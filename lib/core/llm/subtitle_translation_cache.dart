import 'dart:convert';
import 'package:universal_io/io.dart';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:lizunemu/core/audio/models/subtitle.dart';
import 'package:lizunemu/utils/logger.dart';

/// Disk cache for translated subtitle lines.
///
/// **Primary key** is `(workId, targetLang, contentHash)` — audio title is
/// optional legacy hint only. Remaster twins that share subtitle text share
/// one cache file.
class SubtitleTranslationCache {
  static const _subdir = 'translated_subtitles';

  Future<Directory> _baseDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$_subdir');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Directory> _workDir(String workId) async {
    final safeWork = workId.replaceAll(RegExp(r'[^\w\-]'), '_');
    final dir = await _baseDir();
    final workDir = Directory('${dir.path}/$safeWork');
    if (!await workDir.exists()) {
      await workDir.create(recursive: true);
    }
    return workDir;
  }

  String sourceHash(SubtitleList list) {
    final payload = list.subtitles.map((s) => s.text).join('\n');
    return md5.convert(utf8.encode(payload)).toString();
  }

  /// Hash-primary path: `{hash}_{targetLang}.json`
  Future<File> _primaryFile({
    required String workId,
    required String targetLang,
    required String hash,
  }) async {
    final workDir = await _workDir(workId);
    final safeLang = targetLang.replaceAll(RegExp(r'[^\w\-]'), '_');
    return File('${workDir.path}/${hash}_$safeLang.json');
  }

  /// Legacy path: `{audioTitle}_{targetLang}_{hash}.json`
  Future<File> _legacyFile({
    required String workId,
    required String fileName,
    required String targetLang,
    required String hash,
  }) async {
    final workDir = await _workDir(workId);
    final safeFile = fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
    final safeLang = targetLang.replaceAll(RegExp(r'[^\w\-]'), '_');
    return File('${workDir.path}/${safeFile}_${safeLang}_$hash.json');
  }

  Future<bool> exists({
    required String workId,
    required String fileName,
    required String targetLang,
    required String hash,
    required int lineCount,
  }) async {
    final cached = await load(
      workId: workId,
      fileName: fileName,
      targetLang: targetLang,
      hash: hash,
    );
    return cached != null && cached.length == lineCount;
  }

  /// Unique complete-ish translation scripts for a work (by hash+lang).
  Future<int> countForWork(String workId) async {
    try {
      final workDir = await _workDir(workId);
      if (!await workDir.exists()) return 0;
      final seen = <String>{};
      await for (final entity in workDir.list()) {
        if (entity is! File || !entity.path.endsWith('.json')) continue;
        final name = entity.uri.pathSegments.last;
        // Primary: hash_lang.json ; legacy: title_lang_hash.json
        final primary = RegExp(r'^([a-f0-9]{32})_([^.]+)\.json$',
            caseSensitive: false);
        final m = primary.firstMatch(name);
        if (m != null) {
          seen.add('${m.group(1)}|${m.group(2)}');
          continue;
        }
        final legacy = RegExp(
          r'_([^.]+)_([a-f0-9]{32})\.json$',
          caseSensitive: false,
        );
        final lm = legacy.firstMatch(name);
        if (lm != null) {
          seen.add('${lm.group(2)}|${lm.group(1)}');
        } else {
          seen.add(name);
        }
      }
      return seen.length;
    } catch (e) {
      AppLogger.warning('SubtitleTranslationCache countForWork failed: $e');
      return 0;
    }
  }

  Future<Map<int, String>?> load({
    required String workId,
    required String fileName,
    required String targetLang,
    required String hash,
  }) async {
    try {
      final primary = await _primaryFile(
        workId: workId,
        targetLang: targetLang,
        hash: hash,
      );
      final fromPrimary = await _readLines(primary);
      if (fromPrimary != null) return fromPrimary;

      // Legacy remaster title path → promote into primary on hit.
      final legacy = await _legacyFile(
        workId: workId,
        fileName: fileName,
        targetLang: targetLang,
        hash: hash,
      );
      final fromLegacy = await _readLines(legacy);
      if (fromLegacy != null) {
        await _writeLines(primary, fromLegacy);
        return fromLegacy;
      }

      // Any other legacy file ending in _{lang}_{hash}.json for this work.
      final workDir = await _workDir(workId);
      final safeLang = targetLang.replaceAll(RegExp(r'[^\w\-]'), '_');
      final suffix = '_${safeLang}_$hash.json';
      await for (final entity in workDir.list()) {
        if (entity is! File) continue;
        if (!entity.path.endsWith(suffix)) continue;
        final lines = await _readLines(entity);
        if (lines != null) {
          await _writeLines(primary, lines);
          return lines;
        }
      }
      return null;
    } catch (e) {
      AppLogger.warning('SubtitleTranslationCache load failed: $e');
      return null;
    }
  }

  Future<void> save({
    required String workId,
    required String fileName,
    required String targetLang,
    required String hash,
    required Map<int, String> lines,
  }) async {
    try {
      final primary = await _primaryFile(
        workId: workId,
        targetLang: targetLang,
        hash: hash,
      );
      await _writeLines(primary, lines);
    } catch (e) {
      AppLogger.warning('SubtitleTranslationCache save failed: $e');
    }
  }

  Future<Map<int, String>?> _readLines(File file) async {
    if (!await file.exists()) return null;
    final map = jsonDecode(await file.readAsString());
    if (map is! Map) return null;
    final out = <int, String>{};
    map.forEach((key, value) {
      final index = int.tryParse(key.toString());
      if (index != null && value is String) {
        out[index] = value;
      }
    });
    return out.isEmpty ? null : out;
  }

  Future<void> _writeLines(File file, Map<int, String> lines) async {
    final jsonMap = lines.map((k, v) => MapEntry(k.toString(), v));
    await file.writeAsString(jsonEncode(jsonMap));
  }
}
