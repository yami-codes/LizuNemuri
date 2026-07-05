import 'dart:async';
import 'package:get_it/get_it.dart';
import 'package:xuro/utils/logger.dart';
import 'package:xuro/core/subtitle/i_subtitle_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import './i_audio_player_service.dart';
import './models/audio_track_info.dart';
import './models/playback_context.dart';
import './notification/audio_notification_service.dart';
import './storage/i_playback_state_repository.dart';
import './utils/audio_error_handler.dart';
import './state/playback_state_manager.dart';
import './controllers/playback_controller.dart';
import './utils/volume_fader.dart';
import './events/playback_event_hub.dart';
import 'package:xuro/common/constants/log_strings.dart';
import 'package:xuro/core/settings/app_settings_service.dart';
import 'package:xuro/core/settings/playback_speed_presets.dart';
import 'package:xuro/core/audio/effects/audio_effects_controller.dart';
import 'package:xuro/utils/platform_capabilities.dart';

class AudioPlayerService implements IAudioPlayerService {
  late final AudioPlayer _player;
  AndroidEqualizer? _androidEqualizer;
  late final AudioNotificationService _notificationService;
  late final ConcatenatingAudioSource _playlist;
  late final PlaybackStateManager _stateManager;
  late final PlaybackController _playbackController;
  final PlaybackEventHub _eventHub;
  final IPlaybackStateRepository _stateRepository;
  final Completer<void> _initCompleter = Completer<void>();
  int _fadeGeneration = 0;

  /// Await this before calling any public method to ensure init is complete
  Future<void> get ready => _initCompleter.future;

  AudioPlayerService._internal({
    required PlaybackEventHub eventHub,
    required IPlaybackStateRepository stateRepository,
  }) : _eventHub = eventHub,
       _stateRepository = stateRepository {
    _init();
  }

  static AudioPlayerService? _instance;
  
  factory AudioPlayerService({
    required PlaybackEventHub eventHub,
    required IPlaybackStateRepository stateRepository,
  }) {
    _instance ??= AudioPlayerService._internal(
      eventHub: eventHub,
      stateRepository: stateRepository,
    );
    return _instance!;
  }

  Future<void> _init() async {
    try {
      if (PlatformCapabilities.supportsAndroidEqualizer) {
        _androidEqualizer = AndroidEqualizer();
        _player = AudioPlayer(
          audioPipeline: AudioPipeline(
            androidAudioEffects: [_androidEqualizer!],
          ),
        );
        GetIt.I<AudioEffectsController>().bind(_androidEqualizer!);
      } else {
        _player = AudioPlayer();
      }
      _notificationService = AudioNotificationService(
        _player,
        _eventHub,
        GetIt.I<ISubtitleService>(),
      );
      _playlist = ConcatenatingAudioSource(children: []);

      _stateManager = PlaybackStateManager(
        player: _player,
        stateRepository: _stateRepository,
        eventHub: _eventHub,
      );

      _playbackController = PlaybackController(
        player: _player,
        stateManager: _stateManager,
        playlist: _playlist,
        eventHub: _eventHub,
      );

      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      final settings = GetIt.I<AppSettingsService>();
      final savedVolume = settings.playbackVolume;
      await _player.setVolume(savedVolume.clamp(0.0, 1.0));
      await _player.setSpeed(PlaybackSpeedPresets.clamp(settings.playbackSpeed));
      await _notificationService.init();

      _stateManager.initStateListeners();
      await restorePlaybackState();
      _initCompleter.complete();
    } catch (e, stack) {
      _initCompleter.completeError(e, stack);
      AudioErrorHandler.handleError(
        AudioErrorType.init,
        LogStrings.logOpAudioPlayerInit,
        e,
        stack,
      );
      AudioErrorHandler.throwError(
        AudioErrorType.init,
        LogStrings.logOpAudioPlayerInit,
        e,
      );
    }
  }

  // 基础播放控制
  void _cancelFade() => _fadeGeneration++;

  Future<void> _animateVolume({
    required double from,
    required double to,
    required int durationMs,
  }) async {
    final gen = _fadeGeneration;
    const stepMs = VolumeFader.defaultStepMs;
    final total = VolumeFader.stepCount(durationMs, stepMs: stepMs);
    if (total == 0 || from == to) {
      if (gen != _fadeGeneration) return;
      await setVolume(to.clamp(0.0, 1.0), persist: false);
      return;
    }
    for (var i = 1; i <= total; i++) {
      if (gen != _fadeGeneration) return;
      final vol = VolumeFader.volumeAtStep(
        from: from,
        to: to,
        step: i,
        totalSteps: total,
      );
      await setVolume(vol.clamp(0.0, 1.0), persist: false);
      if (i < total) {
        await Future<void>.delayed(const Duration(milliseconds: stepMs));
      }
    }
  }

