import 'package:lizunemu/data/services/api_service.dart';
import 'package:lizunemu/utils/logger.dart';
import 'package:lizunemu/common/constants/log_strings.dart';

class RecommendationCacheManager {
  // Singleton
  static final RecommendationCacheManager _instance = RecommendationCacheManager._internal();
  factory RecommendationCacheManager() => _instance;
  RecommendationCacheManager._internal();

  // LinkedHashMap preserves access order for eviction
  final _cache = <String, _CacheItem>{};
  
  // Cache configuration
  static const int _maxCacheSize = 1000; // Max cache entries
  static const Duration _cacheDuration = Duration(hours: 24); // Cache TTL

  /// Build cache key.
  String _generateKey(String itemId, int page, int subtitle) {
    return '$itemId-$page-$subtitle';
  }

  /// Get cached data.
  WorksResponse? get(String itemId, int page, int subtitle) {
    final key = _generateKey(itemId, page, subtitle);
    final item = _cache[key];

    if (item == null) {
      return null;
    }

    // Check expiry
    if (item.isExpired) {
      _cache.remove(key);
      AppLogger.debug(LogStrings.logCacheExpiredKey3dbc2(key));
      return null;
    }

    AppLogger.debug(LogStrings.logCacheHitKeyebd0f(key));
    return item.data;
  }

  /// Store cached data.
  void set(String itemId, int page, int subtitle, WorksResponse data) {
    final key = _generateKey(itemId, page, subtitle);
    
    // Evict oldest entry when at capacity
    if (_cache.length >= _maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }

    _cache[key] = _CacheItem(data);
    AppLogger.debug(LogStrings.logCacheAddKey26f96(key));
  }

  /// Clear all cache.
  void clear() {
    _cache.clear();
    AppLogger.debug(LogStrings.logClearAllRecommendationCache6c408);
  }

  /// Remove cache for one work.
  void remove(String itemId) {
    _cache.removeWhere((key, _) => key.startsWith('$itemId-'));
    AppLogger.debug(LogStrings.logRemoveWorkCacheItemid82faf(itemId));
  }
}

/// Cache entry wrapper.
class _CacheItem {
  final WorksResponse data;
  final DateTime timestamp;

  _CacheItem(this.data) : timestamp = DateTime.now();

  bool get isExpired => 
    DateTime.now().difference(timestamp) > RecommendationCacheManager._cacheDuration;
} 