import 'package:universal_io/io.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:just_audio/just_audio.dart';
import 'package:lizunemu/utils/logger.dart';
import 'package:lizunemu/common/constants/log_strings.dart';
import 'package:lizunemu/core/media/work_media_utils.dart';
import 'package:lizunemu/utils/platform_capabilities.dart';

/// Audio cache manager.
/// Manages audio file caching and hides the concrete cache implementation from callers.
class AudioCacheManager {
  static const int _maxCacheSize = 1024 * 1024 * 1024; // Total cache limit: 1024 MB
  static const Duration _cacheExpiration = Duration(days: 30);

  /// Desktop backends stream presigned URLs directly; mobile uses lock-cache.
  @visibleForTesting
  static bool shouldUseDirectStreaming({required bool isDesktop}) => isDesktop;

  /// Creates an audio source.
  /// Handles caching internally and returns only an [AudioSource] to callers.
  ///
  /// Desktop backends (`just_audio_windows`, Linux media_kit) handle
  /// [LockCachingAudioSource] byte-stream proxies poorly — use direct progressive
  /// URL streaming there. Mobile keeps lock-caching for LRU disk cache.
  static Future<AudioSource> createAudioSource(String url, {String? hash}) async {
    if (shouldUseDirectStreaming(isDesktop: PlatformCapabilities.isDesktop)) {
      AppLogger.debug(LogStrings.logCreateaudioUrlUrlCachefil14d8a(url, 'desktop-progressive'));
      return ProgressiveAudioSource(
        Uri.parse(url),
        headers: WorkMediaUtils.mediaFetchHeaders,
      );
    }

    try {
      final cacheFile = await _getCacheFile(url, hash: hash);
      final fileName = _generateFileName(url, hash: hash);
      AppLogger.debug(LogStrings.logCreateaudioUrlUrlCachefil14d8a(url, fileName));
      
      // Check whether the cache file exists and is still valid.
      final isValid = await _isCacheValid(cacheFile, fileName);
      
      if (isValid) {
        AppLogger.debug(LogStrings.logFilenameUsingCachefile42421(fileName));
        return _createCachingSource(url, cacheFile);
      }

      AppLogger.debug(LogStrings.logFilenameCreateCache8c40f(fileName));
      return _createCachingSource(url, cacheFile);
      
    } catch (e, stackTrace) {
      AppLogger.warning(LogStrings.logCacheAudioSourceFailedStreama308a(url));
      AppLogger.error(LogStrings.logCacheSourceCreationError7469b, e, stackTrace);
      return ProgressiveAudioSource(
        Uri.parse(url),
        headers: WorkMediaUtils.mediaFetchHeaders,
      );
    }
  }

  /// Cleans expired and over-capacity cache entries (true LRU: delete oldest until total size <= limit).
  static Future<void> cleanCache() async {
    try {
      final cacheDir = await _getCacheDir();
      final entities = await cacheDir.list().toList();

      // Collect (file, stat) asynchronously in one pass; avoid synchronous statSync
      // inside a sort comparator, which would cause O(N log N) blocking FS calls on the main isolate.
      final entries = <({File file, FileStat stat})>[];
      for (final e in entities) {
        if (e is! File) continue;
        try {
          entries.add((file: e, stat: await e.stat()));
        } catch (_) {
          // File may be in use or already deleted; skip.
        }
      }

      final now = DateTime.now();

      // 1) Delete expired files first; survivors go into the live set.
      final live = <({File file, FileStat stat})>[];
      for (final entry in entries) {
        if (now.difference(entry.stat.modified) > _cacheExpiration) {
          try {
            await entry.file.delete();
          } catch (_) {
            // Delete failed while file is in use: it still occupies disk and must count
            // toward capacity. With the oldest modified time, it lands at the front of live
            // and gets retried first during LRU eviction. Do not drop it, or capacity
            // accounting shrinks while actual usage can far exceed the limit.
            live.add(entry);
          }
        } else {
          live.add(entry);
        }
      }

      // 2) True LRU: sort by modified ascending (oldest first), delete from oldest,
      //    decrementing totalSize after each delete until total size is within the limit.
      live.sort((a, b) => a.stat.modified.compareTo(b.stat.modified));
      var totalSize = live.fold<int>(0, (sum, e) => sum + e.stat.size);
      for (final entry in live) {
        if (totalSize <= _maxCacheSize) break;
        try {
          await entry.file.delete();
          totalSize -= entry.stat.size;
        } catch (_) {
          // In use; skip and try the next older file.
        }
      }
    } catch (e) {
      AppLogger.error(LogStrings.logCleanCacheFailed, e);
    }
  }