  @override
  Future<void> pause({bool fade = true}) async {
    await ready;
    _cancelFade();
    final gen = _fadeGeneration;
    final settings = GetIt.I<AppSettingsService>();
    if (fade && settings.playbackFadeEnabled && settings.playbackFadeMs > 0) {
      final target = settings.playbackVolume;
      final from = _player.volume;
      await _animateVolume(
        from: from,
        to: 0,
        durationMs: settings.playbackFadeMs,
      );
      if (gen != _fadeGeneration) return;
      await _playbackController.pause();
      await _player.setVolume(target.clamp(0.0, 1.0));
    } else {
      await _playbackController.pause();
    }
    // 暂停是用户离开/切后台的强信号，立即 flush 一次，避免依赖 20s 节流。
    await _stateManager.saveState();
  }

  @override
  Future<void> resume({bool fade = true}) async {
    await ready;
    _cancelFade();
    final gen = _fadeGeneration;
    final settings = GetIt.I<AppSettingsService>();
    if (fade && settings.playbackFadeEnabled && settings.playbackFadeMs > 0) {
      final target = settings.playbackVolume;
      await _player.setVolume(0);
      await _playbackController.play();
      await _animateVolume(
        from: 0,
        to: target,
        durationMs: settings.playbackFadeMs,
      );
      if (gen != _fadeGeneration) return;
    } else {
      final target = settings.playbackVolume;
      await _player.setVolume(target.clamp(0.0, 1.0));
      await _playbackController.play();
    }
  }

  @override
  Future<void> stop() async {
    await ready;
    _cancelFade();
    await _playbackController.stop();
    _stateManager.clearState();
    // 停止 = 用户主动结束，清掉持久化，避免下次启动误恢复已停止内容。
    await _stateManager.clearSavedState();
  }

  @override
  Future<void> seek(Duration position) async {
    await ready;
    await _playbackController.seek(position);
  }

  @override
  Future<void> previous() async {
    await ready;
    await _playbackController.previous();
  }

  @override
  Future<void> next() async {
    await ready;
    await _playbackController.next();
  }

  // 上下文管理
  @override
  Future<void> playWithContext(PlaybackContext context) async {
    await ready;
    await _playbackController.setPlaybackContext(context);
    // 添加自动播放
    await resume();
  }

  // 状态访问
  @override
  AudioTrackInfo? get currentTrack => _stateManager.currentTrack;

  @override
  PlaybackContext? get currentContext => _stateManager.currentContext;

  @override
  double get volume => _player.volume;

  @override
  Future<void> setVolume(double volume, {bool persist = true}) async {
    await ready;
    final clamped = volume.clamp(0.0, 1.0);
    await _player.setVolume(clamped);
    if (persist) {
      await GetIt.I<AppSettingsService>().setPlaybackVolume(clamped);
    }
  }

  @override
  double get playbackSpeed => _player.speed;

  @override
  Future<void> setPlaybackSpeed(double speed, {bool persist = true}) async {
    await ready;
    final clamped = PlaybackSpeedPresets.clamp(speed);
    await _player.setSpeed(clamped);
    if (persist) {
      await GetIt.I<AppSettingsService>().setPlaybackSpeed(clamped);
    }
  }

  // 状态持久化
  @override
  Future<void> savePlaybackState() => _stateManager.saveState();

  @override
  Future<void> restorePlaybackState() async {
    try {
      AppLogger.debug(LogStrings.logStartRestoringPlaybackStatebf3e6);
      final state = await _stateManager.loadState();
      
      if (state == null) {
        AppLogger.debug(LogStrings.logNoPlaybackStateToRestored59fb);
        return;
      }

      AppLogger.debug(LogStrings.logLoadedSavedStateWorkidStateW175f5(state.work.id));

      final context = PlaybackContext(
        work: state.work,
        files: state.files,
        currentFile: state.currentFile,
        playMode: state.playMode,
      );

      AppLogger.debug(
          LogStrings.logPlaylistInfoLengthContextPlac41a2(context.playlist.length, context.currentIndex));

      if (context.playlist.isEmpty) {
        AppLogger.debug(LogStrings.logRestoredPlaylistEmptySkipe85b3);
        return;
      }

      try {
        await _playbackController.setPlaybackContext(
          context,
          initialPosition: Duration(milliseconds: state.position),
        );
        AppLogger.debug(LogStrings.logPlaybackStateRestoredc4753);
      } catch (e) {
        AppLogger.error(LogStrings.logSetContextFailedSkipStateRes87ad0, e);
      }
    } catch (e, stack) {
      AudioErrorHandler.handleError(
        AudioErrorType.init,
        LogStrings.logOpRestorePlaybackState,
        e,
        stack,
      );
      rethrow;
    }
  }

  @override
  Future<void> dispose() async {
    _stateManager.dispose();
    await _notificationService.dispose();
    await _player.dispose();
  }
}
