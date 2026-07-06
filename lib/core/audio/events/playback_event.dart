import 'package:just_audio/just_audio.dart';
import '../models/audio_track_info.dart';
import '../models/playback_context.dart';
import 'package:lizunemu/data/models/files/child.dart';
import 'package:lizunemu/data/models/works/work.dart';

/// Base playback event.
abstract class PlaybackEvent {}

/// Playback state event.
class PlaybackStateEvent extends PlaybackEvent {
  final PlayerState state;
  final Duration position;
  final Duration? duration;
  PlaybackStateEvent(this.state, this.position, this.duration);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaybackStateEvent &&
          state.playing == other.state.playing &&
          state.processingState == other.state.processingState &&
          position.inMilliseconds ~/ 100 == other.position.inMilliseconds ~/ 100 &&
          duration == other.duration;

  @override
  int get hashCode => Object.hash(
        state.playing,
        state.processingState,
        position.inMilliseconds ~/ 100,
        duration,
      );
}

/// Playback context event.
class PlaybackContextEvent extends PlaybackEvent {
  final PlaybackContext context;
  PlaybackContextEvent(this.context);
}

/// Track change event.
class TrackChangeEvent extends PlaybackEvent {
  final AudioTrackInfo track;
  final Child file;
  final Work work;
  TrackChangeEvent(this.track, this.file, this.work);
}

/// Playback error event.
class PlaybackErrorEvent extends PlaybackEvent {
  final String operation;
  final dynamic error;
  final StackTrace? stackTrace;
  PlaybackErrorEvent(this.operation, this.error, [this.stackTrace]);
}

/// Playback completed event.
class PlaybackCompletedEvent extends PlaybackEvent {
  final PlaybackContext context;
  PlaybackCompletedEvent(this.context);
}

/// Playback progress event.
class PlaybackProgressEvent extends PlaybackEvent {
  final Duration position;
  final Duration? bufferedPosition;
  PlaybackProgressEvent(this.position, this.bufferedPosition);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaybackProgressEvent &&
          position == other.position;

  @override
  int get hashCode => position.hashCode;
}

/// Initial-state related events.
class RequestInitialStateEvent extends PlaybackEvent {}

class InitialStateEvent extends PlaybackEvent {
  final AudioTrackInfo? track;
  final PlaybackContext? context;
  InitialStateEvent(this.track, this.context);
}

class PlaybackClearedEvent extends PlaybackEvent {}