  /// Clears all audio cache (invoked on user-initiated cleanup).
  /// Throws if any file cannot be deleted.
  static Future<void> clearAllCache() async {
    final cacheDir = await _getCacheDir();
    final entities = await cacheDir.list().toList();

    var deleted = 0;
    var failed = 0;

    for (var entity in entities) {
      try {
        if (entity is File) {
          await entity.delete();
          deleted++;
        } else if (entity is Directory) {
          await entity.delete(recursive: true);
          deleted++;
        }
      } catch (e) {
        failed++;
        AppLogger.warning(LogStrings.logCannotDeleteCacheFileEntityP1dc66(entity.path));
      }
    }

    if (failed == 0) {
      AppLogger.debug(LogStrings.logAudioCacheClearedDeletedDele52cd6(deleted));
    } else {
      AppLogger.warning(LogStrings.logAudioCachePartialCleanOkDeleec69e(deleted, failed));
      throw Exception(LogStrings.logPartialCacheDeleteFailed(failed.toString()));
    }
  }

  /// Returns total cache size in bytes.
  static Future<int> getCacheSize() async {
    try {
      final cacheDir = await _getCacheDir();
      final files = await cacheDir.list().toList();
      
      var totalSize = 0;
      for (var file in files) {
        if (file is File) {
          totalSize += (await file.stat()).size;
        }
      }
      return totalSize;
    } catch (e) {
      AppLogger.error(LogStrings.logGetCacheSizeFailedf83a7, e);
      return 0;
    }
  }

  // Private helpers

  /// Creates a caching audio source backed by [cacheFile].
  static AudioSource _createCachingSource(String url, File cacheFile) {
    return LockCachingAudioSource(
      Uri.parse(url),
      cacheFile: cacheFile,
      headers: WorkMediaUtils.mediaFetchHeaders,
    );
  }

  /// Checks whether [cacheFile] is a valid cache entry.
  static Future<bool> _isCacheValid(File cacheFile, String fileName) async {
    final exists = await cacheFile.exists();
    if (!exists) {
      AppLogger.debug(LogStrings.logFilenameCachevalidateFile4be6a(fileName));
      return false;
    }

    try {
      final stat = await cacheFile.stat();
      final size = stat.size;
      final age = DateTime.now().difference(stat.modified);
      
      AppLogger.debug(LogStrings.logFilenameCachevalidateSizef7217(size, fileName, age));
      
      // Per-file size check removed; only expiration is enforced.
      if (age > _cacheExpiration) {
        AppLogger.debug(LogStrings.logFilenameCacheinvalidFileexpif9f0f(fileName, age, _cacheExpiration));
        await cacheFile.delete();
        return false;
      }

      AppLogger.debug(LogStrings.logFilenameCachevalidateValid6ddeb(fileName));
      return true;
    } catch (e) {
      AppLogger.error(LogStrings.logFilenameCheckcachevalidFaile1bb88(fileName), e);
      return false;
    }
  }

  /// Resolves the on-disk cache file for [url].
  static Future<File> _getCacheFile(String url, {String? hash}) async {
    final cacheDir = await _getCacheDir();
    final fileName = _generateFileName(url, hash: hash);
    return File('${cacheDir.path}/$fileName');
  }

  /// Generates a stable cache file name from [url] and optional [hash].
  static String _generateFileName(String url, {String? hash}) {
    if (hash != null && hash.isNotEmpty) {
      // Sanitize hash to ensure filesystem safety
      return hash.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    }
    final bytes = utf8.encode(url);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  /// Returns the audio cache directory, creating it if needed.
  static Future<Directory> _getCacheDir() async {
    final appDir = await getApplicationSupportDirectory();
    final audioCacheDir = Directory('${appDir.path}/audio_cache');
    if (!await audioCacheDir.exists()) {
      await audioCacheDir.create(recursive: true);
    }
    return audioCacheDir;
  }

  /// One-time cleanup of legacy temp cache directory
  static Future<void> cleanLegacyCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final legacyDir = Directory('${tempDir.path}/audio_cache');
      if (await legacyDir.exists()) {
        await legacyDir.delete(recursive: true);
        AppLogger.info(LogStrings.logLegacyTempCacheCleaneddcfa8);
      }
    } catch (e) {
      AppLogger.warning(LogStrings.logLegacyCacheCleanupFailedE792c9(e));
    }
  }
}
