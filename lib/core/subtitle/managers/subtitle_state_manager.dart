import 'dart:async';
import 'package:xuro/core/audio/models/subtitle.dart';
import 'package:xuro/utils/logger.dart';
import 'package:xuro/common/constants/log_strings.dart';

class SubtitleStateManager {
  SubtitleList? _subtitleList;
  Subtitle? _currentSubtitle;
  SubtitleWithState? _currentSubtitleWithState;

  final _subtitleController = StreamController<SubtitleList?>.broadcast();
  final _currentSubtitleController = StreamController<Subtitle?>.broadcast();
  final _currentSubtitleWithStateController = StreamController<SubtitleWithState?>.broadcast();

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
  }

  void updatePosition(Duration position) {
    if (_subtitleList != null) {
      final newSubtitleWithState = _subtitleList!.getCurrentSubtitle(position);
      if (newSubtitleWithState?.subtitle != _currentSubtitleWithState?.subtitle) {
        _currentSubtitleWithState = newSubtitleWithState;
        _currentSubtitle = newSubtitleWithState?.subtitle;
        AppLogger.debug(LogStrings.logSubtitleStateUpdated(_currentSubtitle?.text ?? LogStrings.logNoSubtitle, newSubtitleWithState?.state.toString() ?? ''));
        _currentSubtitleWithStateController.add(newSubtitleWithState);
        _currentSubtitleController.add(_currentSubtitle);
      }
    }
  }

  void clear() {
    _subtitleList = null;
    _currentSubtitle = null;
    _currentSubtitleWithState = null;
    _subtitleController.add(null);
    _currentSubtitleController.add(null);
    _currentSubtitleWithStateController.add(null);
    AppLogger.debug(LogStrings.logSubtitleStateCleared0e6a2);
  }

  void dispose() {
    _subtitleController.close();
    _currentSubtitleController.close();
    _currentSubtitleWithStateController.close();
  }
} 