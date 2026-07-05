import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:lizunemu/utils/logger.dart';
import 'package:lizunemu/common/constants/log_strings.dart';

/// 图片缓存管理器
/// 统一管理应用内所有图片的缓存策略
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

  /// 获取缓存大小
  static Future<int> getSize() async {
    try {
      return instance.store.getCacheSize();
    } catch (e) {
      AppLogger.error(LogStrings.logGetImageCacheSizeFailed8c2b8, e);
      return 0;
    }
  }

  /// 清理图片缓存
  static Future<void> clearCache() async {
    try {
      await instance.emptyCache();
      AppLogger.debug(LogStrings.logImageCacheCleared7784c);
    } catch (e) {
      AppLogger.error(LogStrings.logCleanImageCacheFailed, e);
    }
  }
}
