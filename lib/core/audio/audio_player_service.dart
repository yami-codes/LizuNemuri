import 'dart:async';
import 'package:get_it/get_it.dart';
import 'package:lizunemu/utils/logger.dart';
import 'package:lizunemu/core/subtitle/i_subtitle_service.dart';
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
import 'package:lizunemu/common/constants/log_strings.dart';
import 'package:lizunemu/core/settings/app_settings_service.dart';
import 'package:lizunemu/core/settings/playback_speed_presets.dart';
import 'package:lizunemu/core/audio/effects/audio_effects_controller.dart';
import 'package:lizunemu/utils/platform_capabilities.dart';

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

  // Basic playback controls
  void _cancelFade() => _fadeGeneration++;

  /// Wait until ExoPlayer / desktop pipeline attaches before ramping volume.
  /// Without this, Android can stay silent at volume 0 until the user moves the slider.
  Future<void> _waitForPlaybackPipelineReady() async {
    final state = _player.processingState;
    if (state == ProcessingState.ready || state == ProcessingState.completed) {
      return;
    }
    try {
      await _player.processingStateStream
          .firstWhere(
            (s) =>
                s == ProcessingState.ready || s == ProcessingState.completed,
          )
          .timeout(const Duration(seconds: 60));
    } on TimeoutException {
      // Best-effort — still run fade restore so volume is not stuck at zero.
    }
  }

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
    final target = settings.playbackVolume.clamp(0.0, 1.0);
    try {
      if (fade && settings.playbackFadeEnabled && settings.playbackFadeMs > 0) {
        final from = _player.volume;
        await _animateVolume(
          from: from,
          to: 0,
          durationMs: settings.playbackFadeMs,
        );
        if (gen != _fadeGeneration) return;
        await _playbackController.pause();
      } else {
        await _playbackController.pause();
      }
    } finally {
      if (!_player.playing) {
        await _player.setVolume(target);
      }
    }
    // Pause is a strong signal that the user left or backgrounded the app; flush immediately instead of waiting for the 20s throttle.
    await _stateManager.saveState();
  }

  @override
  Future<void> resume({bool fade = true}) async {
    await ready;
    _cancelFade();
    final gen = _fadeGeneration;
    final settings = GetIt.I<AppSettingsService>();
    final target = settings.playbackVolume.clamp(0.0, 1.0);
    try {
      final session = await AudioSession.instance;
      await session.setActive(true);
      if (fade && settings.playbackFadeEnabled && settings.playbackFadeMs > 0) {
        await _player.setVolume(0);
        await _playbackController.play();
        await _waitForPlaybackPipelineReady();
        if (gen != _fadeGeneration) return;
        await _animateVolume(
          from: 0,
          to: target,
          durationMs: settings.playbackFadeMs,
        );
        if (gen != _fadeGeneration) return;
        await setVolume(target, persist: false);
      } else {
        await _player.setVolume(target);
        await _playbackController.play();
      }
    } finally {
      if (VolumeFader.shouldRestoreVolume(
        isPlaying: _player.playing,
        currentVolume: _player.volume,
        targetVolume: target,
      )) {
        await setVolume(target, persist: false);
      }
    }
  }

  @override
  Future<void> stop() async {
    await ready;
    _cancelFade();
    await _playbackController.stop();
    _stateManager.clearState();
    // Stop = user explicitly ended playback; clear persistence so the next launch does not restore stopped content.
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

  // Context management
  @override
  Future<void> playWithContext(PlaybackContext context) async {
    await ready;
    await _playbackController.setPlaybackContext(context);
    // Enable auto-play
    await resume();
  }

  // State access
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

  // State persistence
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
