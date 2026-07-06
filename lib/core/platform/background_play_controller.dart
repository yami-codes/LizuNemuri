import 'package:flutter/widgets.dart';
import 'package:lizunemu/common/constants/log_strings.dart';

import 'package:lizunemu/core/audio/i_audio_player_service.dart';
import 'package:lizunemu/core/settings/app_settings_service.dart';
import 'package:lizunemu/utils/logger.dart';

/// Background-play switch executor: when the user **disables** background play
/// and the app backgrounds, pause playback.
///
/// Default [AppSettingsService.backgroundPlayEnabled] = `true` preserves always-on background play.
/// **Pause only, never auto-resume** on foreground return. Calls existing public `pause()` only.
class BackgroundPlayController with WidgetsBindingObserver {
  static const _tag = 'BackgroundPlay';

  final AppSettingsService _settings;
  final IAudioPlayerService _audioService;

  bool _initialized = false;

  BackgroundPlayController({
    required AppSettingsService settings,
    required IAudioPlayerService audioService,
  })  : _settings = settings,
        _audioService = audioService;

  /// Register lifecycle observer (idempotent; mirrors CacheLifecycleManager).
  void initialize() {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.paused) return;
    if (_settings.backgroundPlayEnabled) return;
    _audioService.pause().catchError(
      (Object e) => AppLogger.error(LogStrings.logTagBackgroundPauseFailed79342(_tag), e),
    );
  }
}
