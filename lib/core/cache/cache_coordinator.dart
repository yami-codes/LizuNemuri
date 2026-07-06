import 'package:lizunemu/core/audio/cache/audio_cache_manager.dart';
import 'package:lizunemu/core/subtitle/cache/subtitle_cache_manager.dart';
import 'package:lizunemu/core/image/cache/image_cache_manager.dart';
import 'package:lizunemu/core/cache/recommendation_cache_manager.dart';
import 'package:lizunemu/utils/logger.dart';
import 'package:lizunemu/common/constants/log_strings.dart';

/// Unified cache coordinator — single API to query, clean, and clear all app caches.
class CacheCoordinator {
  static final CacheCoordinator _instance = CacheCoordinator._internal();
  factory CacheCoordinator() => _instance;
  CacheCoordinator._internal();

  /// Size report per cache type.
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

  /// Run expiry cleanup on all caches (automatic maintenance).
  Future<void> cleanAll() async {
    AppLogger.info(LogStrings.logStartUnifiedCacheCleanup964c6);
    await AudioCacheManager.cleanCache();
    // SubtitleCacheManager and ImageCacheManager use built-in flutter_cache_manager expiry
    _cleanRecommendationExpired();
    AppLogger.info(LogStrings.logUnifiedCacheCleanupDoneea48b);
  }

  /// Clear all cache data (user-initiated).
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

/// Cache size report.
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
