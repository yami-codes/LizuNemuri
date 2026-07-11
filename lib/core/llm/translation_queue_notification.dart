import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/core/llm/translation_queue_models.dart';
import 'package:lizunemu/utils/logger.dart';
import 'package:lizunemu/utils/platform_capabilities.dart';
import 'package:permission_handler/permission_handler.dart';

/// Best-effort system notification updates for the translation queue.
///
/// Mobile only — desktop relies on the in-app mini indicator.
class TranslationQueueNotification {
  static const _channelId = 'moe.lizu.nemu.translation_queue';
  static const _channelName = 'Translation queue';
  static const _notificationId = 42017;

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
            description: 'Background subtitle translation progress',
            importance: Importance.low,
          ),
        );
        if (await Permission.notification.isDenied) {
          await Permission.notification.request();
        }
      }
      _ready = true;
    } catch (e) {
      AppLogger.warning('TranslationQueueNotification init failed: $e');
      _ready = false;
    }
  }

  Future<void> update(TranslationQueueSnapshot snapshot) async {
    if (!_ready) return;
    try {
      if (!snapshot.isActive) {
        await clear();
        return;
      }
      final title = Strings.translationQueueNotificationTitle;
      final body = snapshot.currentTrackName != null
          ? Strings.translationQueueNotificationBody(
              snapshot.completedTracks,
              snapshot.totalTracks,
              snapshot.currentTrackName!,
            )
          : Strings.translationQueueNotificationIdle(
              snapshot.completedTracks,
              snapshot.totalTracks,
            );
      final progress = snapshot.totalTracks > 0
          ? ((snapshot.completedTracks / snapshot.totalTracks) * 100).round()
          : 0;
      await _plugin.show(
        _notificationId,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: 'Background subtitle translation progress',
            importance: Importance.low,
            priority: Priority.low,
            onlyAlertOnce: true,
            showProgress: true,
            maxProgress: 100,
            progress: progress,
            ongoing: true,
            category: AndroidNotificationCategory.progress,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: false,
            presentBadge: true,
            presentSound: false,
          ),
        ),
      );
    } catch (e) {
      AppLogger.warning('TranslationQueueNotification update failed: $e');
    }
  }

  Future<void> clear() async {
    if (!_ready) return;
    try {
      await _plugin.cancel(_notificationId);
    } catch (e) {
      AppLogger.warning('TranslationQueueNotification clear failed: $e');
    }
  }
}
