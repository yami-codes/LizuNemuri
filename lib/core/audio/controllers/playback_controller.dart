import 'package:lizunemu/utils/logger.dart';
import 'package:just_audio/just_audio.dart';
import '../models/playback_context.dart';
import '../state/playback_state_manager.dart';
import '../utils/playlist_builder.dart';
import '../utils/audio_error_handler.dart';
import '../events/playback_event_hub.dart';
import '../events/playback_event.dart';
import '../models/play_mode.dart';
import 'package:lizunemu/data/models/files/child.dart';
import 'package:lizunemu/data/models/works/work.dart';
import 'package:lizunemu/common/constants/log_strings.dart';


class PlaybackController {
  final AudioPlayer _player;
  final PlaybackStateManager _stateManager;
  final ConcatenatingAudioSource _playlist;
  final PlaybackEventHub _eventHub;

  PlaybackController({
    required AudioPlayer player,
    required PlaybackStateManager stateManager,
    required ConcatenatingAudioSource playlist,
    required PlaybackEventHub eventHub,
  }) : _player = player,
       _stateManager = stateManager,
       _playlist = playlist,
       _eventHub = eventHub;

  // 基础播放控制
  Future<void> play() => _player.play();
  Future<void> pause() => _player.pause();
  Future<void> stop() => _player.stop();
  Future<void> seek(Duration position, {int? index}) => _player.seek(position, index: index);
  
  // 播放列表控制
  Future<void> next() async {
    try {
      AppLogger.debug(LogStrings.logTrySkipNextac03e);
      if (_stateManager.currentContext == null) {
        AppLogger.debug(LogStrings.logNoContextCannotSkipNextdc074);
        return;
      }

      if (_player.hasNext) {
        AppLogger.debug(LogStrings.logSwitchingToNextTrack5bd58);
        await _player.seekToNext();
      } else {
        AppLogger.debug(LogStrings.logNoNextTrack1c8bb);
      }
    } catch (e, stack) {
      AppLogger.error(LogStrings.logSkipNextFailed2be30, e, stack);
      _eventHub.emit(PlaybackErrorEvent('next', e, stack));
      AudioErrorHandler.handleError(
        AudioErrorType.playback,
        LogStrings.logOpSkipNext,
        e,
        stack,
      );
    }
  }

  Future<void> previous() async {
    try {
      AppLogger.debug(LogStrings.logTrySkipPrevious376dc);
      if (_stateManager.currentContext == null) {
        AppLogger.debug(LogStrings.logNoContextCannotSkipPreviousc1953);
        return;
      }

      if (_player.hasPrevious) {
        AppLogger.debug(LogStrings.logSwitchingToPreviousTrackabca4);
        await _player.seekToPrevious();
      } else {
        AppLogger.debug(LogStrings.logNoPreviousTrackb0605);
      }
    } catch (e, stack) {
      AppLogger.error(LogStrings.logSkipPreviousFailed965b5, e, stack);
      _eventHub.emit(PlaybackErrorEvent('previous', e, stack));
      AudioErrorHandler.handleError(
        AudioErrorType.playback,
        LogStrings.logOpSkipPrevious,
        e,
        stack,
      );
    }
  }

  // 播放上下文设置
  Future<void> setPlaybackContext(PlaybackContext originalContext, {Duration? initialPosition}) async {
    try {
      AppLogger.debug(LogStrings.logPreparePlaybackContextWorkid46397(originalContext.work.id, originalContext.currentFile.title));
      AppLogger.debug(LogStrings.logPlaylistStateLengthOriginalc24b5f(originalContext.playlist.length, originalContext.currentIndex));

      // 验证上下文
      try {
        originalContext.validate();
      } catch (e) {
        AppLogger.error(LogStrings.logPlaybackContextValidationFaica38c, e);
        rethrow;
      }

      // 1. 先停止当前播放
      AppLogger.debug(LogStrings.logStopCurrentPlayback61998);
      await _player.stop();

      // 2. 设置新的播放源
      AppLogger.debug(LogStrings.logSetPlaybackSourceInitial(initialPosition?.inMilliseconds.toString() ?? '0'));
      List<Child> loadedFiles;
      try {
        loadedFiles = await PlaylistBuilder.setPlaylistSource(
          player: _player,
          playlist: _playlist,
          files: originalContext.playlist,
          initialIndex: originalContext.currentIndex,
          initialPosition: initialPosition ?? Duration.zero,
          workId: originalContext.work.id.toString(),
        );
      } catch (e, stack) {
        AppLogger.error(LogStrings.logSetPlaybackSourceFailed81f10, e, stack);
        rethrow;
      }

      // 3. 加载成功后更新上下文
      var context = originalContext;
      if (loadedFiles.length != originalContext.playlist.length) {
        final currentFile = loadedFiles.contains(originalContext.currentFile)
            ? originalContext.currentFile
            : loadedFiles.first;
        context = PlaybackContext.withFilteredPlaylist(
          work: originalContext.work,
          files: originalContext.files,
          currentFile: currentFile,
          playlist: loadedFiles,
          playMode: originalContext.playMode,
        );
      }
      _stateManager.updateContext(context);

      // Set loop mode based on play mode
      await _player.setLoopMode(context.playMode.toLoopMode());

      // 4. 更新轨道信息
      AppLogger.debug(LogStrings.logUpdateTrackInfoeb504);
      _updateTrackAndContext(context.currentFile, context.work);

      AppLogger.debug(LogStrings.logPlaybackContextSetaa3cc);
    } catch (e, stack) {
      AppLogger.error(LogStrings.logSetPlaybackContextFailed866ab, e, stack);
      _eventHub.emit(PlaybackErrorEvent('setPlaybackContext', e, stack));
      AudioErrorHandler.handleError(
        AudioErrorType.context,
        LogStrings.logOpSetContext,
        e,
        stack,
      );
      rethrow;
    }
  }

  // 私有辅助方法
  void _updateTrackAndContext(Child file, Work work) {
    AppLogger.debug(LogStrings.logUpdateTrackAndContextFileFile5842(file.title));
    _stateManager.updateTrackAndContext(file, work);
  }
} 