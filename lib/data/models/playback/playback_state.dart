import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:lizunemu/data/models/works/work.dart';
import 'package:lizunemu/data/models/files/files.dart';
import 'package:lizunemu/data/models/files/child.dart';
import 'package:lizunemu/core/audio/models/play_mode.dart';

part 'playback_state.freezed.dart';
part 'playback_state.g.dart';

@freezed
class PlaybackState with _$PlaybackState {
  // playlist / currentIndex not persisted: PlaybackContext factory re-derives from files + currentFile.
  const factory PlaybackState({
    required Work work,
    required Files files,
    required Child currentFile,
    required PlayMode playMode,
    required int position,  // Stored in milliseconds
    required String timestamp,  // ISO8601 string
  }) = _PlaybackState;

  factory PlaybackState.fromJson(Map<String, dynamic> json) => 
      _$PlaybackStateFromJson(json);
} 