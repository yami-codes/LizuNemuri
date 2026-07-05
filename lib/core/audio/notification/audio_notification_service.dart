import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:lizunemu/core/audio/events/playback_event_hub.dart';
import 'package:lizunemu/core/subtitle/i_subtitle_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lizunemu/utils/logger.dart';
import 'package:lizunemu/utils/platform_capabilities.dart';
import '../models/audio_track_info.dart';
import '../audio_player_handler.dart';
import 'package:lizunemu/common/constants/log_strings.dart';

class AudioNotificationService {
  final AudioPlayer _player;
  final PlaybackEventHub _eventHub;
  final ISubtitleService _subtitleService;
  AudioHandler? _audioHandler;
  StreamSubscription? _trackChangeSubscription;
  StreamSubscription? _stateSubscription;
  StreamSubscription? _subtitleSubscription;

  // Latest pieces that compose the lock-screen MediaItem. The Android media
  // notification only renders a duration-backed seekbar when the MediaItem
  // carries a non-null duration — but at trackChange time the source is often
  // not loaded yet, so the real duration arrives later via playbackState.
  AudioTrackInfo? _currentTrack;
  Duration? _knownDuration;
  String? _currentLyric;

  AudioNotificationService(
    this._player,
    this._eventHub,
    this._subtitleService,
  );

  Future<void> init() async {
    if (!PlatformCapabilities.supportsMediaNotification) {
      AppLogger.debug(LogStrings.logNotificationServiceSkipped);
      return;
    }
    try {
      // Request notification permission (Android 13+)
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.notification.request();
      }

      _audioHandler = await AudioService.init(
        builder: () => AudioPlayerHandler(_player, _eventHub),
        config: AudioServiceConfig(
          androidNotificationChannelId: 'moe.lizu.nemu.audio',
          androidNotificationChannelName: LogStrings.logNotificationChannelName,
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: true,
        ),
      );

      _setupEventListeners();
      AppLogger.debug(LogStrings.logNotificationServiceInitializc2ef2);
    } catch (e) {
      AppLogger.error(LogStrings.logNotificationServiceInitFailef5f41, e);
      if (!PlatformCapabilities.supportsMediaNotification) return;
      rethrow;
    }
  }

  void _setupEventListeners() {
    _trackChangeSubscription = _eventHub.trackChange.listen((event) {
      _currentTrack = event.track;
      // TrackInfoCreator doesn't fill duration; when a paused track is
      // restored the ready/duration event can arrive before trackChange, so
      // fall back to the player's known duration instead of resetting to null.
      _knownDuration = event.track.duration ?? _player.duration;
      _currentLyric = null;
      _pushMediaItem();
    });

    // Duration is usually unknown at trackChange; capture it once the player
    // reports it so the lock-screen seekbar can appear.
    _stateSubscription = _eventHub.playbackState.listen((event) {
      final duration = event.duration;
      if (duration != null && duration != _knownDuration) {
        _knownDuration = duration;
        _pushMediaItem();
      }
    });

    // Surface the current subtitle line on the lock screen. Android's
    // MediaStyle notification has no dedicated lyric line, so the active line
    // replaces the artist row; it falls back to the real artist when absent.
    _subtitleSubscription =
        _subtitleService.currentSubtitleStream.listen((subtitle) {
      final text = subtitle?.text;
      if (text == _currentLyric) return;
      _currentLyric = text;
      _pushMediaItem();
    });
  }

  void _pushMediaItem() {
    final track = _currentTrack;
    if (track == null || _audioHandler == null) return;

    final lyric = _currentLyric;
    final mediaItem = MediaItem(
      id: track.url,
      title: track.title,
      artist: (lyric != null && lyric.isNotEmpty) ? lyric : track.artist,
      artUri: Uri.parse(track.coverUrl),
      duration: _knownDuration ?? track.duration,
    );

    (_audioHandler as BaseAudioHandler).mediaItem.add(mediaItem);
  }

  Future<void> dispose() async {
    _trackChangeSubscription?.cancel();
    _stateSubscription?.cancel();
    _subtitleSubscription?.cancel();
    final handler = _audioHandler;
    if (handler is AudioPlayerHandler) {
      await handler.cancelSubscriptions();
    }
    await _audioHandler?.stop();
  }
}
