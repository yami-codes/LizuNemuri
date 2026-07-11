import 'dart:async';
import 'package:lizunemu/core/audio/models/subtitle.dart';
import 'package:lizunemu/utils/logger.dart';
import 'package:lizunemu/common/constants/log_strings.dart';

class SubtitleStateManager {
  SubtitleList? _subtitleList;
  Subtitle? _currentSubtitle;
  SubtitleWithState? _currentSubtitleWithState;
  Duration? _lastPosition;

  final _subtitleController = StreamController<SubtitleList?>.broadcast();
  final _currentSubtitleController = StreamController<Subtitle?>.broadcast();
  final _currentSubtitleWithStateController =
      StreamController<SubtitleWithState?>.broadcast();

  Stream<SubtitleList?> get subtitleStream => _subtitleController.stream;
  Stream<Subtitle?> get currentSubtitleStream => _currentSubtitleController.stream;
  Stream<SubtitleWithState?> get currentSubtitleWithStateStream =>
      _currentSubtitleWithStateController.stream;

  Subtitle? get currentSubtitle => _currentSubtitle;
  SubtitleList? get subtitleList => _subtitleList;
  SubtitleWithState? get currentSubtitleWithState => _currentSubtitleWithState;

  void setSubtitleList(SubtitleList? subtitleList) {
    _subtitleList = subtitleList;
    _subtitleController.add(_subtitleList);

    if (_subtitleList == null) {
      _emitCurrent(null);
      return;
    }

    if (_lastPosition != null) {
      _syncCurrentSubtitle(_lastPosition!);
    }
  }

  void updatePosition(Duration position) {
    _lastPosition = position;
    if (_subtitleList != null) {
      _syncCurrentSubtitle(position);
    }
  }

  void _syncCurrentSubtitle(Duration position) {
    final newSubtitleWithState = _subtitleList!.getCurrentSubtitle(position);
    final newIndex = newSubtitleWithState?.subtitle.index;
    final oldIndex = _currentSubtitleWithState?.subtitle.index;
    final newState = newSubtitleWithState?.state;
    final oldState = _currentSubtitleWithState?.state;

    if (newIndex != oldIndex || newState != oldState) {
      _emitCurrent(newSubtitleWithState);
      return;
    }

    if (newSubtitleWithState == null) return;

    // Same cue index/state — refresh refs (streaming text) without stream emit.
    _currentSubtitleWithState = newSubtitleWithState;
    _currentSubtitle = newSubtitleWithState.subtitle;
  }

  void _emitCurrent(SubtitleWithState? newSubtitleWithState) {
    _currentSubtitleWithState = newSubtitleWithState;
    _currentSubtitle = newSubtitleWithState?.subtitle;
    AppLogger.debug(LogStrings.logSubtitleStateUpdated(
      _currentSubtitle?.text ?? LogStrings.logNoSubtitle,
      newSubtitleWithState?.state.toString() ?? '',
    ));
    _currentSubtitleWithStateController.add(newSubtitleWithState);
    _currentSubtitleController.add(_currentSubtitle);
  }

  void clear() {
    _subtitleList = null;
    _lastPosition = null;
    _emitCurrent(null);
    _subtitleController.add(null);
    AppLogger.debug(LogStrings.logSubtitleStateCleared0e6a2);
  }

  void dispose() {
    _subtitleController.close();
    _currentSubtitleController.close();
    _currentSubtitleWithStateController.close();
  }
}
