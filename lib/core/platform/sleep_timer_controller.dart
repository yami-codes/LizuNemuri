import 'dart:async';
import 'package:lizunemu/common/constants/log_strings.dart';

import 'package:flutter/foundation.dart';

import 'package:lizunemu/core/audio/i_audio_player_service.dart';
import 'package:lizunemu/core/settings/app_settings_service.dart';
import 'package:lizunemu/utils/logger.dart';

/// 睡眠定时器：选定时长后到点自动 **暂停** 播放（用 `pause()` 而非
/// `stop()`——`stop()` 会清空持久化播放态，睡眠场景需可恢复）。
///
/// 可选在最后 [fadeOutSeconds] 秒线性淡出音量，并在播放器上叠加睡眠模式暗幕。
///
/// 刻意 **不持久化**：这是会话级控制，重启后静默重新计时是坏 UX，
/// 也避开 `playback_state` 持久化不变量。
class SleepTimerController extends ChangeNotifier {
  static const _tag = 'SleepTimer';

  /// 可选时长档（分钟）。`null` 即对话框里的「关闭」。
  static const List<int> presetMinutes = [15, 30, 45, 60, 90];

  /// 到期前音量淡出窗口（秒）。
  static const int fadeOutSeconds = 30;

  static const double baseDimOpacity = 0.35;
  static const double maxDimOpacity = 0.82;

  final IAudioPlayerService _audioService;
  final AppSettingsService _settings;

  Timer? _timer;
  Timer? _tickTimer;
  int? _minutes;
  int? _remainingSeconds;
  double? _volumeBeforeFade;
  bool _isFading = false;

  SleepTimerController(this._audioService, this._settings);

  /// 当前选定时长（分钟）；`null` = 未设置/已关闭。
  int? get minutes => _minutes;

  bool get isActive => _timer != null;

  bool get isFading => _isFading;

  /// 剩余时间；未激活时为 `null`。
  Duration? get remaining => _remainingSeconds == null
      ? null
      : Duration(seconds: _remainingSeconds!);

  /// 睡眠模式暗幕不透明度（0 = 无暗幕）。
  double get dimOpacity => computeDimOpacity(
        isActive: isActive,
        dimEnabled: _settings.sleepTimerDimScreenEnabled,
        fadeEnabled: _settings.sleepTimerFadeOutEnabled,
        remaining: remaining,
      );

  @visibleForTesting
  static double computeDimOpacity({
    required bool isActive,
    required bool dimEnabled,
    required bool fadeEnabled,
    required Duration? remaining,
  }) {
    if (!isActive || !dimEnabled) return 0;
    if (remaining == null) return 0;
    if (!fadeEnabled) return baseDimOpacity;
    const fadeWindow = Duration(seconds: fadeOutSeconds);
    if (remaining > fadeWindow) return baseDimOpacity;
    final t = 1.0 - (remaining.inMilliseconds / fadeWindow.inMilliseconds);
    return baseDimOpacity +
        (maxDimOpacity - baseDimOpacity) * t.clamp(0.0, 1.0);
  }

  /// 设置定时时长。`null` 或 `<= 0` = 取消。重复设置会先取消旧 Timer。
  void setMinutes(int? minutes) {
    _cancelTimers();
    _restoreVolumeIfNeeded();

    if (minutes == null || minutes <= 0) {
      if (_minutes != null) {
        _minutes = null;
        _remainingSeconds = null;
        notifyListeners();
      }
      return;
    }

    _minutes = minutes;
    _remainingSeconds = minutes * 60;
    _timer = Timer(Duration(minutes: minutes), _onExpire);
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    notifyListeners();
  }

  void cancel() => setMinutes(null);

  void _onTick() {
    if (!isActive) return;

    if (_remainingSeconds != null && _remainingSeconds! > 0) {
      _remainingSeconds = _remainingSeconds! - 1;
    }

    final left = remaining;
    if (left != null && _settings.sleepTimerFadeOutEnabled) {
      const fadeWindow = Duration(seconds: fadeOutSeconds);
      if (left <= fadeWindow) {
        _isFading = true;
        _volumeBeforeFade ??= _audioService.volume;
        final progress =
            1.0 - (left.inMilliseconds / fadeWindow.inMilliseconds);
        final target =
            (_volumeBeforeFade! * (1.0 - progress)).clamp(0.0, 1.0);
        _audioService.setVolume(target, persist: false).catchError(
          (Object e) => AppLogger.error(
            LogStrings.logTagSleepTimerPauseFailed9626d(_tag),
            e,
          ),
        );
      }
    }

    notifyListeners();
  }

  void _onExpire() {
    final restoreVolume = _volumeBeforeFade;
    _cancelTimers();
    _volumeBeforeFade = null;
    _isFading = false;
    _minutes = null;
    _remainingSeconds = null;
    notifyListeners();

    Future<void>(() async {
      if (restoreVolume != null) {
        await _audioService.setVolume(restoreVolume);
      }
      await _audioService.pause(fade: false);
    }).catchError(
      (Object e) => AppLogger.error(
        LogStrings.logTagSleepTimerPauseFailed9626d(_tag),
        e,
      ),
    );
  }

  void _restoreVolumeIfNeeded() {
    final restore = _volumeBeforeFade;
    if (restore == null) return;
    _volumeBeforeFade = null;
    _isFading = false;
    _audioService.setVolume(restore).catchError(
      (Object e) => AppLogger.error(
        LogStrings.logTagSleepTimerPauseFailed9626d(_tag),
        e,
      ),
    );
  }

  void _cancelTimers() {
    _timer?.cancel();
    _timer = null;
    _tickTimer?.cancel();
    _tickTimer = null;
  }

  @override
  void dispose() {
    _cancelTimers();
    _restoreVolumeIfNeeded();
    super.dispose();
  }
}
