import 'package:flutter/widgets.dart';
import 'package:lizunemu/core/cache/cache_coordinator.dart';
import 'package:lizunemu/utils/logger.dart';
import 'package:lizunemu/common/constants/log_strings.dart';

/// Cache lifecycle manager — listens to app lifecycle for automatic cache maintenance.
class CacheLifecycleManager with WidgetsBindingObserver {
  static final CacheLifecycleManager _instance = CacheLifecycleManager._internal();
  factory CacheLifecycleManager() => _instance;
  CacheLifecycleManager._internal();

  bool _initialized = false;
  bool _isCleanupRunning = false;
  DateTime? _lastCleanup;
  static const _minCleanupInterval = Duration(hours: 6);

  /// Initialize and register as lifecycle observer (idempotent).
  void initialize() {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
    // Defer startup cleanup until after first frame to avoid stat-heavy scan vs first paint.
    WidgetsBinding.instance.addPostFrameCallback((_) => _triggerCleanup());
  }

  /// Unregister observer.
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _triggerCleanup();
    }
  }

  void _triggerCleanup() {
    if (_isCleanupRunning) return;
    if (_lastCleanup != null &&
        DateTime.now().difference(_lastCleanup!) < _minCleanupInterval) {
      return;
    }

    _isCleanupRunning = true;
    CacheCoordinator().cleanAll().then((_) {
      _lastCleanup = DateTime.now();
      AppLogger.debug(LogStrings.logAutoCacheCleanupDone9b23a);
    }).catchError((e) {
      AppLogger.error(LogStrings.logAutoCacheCleanupFailed7cdd2, e);
    }).whenComplete(() {
      _isCleanupRunning = false;
    });
  }
}
