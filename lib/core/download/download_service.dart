import 'dart:async';
import 'dart:convert';
import 'package:universal_io/io.dart';
import 'package:lizunemu/utils/platform_capabilities.dart';
import 'package:lizunemu/common/constants/log_strings.dart';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:lizunemu/core/download/models/download_entry.dart';
import 'package:lizunemu/core/download/storage/i_download_repository.dart';
import 'package:lizunemu/data/models/files/child.dart';
import 'package:lizunemu/utils/logger.dart';

enum DownloadStatus {
  success,
  alreadyExists,
  cancelled,
  networkError,
  ioError,
}

class DownloadResult {
  final DownloadStatus status;

  /// Local absolute path on success / alreadyExists; otherwise null.
  final String? localPath;

  const DownloadResult(this.status, [this.localPath]);

  bool get isPlayable =>
      status == DownloadStatus.success || status == DownloadStatus.alreadyExists;
}

/// Local media download service.
///
/// - Uses a **standalone `Dio()`** (no `AuthInterceptor`, no node rotation): media
///   `mediaDownloadUrl` is an API-issued presigned absolute URL, unrelated to asmr nodes;
///   same as tokenless `LockCachingAudioSource` (see spike notes).
/// - On Android, files land in the **app-specific external directory** via `getExternalStorageDirectory()`
///   （`/storage/emulated/0/Android/data/<pkg>/files/downloads/<workId>/`）：
///   No storage permission on any Android version; USB/MTP visible; cleared on uninstall.
///   Falls back to internal `getApplicationDocumentsDirectory()` when unavailable. Non-Android
///   always uses internal storage (`getExternalStorageDirectory()` throws on iOS).
/// - Atomic write mirrors `SubtitleImportService`: tmp → (backup existing) → rename → upsert;
///   any failure rolls back; **never destroy a good existing file before the new one is confirmed**.
/// - Capacity LRU mirrors `AudioCacheManager`: undeletable files still count toward capacity.
class DownloadService {
  static const int _maxTotalSize = 4 * 1024 * 1024 * 1024; // 4 GB

  final IDownloadRepository _repository;
  final Dio _dio;

  DownloadService({required IDownloadRepository repository, Dio? dio})
      : _repository = repository,
        _dio = dio ?? Dio();

  /// Windows/MTP reserved device names (breaks external visibility goal).
  static final RegExp _reservedStem = RegExp(
    r'^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])$',
    caseSensitive: false,
  );

  /// Sanitizes filenames while **preserving the API original title** (Unicode JP/CN, etc.):
  /// only true FS-illegal chars (path separators, Windows/FAT reserved names, controls) → `_`;
  /// trim whitespace and **leading/trailing dots** (FAT/Windows eats trailing dots; leading dot = hidden).
  /// Degenerate input falls back to `file`; Windows reserved stems get a `_` prefix. Clamped to
  /// [_maxNameBytes] UTF-8 bytes keeping the extension (FAT/exFAT 255-byte filename limit).
  static String sanitizeFileName(String name) {
    var cleaned = name
        .replaceAll(RegExp(r'[\x00-\x1F/\\:*?"<>|]'), '_')
        .trim()
        .replaceAll(RegExp(r'^[.\s]+'), '')
        .replaceAll(RegExp(r'[.\s]+$'), '');
    if (cleaned.isEmpty || RegExp(r'^[_.\s]*$').hasMatch(cleaned)) {
      return 'file';
    }
    if (_reservedStem.hasMatch(p.basenameWithoutExtension(cleaned))) {
      cleaned = '_$cleaned';
    }
    return _clampNameBytes(cleaned);
  }

  /// FAT/exFAT 255-byte filename limit; headroom for `.dl_tmp`/`.dl_bak` suffixes.
  static const int _maxNameBytes = 180;

  /// Clamps filename to [_maxNameBytes] UTF-8 bytes, preserving extension without splitting
  /// multibyte chars. Abnormally long "extensions" are treated as part of the stem.
  static String _clampNameBytes(String name) {
    if (utf8.encode(name).length <= _maxNameBytes) return name;
    var ext = p.extension(name);
    if (utf8.encode(ext).length > _maxNameBytes - 8) ext = '';
    final base = name.substring(0, name.length - ext.length);
    final budget = _maxNameBytes - utf8.encode(ext).length;
    final buf = StringBuffer();
    var used = 0;
    for (final ch in base.runes) {
      final chBytes = utf8.encode(String.fromCharCode(ch)).length;
      if (used + chBytes > budget) break;
      buf.writeCharCode(ch);
      used += chBytes;
    }
    final clampedBase = buf.toString().trim();
    return clampedBase.isEmpty ? 'file$ext' : '$clampedBase$ext';
  }

