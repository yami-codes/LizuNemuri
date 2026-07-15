import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/core/lore/lore_generate_queue_models.dart';
import 'package:lizunemu/utils/logger.dart';
import 'package:lizunemu/utils/platform_capabilities.dart';
import 'package:permission_handler/permission_handler.dart';

class LoreGenerateQueueNotification {
  static const _channelId = 'moe.lizu.nemu.lore_generate';
  static const _channelName = 'Lore generate';
  static const _notificationId = 42018;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> initialize() async {
    if (!PlatformCapabilities.supportsMediaNotification) return;
    try {
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
            description: 'Background work-lore generation progress',
            importance: Importance.low,
          ),
        );
        if (await Permission.notification.isDenied) {
          await Permission.notification.request();
        }
      }
      _ready = true;
    } catch (e) {
      AppLogger.warning('LoreGenerateQueueNotification init failed: $e');
      _ready = false;
    }
  }

  Future<void> update(LoreGenerateQueueSnapshot snapshot) async {
    if (!_ready) return;
    try {
      if (!snapshot.isActive) {
        await clear();
        return;
      }
      final title = Strings.loreQueueNotificationTitle;
      final body = snapshot.currentWorkTitle != null
          ? Strings.loreQueueNotificationBody(
              snapshot.completedJobs,
              snapshot.totalJobs,
              snapshot.currentWorkTitle!,
            )
          : Strings.loreQueueNotificationIdle(
              snapshot.completedJobs,
              snapshot.totalJobs,
            );
      final progress = snapshot.totalJobs > 0
          ? ((snapshot.completedJobs / snapshot.totalJobs) * 100).round()
          : 0;
      await _plugin.show(
        _notificationId,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: 'Background work-lore generation progress',
            importance: Importance.low,
            priority: Priority.low,
            onlyAlertOnce: true,
            showProgress: true,
            maxProgress: 100,
            progress: progress,
            ongoing: true,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      AppLogger.warning('LoreGenerateQueueNotification update failed: $e');
    }
  }

  Future<void> clear() async {
    if (!_ready) return;
    try {
      await _plugin.cancel(_notificationId);
    } catch (_) {}
  }
}
