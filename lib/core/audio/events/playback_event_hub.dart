import 'package:rxdart/rxdart.dart';
import './playback_event.dart';

class PlaybackEventHub {
  // Unified event stream for all event types
  final _eventSubject = PublishSubject<PlaybackEvent>();

  // Typed event streams
  late final Stream<PlaybackStateEvent> playbackState = _eventSubject
      .whereType<PlaybackStateEvent>()
      .distinct();
      
  late final Stream<TrackChangeEvent> trackChange = _eventSubject
      .whereType<TrackChangeEvent>();
      
  late final Stream<PlaybackContextEvent> contextChange = _eventSubject
      .whereType<PlaybackContextEvent>();
      
  late final Stream<PlaybackProgressEvent> playbackProgress = _eventSubject
      .whereType<PlaybackProgressEvent>()
      .distinct((prev, next) => prev.position == next.position);
      
  late final Stream<PlaybackErrorEvent> errors = _eventSubject
      .whereType<PlaybackErrorEvent>();

  // Additional event streams
  late final Stream<InitialStateEvent> initialState = _eventSubject
      .whereType<InitialStateEvent>();
      
  late final Stream<RequestInitialStateEvent> requestInitialState = _eventSubject
      .whereType<RequestInitialStateEvent>();

  late final Stream<PlaybackClearedEvent> playbackCleared = _eventSubject
      .whereType<PlaybackClearedEvent>();

  late final Stream<PlaybackCompletedEvent> playbackCompleted = _eventSubject
      .whereType<PlaybackCompletedEvent>();

  // Emit events
  void emit(PlaybackEvent event) => _eventSubject.add(event);

  // Release resources
  void dispose() => _eventSubject.close();
} 