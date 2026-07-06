import 'dart:async';
import 'package:lizunemu/common/constants/log_strings.dart';

import 'package:flutter/foundation.dart';

import 'package:lizunemu/core/audio/i_audio_player_service.dart';
import 'package:lizunemu/core/settings/app_settings_service.dart';
import 'package:lizunemu/utils/logger.dart';

/// Sleep timer: at expiry **pause** playback (`pause()` not `stop()` — stop clears persisted state).
///
/// Optional linear volume fade in the last [fadeOutSeconds] plus a sleep-mode dim overlay.
///
/// **Not persisted**: session-only; re-arming on launch is bad UX and avoids playback_state invariants.
class SleepTimerController extends ChangeNotifier {
  static const _tag = 'SleepTimer';

  /// Preset durations in minutes. `null` = off in the dialog.
  static const List<int> presetMinutes = [15, 30, 45, 60, 90];

  /// Volume fade window before expiry (seconds).
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

  /// Selected duration in minutes; `null` = off.
  int? get minutes => _minutes;

  bool get isActive => _timer != null;

  bool get isFading => _isFading;

  /// Remaining time; `null` when inactive.
  Duration? get remaining => _remainingSeconds == null
      ? null
      : Duration(seconds: _remainingSeconds!);

  /// Sleep-mode dim overlay opacity (0 = none).
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

  /// Set duration. `null` or `<= 0` cancels. Replaces any existing Timer.
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
