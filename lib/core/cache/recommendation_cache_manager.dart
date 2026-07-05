import 'dart:collection';
import 'package:xuro/data/services/api_service.dart';
import 'package:xuro/utils/logger.dart';
import 'package:xuro/common/constants/log_strings.dart';

class RecommendationCacheManager {
  // 单例模式
  static final RecommendationCacheManager _instance = RecommendationCacheManager._internal();
  factory RecommendationCacheManager() => _instance;
  RecommendationCacheManager._internal();

  // 使用 LinkedHashMap 便于按访问顺序管理缓存
  final _cache = <String, _CacheItem>{};
  
  // 缓存配置
  static const int _maxCacheSize = 1000; // 最大缓存条目数
  static const Duration _cacheDuration = Duration(hours: 24); // 缓存有效期

  /// 生成缓存键
  String _generateKey(String itemId, int page, int subtitle) {
    return '$itemId-$page-$subtitle';
  }

  /// 获取缓存数据
  WorksResponse? get(String itemId, int page, int subtitle) {
    final key = _generateKey(itemId, page, subtitle);
    final item = _cache[key];

    if (item == null) {
      return null;
    }

    // 检查是否过期
    if (item.isExpired) {
      _cache.remove(key);
      AppLogger.debug(LogStrings.logCacheExpiredKey3dbc2(key));
      return null;
    }

    AppLogger.debug(LogStrings.logCacheHitKeyebd0f(key));
    return item.data;
  }

  /// 存储缓存数据
  void set(String itemId, int page, int subtitle, WorksResponse data) {
    final key = _generateKey(itemId, page, subtitle);
    
    // 检查缓存大小,如果达到上限则移除最早的条目
    if (_cache.length >= _maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }

    _cache[key] = _CacheItem(data);
    AppLogger.debug(LogStrings.logCacheAddKey26f96(key));
  }

  /// 清除所有缓存
  void clear() {
    _cache.clear();
    AppLogger.debug(LogStrings.logClearAllRecommendationCache6c408);
  }

  /// 移除指定作品的缓存
  void remove(String itemId) {
    _cache.removeWhere((key, _) => key.startsWith('$itemId-'));
    AppLogger.debug(LogStrings.logRemoveWorkCacheItemid82faf(itemId));
  }
}

/// 缓存条目包装类
class _CacheItem {
  final WorksResponse data;
  final DateTime timestamp;

  _CacheItem(this.data) : timestamp = DateTime.now();

  bool get isExpired => 
    DateTime.now().difference(timestamp) > RecommendationCacheManager._cacheDuration;
} 