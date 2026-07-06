import './models/audio_track_info.dart';
import './models/playback_context.dart';

abstract class IAudioPlayerService {
  // Basic playback controls
  Future<void> pause({bool fade = true});
  Future<void> resume({bool fade = true});
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> previous();
  Future<void> next();
  Future<void> dispose();

  // Context management
  Future<void> playWithContext(PlaybackContext context);
  
  // State access
  AudioTrackInfo? get currentTrack;
  PlaybackContext? get currentContext;

  // State persistence
  Future<void> savePlaybackState();
  Future<void> restorePlaybackState();

  /// Output volume 0.0–1.0 (just_audio).
  double get volume;
  Future<void> setVolume(double volume, {bool persist = true});

  /// Playback speed multiplier (1.0 = normal).
  double get playbackSpeed;
  Future<void> setPlaybackSpeed(double speed, {bool persist = true});
}
