# ASMR One App Audio Playback Architecture

## 1. Architecture Overview

This document describes the audio playback architecture for the ASMR One App. Following Clean Architecture, it uses an event-driven design split into core, data, and presentation layers.

## 2. Directory Structure

<pre>
lib/
├── core/
│   └── audio/                      # Audio core
│       ├── audio_player_service.dart    # Audio service implementation
│       ├── i_audio_player_service.dart  # Audio service interface
│       ├── controllers/                 # Controllers
│       │   └── playback_controller.dart # Playback controller
│       ├── events/                      # Event system
│       │   ├── playback_event.dart     # Event definitions
│       │   └── playback_event_hub.dart # Event hub
│       ├── models/                      # Data models
│       │   ├── audio_track_info.dart   # Track info
│       │   └── playback_context.dart   # Playback context
│       ├── notification/                # Notifications
│       │   └── audio_notification_service.dart
│       ├── state/                       # State management
│       │   └── playback_state_manager.dart
│       ├── storage/                     # State persistence
│       │   ├── i_playback_state_repository.dart
│       │   └── playback_state_repository.dart
│       └── utils/                       # Utilities
│           ├── audio_error_handler.dart
│           ├── playlist_builder.dart
│           └── track_info_creator.dart
└── presentation/
    └── viewmodels/
        └── player_viewmodel.dart   # Player view model
</pre>

## 3. Core Component Design

### 3.1 Audio Service Interface (IAudioPlayerService)

<pre>
abstract class IAudioPlayerService {
  // Basic playback control
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> previous();
  Future<void> next();
  
  // Context management
  Future<void> playWithContext(PlaybackContext context);
  
  // State access
  AudioTrackInfo? get currentTrack;
  PlaybackContext? get currentContext;
  
  // State persistence
  Future<void> savePlaybackState();
  Future<void> restorePlaybackState();
}
</pre>

### 3.2 Event System (PlaybackEventHub)

<pre>
class PlaybackEventHub {
  // Main event stream
  final _eventSubject = PublishSubject<PlaybackEvent>();
  
  // Typed event streams
  late final Stream<PlaybackStateEvent> playbackState;
  late final Stream<TrackChangeEvent> trackChange;
  late final Stream<PlaybackContextEvent> contextChange;
  late final Stream<PlaybackProgressEvent> playbackProgress;
  late final Stream<PlaybackErrorEvent> errors;
  
  void emit(PlaybackEvent event);
}
</pre>

## 4. Event Model

### 4.1 Playback Events (PlaybackEvent)

<pre>
abstract class PlaybackEvent {}

class PlaybackStateEvent extends PlaybackEvent {
  final PlayerState state;
  final Duration position;
  final Duration? duration;
}

class TrackChangeEvent extends PlaybackEvent {
  final AudioTrackInfo track;
  final Child file;
  final Work work;
}

// ... other event types
</pre>

## 5. State Management

### 5.1 Playback State Manager (PlaybackStateManager)

<pre>
class PlaybackStateManager {
  final AudioPlayer _player;
  final PlaybackEventHub _eventHub;
  final IPlaybackStateRepository _stateRepository;
  
  void initStateListeners();
  void updateContext(PlaybackContext? context);
  void updateTrackInfo(AudioTrackInfo track);
  Future<void> saveState();
  Future<PlaybackState?> loadState();
}
</pre>

## 6. Notification Integration

### 6.1 Notification Service (AudioNotificationService)

<pre>
class AudioNotificationService {
  final AudioPlayer _player;
  final PlaybackEventHub _eventHub;
  AudioHandler? _audioHandler;
  
  Future<void> init();
  void updateMetadata(AudioTrackInfo trackInfo);
}
</pre>

## 7. Implementation Details

### 7.1 Dependency Injection

GetIt manages dependencies:
- PlaybackEventHub registered as singleton
- AudioPlayerService registered as lazy singleton
- All dependencies injected via constructors

### 7.2 Event-Driven Design

- RxDart for event streams
- Central event hub for all playback-related events
- Components communicate via events to reduce coupling

### 7.3 Error Handling

- Unified error handling
- Errors propagated through EventHub
- Supports error tracking and logging

## 8. Development Plan

1. Improve playback experience
   - Optimize event handling performance
   - Complete error handling
   - Improve state synchronization

2. Enhance features
   - Playlist support
   - More play modes
   - Cache strategy improvements

3. Architecture improvements
   - Further decouple components
   - Optimize dependency injection
   - Expand unit test coverage