  /// Stable identity key for DB dedup/query/delete and **on-disk subdir** — not the display name.
  ///
  /// Distinct titles/paths must be distinct downloads. On-disk names use API titles ([diskFileName]);
  /// `<fileKey>/` subdirs isolate same-name collisions. Identity: `hash` > `mediaDownloadUrl` > `title`, md5.
  static String fileKey(Child file) {
    final idSource = (file.hash != null && file.hash!.isNotEmpty)
        ? file.hash!
        : (file.mediaDownloadUrl ?? file.title ?? 'file');
    return md5.convert(utf8.encode(idSource)).toString();
  }

  /// On-disk name = **API original title** (FS-sanitized, human-readable). Uniqueness via `<fileKey>/` subdir.
  static String diskFileName(Child file) {
    return sanitizeFileName(file.title ?? '');
  }

  /// Download root: Android prefers external app dir; fallback internal; non-Android internal only.
  Future<Directory> _baseDir() async {
    if (PlatformCapabilities.isAndroid) {
      try {
        final ext = await getExternalStorageDirectory();
        if (ext != null) return ext;
      } catch (e) {
        AppLogger.warning(LogStrings.logExternalStorageUnavailableFae9daa(e));
      }
    }
    return getApplicationDocumentsDirectory();
  }

  Future<Directory> _workDir(String workId) async {
    final base = await _baseDir();
    final dir = Directory(p.join(base.path, 'downloads', workId));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Path = `<root>/downloads/<workId>/<fileKey>/<original title>`. Each file gets its own `<fileKey>/`
  /// subdir so same-name files in different folders never collide. tmp/bak/dest share the subdir for atomic rename.
  Future<String> _destPath(String workId, Child file) async {
    final dir = await _workDir(workId);
    final sub = Directory(p.join(dir.path, fileKey(file)));
    if (!await sub.exists()) await sub.create(recursive: true);
    return p.join(sub.path, diskFileName(file));
  }

  /// Best-effort prune empty `<fileKey>/` dirs after file delete; failure is harmless.
  Future<void> _pruneEmptyDir(String filePath) async {
    try {
      final parent = Directory(p.dirname(filePath));
      if (await parent.exists() && await parent.list().isEmpty) {
        await parent.delete();
      }
    } catch (_) {}
  }

  /// Completed download with file on disk (lookup by stable [key]); stale DB rows without files are removed.
  Future<DownloadEntry?> findCompleted(String workId, String key) async {
    final entry = await _repository.find(workId, key);
    if (entry == null) return null;
    if (await File(entry.filePath).exists()) return entry;
    AppLogger.warning(LogStrings.logStaleDownloadRowCleanedEntry5340a(entry.filePath));
    try {
      await _repository.remove(workId, key);
    } catch (e) {
      AppLogger.error(LogStrings.logCleanStaleDownloadRowsFailede1ed8, e);
    }
    return null;
  }

  /// Returns local path if fully downloaded (for offline local-source playback).
  ///
  /// Primary lookup by [fileKey]; falls back to [Child.title] vs [DownloadEntry.fileName] when hash is unavailable.
  Future<String?> localPathIfDownloaded(String workId, Child file) async {
    if (file.title == null) return null;
    final entry = await findCompleted(workId, fileKey(file));
    if (entry != null) return entry.filePath;

    final entries = await _repository.listByWork(workId);
    for (final e in entries) {
      if (e.fileName == file.title && await File(e.filePath).exists()) {
        return e.filePath;
      }
    }
    return null;
  }

  /// Downloads one file (audio/video/subtitle) to the local download dir. Idempotent if already complete.
  Future<DownloadResult> download({
    required String workId,
    required Child file,
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final url = file.mediaDownloadUrl;
    final fileName = file.title;
    if (url == null || url.isEmpty || fileName == null || fileName.isEmpty) {
      AppLogger.warning(LogStrings.logDownloadMissingUrlOrFilename1e7e8(fileName));
      return const DownloadResult(DownloadStatus.ioError);
    }

    final key = fileKey(file);

    // Pre-flight IO/DB (dedup, paths, tmp/bak) inside the same try: DB open/migration,
    // path_provider/dir create, File.exists permission errors → ioError + cleanup, never uncaught.
    String? destPath;
    File? tmpFile;
    File? bakFile;
    var backedUp = false;

    try {
      // Dedup: reuse completed download (early return, not catch).
      final existing = await findCompleted(workId, key);
      if (existing != null) {
        return DownloadResult(DownloadStatus.alreadyExists, existing.filePath);
      }

      destPath = await _destPath(workId, file);
      final tmpPath = '$destPath.dl_tmp';
      final bakPath = '$destPath.dl_bak';
      tmpFile = File(tmpPath);
      bakFile = File(bakPath);

      // 1. Download to temp — failures must not touch existing files.
      await _dio.download(
        url,
        tmpPath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (onProgress != null && total > 0) {
            onProgress(received / total);
          }
        },
      );

      // 2. Move existing dest to backup for rollback.
      if (await File(destPath).exists()) {
        await File(destPath).rename(bakPath);
        backedUp = true;
      }

      // 3. Same-volume rename is atomic.
      await tmpFile.rename(destPath);

      // 4. Persist DB row (file is in place).
      final size = await File(destPath).length();
      await _repository.upsert(DownloadEntry(
        workId: workId,
        fileKey: key,
        fileName: fileName,
        filePath: destPath,
        mediaType: (file.type ?? '').toLowerCase(),
        sourceUrl: url,
        size: size,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ));

      // 5. Success — delete backup of replaced file.
      if (backedUp) {
        try {
          if (await bakFile.exists()) await bakFile.delete();
        } catch (_) {}
      }

      // 6. Capacity enforcement (failure does not affect this download). Exclude just-finished file.
      unawaited(enforceCapacity(
        exceptWorkId: workId,
        exceptFileKey: key,
      ));

      AppLogger.debug(LogStrings.logDownloadCompleteWorkidFilena3d481(workId, fileName, destPath));
      return DownloadResult(DownloadStatus.success, destPath);
    } catch (e) {
      // Cleanup tmp and restore backup; never destroy existing data. Null-guard tmp/bak/destPath on pre-flight failure.
      final tf = tmpFile;
      final bf = bakFile;
      final dp = destPath;
      try {
        if (tf != null && await tf.exists()) await tf.delete();
      } catch (_) {}
      if (backedUp && bf != null && dp != null) {
        try {
          await bf.rename(dp);
        } catch (_) {}
      }
      if (e is DioException && CancelToken.isCancel(e)) {
        AppLogger.debug(LogStrings.logDownloadCancelledWorkidFilene08ac(workId, fileName));
        return const DownloadResult(DownloadStatus.cancelled);
      }
      if (e is DioException) {
        AppLogger.error(LogStrings.logDownloadNetworkErrorWorkidFi3d322(workId, fileName), e);
        return const DownloadResult(DownloadStatus.networkError);
      }
      AppLogger.error(LogStrings.logDownloadFailedWorkidFilename338fd(workId, fileName), e);
      return const DownloadResult(DownloadStatus.ioError);
    }
  }

  Future<void> removeDownload(String workId, Child file) async {
    final key = fileKey(file);
    String? path;
    try {
      path = (await _repository.find(workId, key))?.filePath;
    } catch (e) {
      AppLogger.error(LogStrings.logQueryDownloadToRemoveFailedb00ee, e);
    }
    // Remove DB row first (stale row makes app think file is downloaded); file delete is best-effort.
    var dbRemoved = false;
    try {
      await _repository.remove(workId, key);
      dbRemoved = true;
    } catch (e) {
      AppLogger.error(LogStrings.logRemoveDownloadDbRowFailedKee7b72d, e);
    }
    if (dbRemoved && path != null) {
      try {
        final f = File(path);
        if (await f.exists()) await f.delete();
        await _pruneEmptyDir(path);
      } catch (e) {
        AppLogger.warning(LogStrings.logRemoveDownloadFileFailedDbRo1c106(e));
      }
    }
  }

  /// True LRU: when over capacity, delete oldest (file + DB row) until within limit.
  /// Undeletable files still on disk must keep counting and retain valid DB rows.
  Future<void> enforceCapacity({
    String? exceptWorkId,
    String? exceptFileKey,
  }) async {
    try {
      final entries = await _repository.listAllOldestFirst();
      var total = 0;
      final live = <DownloadEntry>[];
      for (final e in entries) {
        try {
          final f = File(e.filePath);
          if (await f.exists()) {
            total += (await f.stat()).size;
            live.add(e);
          } else {
            // File gone: remove stale row, do not count.
            await _repository.remove(e.workId, e.fileKey);
          }
        } catch (_) {
          // stat failed but row may still point at an in-use file: count DB size conservatively.
          total += e.size;
          live.add(e);
        }
      }
      for (final e in live) {
        if (total <= _maxTotalSize) break;
        // Skip the file just finished — do not evict what the user just got.
        if (e.workId == exceptWorkId && e.fileKey == exceptFileKey) continue;
        try {
          final f = File(e.filePath);
          int sz;
          try {
            sz = await f.exists() ? (await f.stat()).size : e.size;
          } catch (_) {
            sz = e.size;
          }
          await f.delete();
          await _repository.remove(e.workId, e.fileKey);
          await _pruneEmptyDir(e.filePath);
          total -= sz;
        } catch (_) {
          // In use: keep file and DB row, still count toward capacity, skip.
        }
      }
    } catch (e) {
      AppLogger.error(LogStrings.logDownloadCapacityReclaimFaile4d679, e);
    }
  }
}
