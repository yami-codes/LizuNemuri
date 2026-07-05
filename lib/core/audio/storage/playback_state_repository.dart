import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lizunemu/utils/logger.dart';
import 'package:lizunemu/data/models/playback/playback_state.dart';
import 'i_playback_state_repository.dart';
import 'package:lizunemu/common/constants/log_strings.dart';

class PlaybackStateRepository implements IPlaybackStateRepository {
  static const _key = 'last_playback_state';
  final SharedPreferences _prefs;

  PlaybackStateRepository(this._prefs);

  @override
  Future<void> saveState(PlaybackState state) async {
    try {
      final json = state.toJson();
      final data = jsonEncode(json);
      await _prefs.setString(_key, data);
      AppLogger.debug(LogStrings.logPlaybackStateSaved8075d);
    } catch (e) {
      AppLogger.error(LogStrings.logSavePlaybackStateFailed48c3d, e);
      rethrow;
    }
  }

  @override
  Future<void> clearState() async {
    try {
      await _prefs.remove(_key);
      AppLogger.debug(LogStrings.logPlaybackStateCleareda68e0);
    } catch (e) {
      AppLogger.error(LogStrings.logClearPlaybackStateFailedebdde, e);
      rethrow;
    }
  }

  @override
  Future<PlaybackState?> loadState() async {
    try {
      final data = _prefs.getString(_key);
      if (data == null) {
        AppLogger.debug(LogStrings.logNoSavedPlaybackStated1b67);
        return null;
      }

      final json = jsonDecode(data) as Map<String, dynamic>;
      final state = PlaybackState.fromJson(json);
      AppLogger.debug(LogStrings.logPlaybackStateLoadedbf046);
      return state;
    } catch (e) {
      AppLogger.error(LogStrings.logLoadPlaybackStateFailed21627, e);
      return null;
    }
  }
} 