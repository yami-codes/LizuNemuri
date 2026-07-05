import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:lizunemu/core/audio/models/subtitle.dart';
import 'package:lizunemu/utils/logger.dart';

/// Disk cache for translated subtitle lines keyed by work/file/lang/source hash.
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

  String sourceHash(SubtitleList list) {
    final payload = list.subtitles.map((s) => s.text).join('\n');
    return md5.convert(utf8.encode(payload)).toString();
  }

  Future<File> _cacheFile({
    required String workId,
    required String fileName,
    required String targetLang,
    required String hash,
  }) async {
    final safeWork = workId.replaceAll(RegExp(r'[^\w\-]'), '_');
    final safeFile = fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
    final dir = await _baseDir();
    final workDir = Directory('${dir.path}/$safeWork');
    if (!await workDir.exists()) {
      await workDir.create(recursive: true);
    }
    return File('${workDir.path}/${safeFile}_${targetLang}_$hash.json');
  }

  /// Whether a complete cached translation exists for this track + language.
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

  /// Count cached translation files under one work directory.
  Future<int> countForWork(String workId) async {
    try {
      final safeWork = workId.replaceAll(RegExp(r'[^\w\-]'), '_');
      final dir = await _baseDir();
      final workDir = Directory('${dir.path}/$safeWork');
      if (!await workDir.exists()) return 0;
      var count = 0;
      await for (final entity in workDir.list()) {
        if (entity is File && entity.path.endsWith('.json')) count++;
      }
      return count;
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
      final file = await _cacheFile(
        workId: workId,
        fileName: fileName,
        targetLang: targetLang,
        hash: hash,
      );
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
      final file = await _cacheFile(
        workId: workId,
        fileName: fileName,
        targetLang: targetLang,
        hash: hash,
      );
      final jsonMap = lines.map((k, v) => MapEntry(k.toString(), v));
      await file.writeAsString(jsonEncode(jsonMap));
    } catch (e) {
      AppLogger.warning('SubtitleTranslationCache save failed: $e');
    }
  }
}
