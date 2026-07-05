import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:xuro/utils/logger.dart';

/// Disk cache for LLM-translated work titles.
class WorkTitleTranslationCache {
  static const _subdir = 'translated_titles';

  Future<Directory> _baseDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$_subdir');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String sourceHash(String title) =>
      md5.convert(utf8.encode(title.trim())).toString();

  Future<File> _cacheFile({
    required String workId,
    required String targetLang,
    required String hash,
  }) async {
    final safeWork = workId.replaceAll(RegExp(r'[^\w\-]'), '_');
    final dir = await _baseDir();
    final workDir = Directory('${dir.path}/$safeWork');
    if (!await workDir.exists()) {
      await workDir.create(recursive: true);
    }
    return File('${workDir.path}/${targetLang}_$hash.txt');
  }

  Future<String?> load({
    required String workId,
    required String targetLang,
    required String sourceTitle,
  }) async {
    if (kIsWeb) return null;
    try {
      final hash = sourceHash(sourceTitle);
      final file = await _cacheFile(
        workId: workId,
        targetLang: targetLang,
        hash: hash,
      );
      if (!await file.exists()) return null;
      final text = (await file.readAsString()).trim();
      return text.isEmpty ? null : text;
    } catch (e) {
      AppLogger.warning('WorkTitleTranslationCache load failed: $e');
      return null;
    }
  }

  Future<void> save({
    required String workId,
    required String targetLang,
    required String sourceTitle,
    required String translatedTitle,
  }) async {
    if (kIsWeb) return;
    try {
      final hash = sourceHash(sourceTitle);
      final file = await _cacheFile(
        workId: workId,
        targetLang: targetLang,
        hash: hash,
      );
      await file.writeAsString(translatedTitle.trim());
    } catch (e) {
      AppLogger.warning('WorkTitleTranslationCache save failed: $e');
    }
  }
}
