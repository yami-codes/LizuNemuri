import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lizunemu/utils/logger.dart';
import 'package:lizunemu/utils/platform_capabilities.dart';

/// Keeps Android awake for lore / subtitle LLM queues via FGS (API 34+)
/// or a decorative ongoing notification (older Android).
class LlmBackgroundKeeper {
  static const notificationId = 42019;
  static const _channelId = 'moe.lizu.nemu.llm_background';
  static const _channelName = 'LLM background work';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final Set<String> _holders = {};
  bool _ready = false;
  bool _fgsActive = false;
  bool _legacyActive = false;
  bool _preferLegacy = false;

  bool get isActive => _holders.isNotEmpty;

  Future<void> initialize() async {
    if (!PlatformCapabilities.supportsMediaNotification) return;
    try {
      await PlatformCapabilities.ensureAndroidSdkInt();
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings();
      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios),
      );
      if (PlatformCapabilities.isAndroid) {
        final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: 'Keeps lore / subtitle LLM work alive in background',
            importance: Importance.low,
          ),
        );
      }
      _ready = true;
    } catch (e) {
      AppLogger.warning('LlmBackgroundKeeper init failed: $e');
      _ready = false;
    }
  }

  Future<void> acquire(String holder) async {
    _holders.add(holder);
    if (_holders.length == 1) {
      await _start(
        title: 'Working…',
        body: 'LLM queue active',
      );
    }
  }

  Future<void> release(String holder) async {
    _holders.remove(holder);
    if (_holders.isEmpty) {
      await _stop();
    }
  }

  Future<void> update({
    required String title,
    required String body,
    int? progress,
    int maxProgress = 100,
    bool indeterminate = false,
  }) async {
    if (!_ready || _holders.isEmpty) return;
    await _start(
      title: title,
      body: body,
      progress: progress,
      maxProgress: maxProgress,
      indeterminate: indeterminate,
    );
  }

  Future<void> _start({
    required String title,
    required String body,
    int? progress,
    int maxProgress = 100,
    bool indeterminate = false,
  }) async {
    if (!_ready || !PlatformCapabilities.isAndroid) return;
    final details = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Keeps lore / subtitle LLM work alive in background',
      importance: Importance.low,
      priority: Priority.low,
      onlyAlertOnce: true,
      ongoing: true,
      showProgress: true,
      maxProgress: maxProgress,
      progress: progress ?? 0,
      indeterminate: indeterminate || progress == null,
      category: AndroidNotificationCategory.progress,
    );

    final useFgs = PlatformCapabilities.supportsLlmDataSyncForegroundService &&
        !_preferLegacy;

    try {
      if (useFgs) {
        final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.startForegroundService(
          notificationId,
          title,
          body,
          notificationDetails: details,
          foregroundServiceTypes: {
            AndroidServiceForegroundType.foregroundServiceTypeDataSync,
          },
        );
        _fgsActive = true;
        _legacyActive = false;
      } else {
        await _plugin.show(
          notificationId,
          title,
          body,
          NotificationDetails(android: details),
        );
        _legacyActive = true;
        _fgsActive = false;
      }
    } catch (e) {
      AppLogger.warning('LlmBackgroundKeeper start failed: $e');
      if (useFgs) {
        _preferLegacy = true;
        try {
          await _plugin.show(
            notificationId,
            title,
            body,
            NotificationDetails(android: details),
          );
          _legacyActive = true;
          _fgsActive = false;
        } catch (e2) {
          AppLogger.warning('LlmBackgroundKeeper legacy fallback failed: $e2');
        }
      }
    }
  }

  Future<void> _stop() async {
    if (!_ready) return;
    try {
      if (_fgsActive) {
        final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.stopForegroundService();
        _fgsActive = false;
      }
      if (_legacyActive || !_fgsActive) {
        await _plugin.cancel(notificationId);
        _legacyActive = false;
      }
    } catch (e) {
      AppLogger.warning('LlmBackgroundKeeper stop failed: $e');
    }
  }
}
