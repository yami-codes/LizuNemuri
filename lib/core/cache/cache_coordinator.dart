import 'package:xuro/core/audio/cache/audio_cache_manager.dart';
import 'package:xuro/core/subtitle/cache/subtitle_cache_manager.dart';
import 'package:xuro/core/image/cache/image_cache_manager.dart';
import 'package:xuro/core/cache/recommendation_cache_manager.dart';
import 'package:xuro/utils/logger.dart';
import 'package:xuro/common/constants/log_strings.dart';

/// 统一缓存协调器
/// 提供单一 API 查询、清理和清除所有应用缓存
class CacheCoordinator {
  static final CacheCoordinator _instance = CacheCoordinator._internal();
  factory CacheCoordinator() => _instance;
  CacheCoordinator._internal();

  /// 获取各缓存类型的大小报告
  Future<CacheSizeReport> getSizeReport() async {
    final results = await Future.wait([
      AudioCacheManager.getCacheSize(),
      SubtitleCacheManager.getSize(),
      ImageCacheManager.getSize(),
    ]);
    return CacheSizeReport(
      audio: results[0],
      subtitle: results[1],
      image: results[2],
    );
  }

  /// 运行所有缓存的过期清理（自动维护用）
  Future<void> cleanAll() async {
    AppLogger.info(LogStrings.logStartUnifiedCacheCleanup964c6);
    await AudioCacheManager.cleanCache();
    // SubtitleCacheManager 和 ImageCacheManager 使用 flutter_cache_manager 内置的过期策略
    _cleanRecommendationExpired();
    AppLogger.info(LogStrings.logUnifiedCacheCleanupDoneea48b);
  }

  /// 清除所有缓存数据（用户主动清理）
  Future<void> clearAll() async {
    AppLogger.info(LogStrings.logClearingAllCache16985);
    await Future.wait([
      AudioCacheManager.clearAllCache(),
      SubtitleCacheManager.clearCache(),
      ImageCacheManager.clearCache(),
    ]);
    RecommendationCacheManager().clear();
    AppLogger.info(LogStrings.logAllCacheCleared0da32);
  }

  void _cleanRecommendationExpired() {
    RecommendationCacheManager().clear();
  }
}

/// 缓存大小报告
class CacheSizeReport {
  final int audio;
  final int subtitle;
  final int image;

  int get total => audio + subtitle + image;

  const CacheSizeReport({
    required this.audio,
    required this.subtitle,
    required this.image,
  });
}
