import 'dart:async';
import 'package:just_audio/just_audio.dart';
import '../models/audio_track_info.dart';
import '../models/playback_context.dart';
import '../utils/audio_error_handler.dart';
import '../utils/track_info_creator.dart';
import 'package:lizunemu/data/models/playback/playback_state.dart';
import '../storage/i_playback_state_repository.dart';
import '../events/playback_event.dart';
import '../events/playback_event_hub.dart';
import 'package:lizunemu/data/models/files/child.dart';
import 'package:lizunemu/data/models/works/work.dart';
import 'package:lizunemu/common/constants/log_strings.dart';


class PlaybackStateManager {
  final AudioPlayer _player;
  final PlaybackEventHub _eventHub;
  final IPlaybackStateRepository _stateRepository;
  
  AudioTrackInfo? _currentTrack;
  PlaybackContext? _currentContext;

  final List<StreamSubscription> _subscriptions = [];
  Timer? _saveDebounceTimer;
  static const _saveInterval = Duration(seconds: 20);

  // Persistence serialization + tombstone: all save/clear ops share one Future chain so
  // stop()'s remove always runs after any in-flight save; _persistSuppressed makes any
  // save between stop() and the next non-null playback context a no-op, preventing
  // actively stopped content from being written back to prefs.
  Future<void> _persistChain = Future<void>.value();
  bool _persistSuppressed = false;

  PlaybackStateManager({
    required AudioPlayer player,
    required PlaybackEventHub eventHub,
    required IPlaybackStateRepository stateRepository,
  }) : _player = player,
       _eventHub = eventHub,
       _stateRepository = stateRepository;

  // Initialize state listeners
  void initStateListeners() {
    // Listen for player index changes
    _subscriptions.add(
      _player.currentIndexStream.listen((index) {
        if (index != null && _currentContext != null) {
          if (index >= 0 && index < _currentContext!.playlist.length) {
            final newFile = _currentContext!.playlist[index];
            updateTrackAndContext(newFile, _currentContext!.work);
          }
        }
      }),
    );

    // Listen directly to AudioPlayer raw streams
    _subscriptions.add(
      _player.playerStateStream.listen((state) async {
        final position = _player.position;
        final duration = _player.duration;

        // Convert and emit to EventHub
        _eventHub.emit(PlaybackStateEvent(state, position, duration));

        if (state.processingState == ProcessingState.completed) {
          _onPlaybackCompleted();
        }
        _debounceSave();
      }),
    );

    _subscriptions.add(
      _player.positionStream.listen((position) {
        _eventHub.emit(PlaybackProgressEvent(
          position,
          _player.bufferedPosition
        ));
      }),
    );

    // Listen for player errors
    _subscriptions.add(
      _player.playbackEventStream.listen(
        (_) {},
        onError: (error, stackTrace) {
          _eventHub.emit(PlaybackErrorEvent('playerStream', error, stackTrace));
        },
      ),
    );

    _setupEventListeners();
  }

  void _debounceSave() {
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(_saveInterval, () {
      saveState();
    });
  }

  // State update methods
  void updateContext(PlaybackContext? context) {
    _currentContext = context;
    if (context != null) {
      // New playback content lifts the persistence suppression set by stop().
      _persistSuppressed = false;
      _eventHub.emit(PlaybackContextEvent(context));
    }
  }

  void updateTrackInfo(AudioTrackInfo track) {
    _currentTrack = track;
    if (_currentContext != null) {
      _eventHub.emit(TrackChangeEvent(track, _currentContext!.currentFile, _currentContext!.work));
    }
  }

  void updateTrackAndContext(Child file, Work work) {
    if (_currentContext != null) {
      final newContext = _currentContext!.copyWithFile(file);
      updateContext(newContext);
    }
    
    final trackInfo = TrackInfoCreator.createFromFile(file, work);
    updateTrackInfo(trackInfo);
  }

  void _onPlaybackCompleted() {
    if (_currentContext == null) return;
    saveState(); // Immediate save on completion
    _eventHub.emit(PlaybackCompletedEvent(_currentContext!));
  }

  // State access
  AudioTrackInfo? get currentTrack => _currentTrack;
  PlaybackContext? get currentContext => _currentContext;

  void clearState() {
    _currentTrack = null;
    _currentContext = null;
    _eventHub.emit(PlaybackClearedEvent());
  }

  // State persistence (all serialized via _persistChain to eliminate save/clear races)
  Future<void> saveState() {
    if (_persistSuppressed) return _persistChain;
    final context = _currentContext;
    if (context == null) return _persistChain;

    // Snapshot context and position at call time: when the chain runs, _currentContext
    // may already be cleared by stop(); the snapshot preserves the state at request time.
    final positionMs = _player.position.inMilliseconds;
    _persistChain = _persistChain.then((_) async {
      // If stop() ran after enqueue but before execution, drop this write.
      if (_persistSuppressed) return;
      try {
        final state = PlaybackState(
          work: context.work,
          files: context.files,
          currentFile: context.currentFile,
          playMode: context.playMode,
          position: positionMs,
          timestamp: DateTime.now().toIso8601String(),
        );
        await _stateRepository.saveState(state);
      } catch (e, stack) {
        AudioErrorHandler.handleError(
          AudioErrorType.state,
          LogStrings.logOpSavePlaybackState,
          e,
          stack,
        );
      }
    });
    return _persistChain;
  }

  Future<void> clearSavedState() {
    // Set synchronously: subsequent saveState() calls become no-ops immediately;
    // remove is appended to the chain tail, always after enqueued saves, so remove is the final write.
    _persistSuppressed = true;
    _persistChain = _persistChain.then((_) async {
      try {
        await _stateRepository.clearState();
      } catch (e, stack) {
        AudioErrorHandler.handleError(
          AudioErrorType.state,
          LogStrings.logOpClearPlaybackState,
          e,
          stack,
        );
      }
    });
    return _persistChain;
  }

  Future<PlaybackState?> loadState() async {
    try {
      return await _stateRepository.loadState();
    } catch (e, stack) {
      AudioErrorHandler.handleError(
        AudioErrorType.state,
        LogStrings.logOpLoadPlaybackState,
        e,
        stack,
      );
      return null;
    }
  }

  void _setupEventListeners() {
    // Handle initial-state requests
    _subscriptions.add(
      _eventHub.requestInitialState.listen((_) {
        _eventHub.emit(InitialStateEvent(
          _currentTrack,
          _currentContext
        ));
      }),
    );
  }

  void dispose() {
    // Best-effort flush before cancelling the timer (dispose cannot await).
    if (_currentContext != null) {
      saveState();
    }
    _saveDebounceTimer?.cancel();
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }
} 