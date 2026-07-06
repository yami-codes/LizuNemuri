import 'dart:convert';

import 'package:universal_io/io.dart';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:lizunemu/utils/logger.dart';

/// Disk cache for translated metadata (work titles, track names, etc.).
class MetadataTranslationCache {
  static const _subdir = 'translated_metadata';

  Future<Directory> _baseDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$_subdir');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String sourceHash(String text) =>
      md5.convert(utf8.encode(text.trim())).toString();

  Future<File> _cacheFile({
    required String scope,
    required String entityId,
    required String targetLang,
    required String hash,
  }) async {
    final safeScope = scope.replaceAll(RegExp(r'[^\w\-]'), '_');
    final safeEntity = entityId.replaceAll(RegExp(r'[^\w\-]'), '_');
    final dir = await _baseDir();
    final scopeDir = Directory('${dir.path}/$safeScope');
    if (!await scopeDir.exists()) {
      await scopeDir.create(recursive: true);
    }
    return File('${scopeDir.path}/${safeEntity}_${targetLang}_$hash.txt');
  }

  Future<String?> load({
    required String scope,
    required String entityId,
    required String targetLang,
    required String sourceText,
  }) async {
    if (kIsWeb) return null;
    try {
      final hash = sourceHash(sourceText);
      final file = await _cacheFile(
        scope: scope,
        entityId: entityId,
        targetLang: targetLang,
        hash: hash,
      );
      if (!await file.exists()) return null;
      final text = (await file.readAsString()).trim();
      return text.isEmpty ? null : text;
    } catch (e) {
      AppLogger.warning('MetadataTranslationCache load failed: $e');
      return null;
    }
  }

  Future<void> save({
    required String scope,
    required String entityId,
    required String targetLang,
    required String sourceText,
    required String translatedText,
  }) async {
    if (kIsWeb) return;
    try {
      final hash = sourceHash(sourceText);
      final file = await _cacheFile(
        scope: scope,
        entityId: entityId,
        targetLang: targetLang,
        hash: hash,
      );
      await file.writeAsString(translatedText.trim());
    } catch (e) {
      AppLogger.warning('MetadataTranslationCache save failed: $e');
    }
  }
}
