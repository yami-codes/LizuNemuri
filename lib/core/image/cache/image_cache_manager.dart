import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:lizunemu/utils/logger.dart';
import 'package:lizunemu/common/constants/log_strings.dart';

/// Image cache manager — unified image caching policy.
class ImageCacheManager {
  static const String key = 'imageCache';

  static final CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 500,
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );

  /// Returns cache size.
  static Future<int> getSize() async {
    try {
      return instance.store.getCacheSize();
    } catch (e) {
      AppLogger.error(LogStrings.logGetImageCacheSizeFailed8c2b8, e);
      return 0;
    }
  }

  /// Clears image cache.
  static Future<void> clearCache() async {
    try {
      await instance.emptyCache();
      AppLogger.debug(LogStrings.logImageCacheCleared7784c);
    } catch (e) {
      AppLogger.error(LogStrings.logCleanImageCacheFailed, e);
    }
  }
}
