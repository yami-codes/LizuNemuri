import 'dart:convert';
import 'dart:typed_data';
import 'package:lizunemu/common/constants/log_strings.dart';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:lizunemu/utils/logger.dart';

class SubtitleCacheManager {
  static const String key = 'subtitleCache';
  
  static final CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 365), // Subtitles rarely change; long TTL
      maxNrOfCacheObjects: 1000, // Max cached files
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );

  /// Returns cached subtitle content.
  static Future<String?> getCachedContent(String url) async {
    try {
      final fileInfo = await instance.getFileFromCache(url);
      if (fileInfo != null) {
        // Check if cache entry has expired
        if (fileInfo.validTill.isBefore(DateTime.now())) {
          AppLogger.debug(LogStrings.logSubtitleCacheExpiredUrle7fbb(url));
          await instance.removeFile(url);
          return null;
        }
        AppLogger.debug(LogStrings.logUsingSubtitleCacheUrl3a292(url));
        return await fileInfo.file.readAsString();
      }
      return null;
    } catch (e) {
      AppLogger.error(LogStrings.logReadSubtitleCacheFaileddb134, e);
      return null;
    }
  }

  /// Saves subtitle content to cache.
  static Future<void> cacheContent(String url, String content) async {
    try {
      await instance.putFile(
        url,
        Uint8List.fromList(utf8.encode(content)),
        fileExtension: 'txt',
      );
      AppLogger.debug(LogStrings.logSubtitleCachedUrlec740(url));
    } catch (e) {
      AppLogger.error(LogStrings.logSaveSubtitleCacheFailedf3048, e);
    }
  }

  /// Cleans cache.
  static Future<void> clearCache() async {
    try {
      await instance.emptyCache();
      AppLogger.debug(LogStrings.logSubtitleCacheCleared0d887);
    } catch (e) {
      AppLogger.error(LogStrings.logCleanSubtitleCacheFailed, e);
    }
  }

  /// Returns cache size.
  static Future<int> getSize() async {
    try {
      return instance.store.getCacheSize();
    } catch (e) {
      AppLogger.error(LogStrings.logGetSubtitleCacheSizeFailed622b3, e);
      return 0;
    }
  }
} 