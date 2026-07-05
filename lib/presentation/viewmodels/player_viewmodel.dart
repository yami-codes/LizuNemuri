import 'package:xuro/core/audio/events/playback_event.dart';
import 'package:xuro/core/audio/models/audio_track_info.dart';
import 'package:xuro/core/audio/models/playback_context.dart';
import 'package:xuro/core/subtitle/i_subtitle_service.dart';
import 'package:xuro/common/constants/strings.dart';
import 'package:flutter/foundation.dart';
import 'package:xuro/core/audio/i_audio_player_service.dart';
import 'package:xuro/core/audio/models/subtitle.dart';
import 'dart:async';
import 'package:xuro/core/subtitle/subtitle_loader.dart';
import 'package:xuro/core/download/download_service.dart';
import 'package:xuro/core/audio/events/playback_event_hub.dart';
import 'package:just_audio/just_audio.dart';
import 'package:get_it/get_it.dart';
import 'package:xuro/core/llm/subtitle_translation_service.dart';
import 'package:xuro/core/settings/app_settings_service.dart';
import 'package:xuro/core/subtitle/subtitle_import_service.dart';
import 'package:rxdart/rxdart.dart';
import 'package:xuro/utils/logger.dart';
import 'package:xuro/common/constants/log_strings.dart';

class PlayerViewModel extends ChangeNotifier {
  final IAudioPlayerService _audioService;
  final PlaybackEventHub _eventHub;
  final ISubtitleService _subtitleService;
  final _subtitleLoader = GetIt.I<SubtitleLoader>();
  final _importService = GetIt.I<SubtitleImportService>();
  final _downloadService = GetIt.I<DownloadService>();
  final _translationService = GetIt.I<SubtitleTranslationService>();
  final _settings = GetIt.I<AppSettingsService>();

  bool _isPlaying = false;
  bool _isBuffering = false;
  bool _isToggling = false;
  String? _errorMessage;
  bool _isUserImportedSubtitle = false;
  bool _isLlmTranslated = false;
  bool _isTranslating = false;
  String? _translationFeedback;
  SubtitleList? _subtitleSourceList;
  int _loadVersion = 0;
  Duration? _position;
  Duration? _duration;
  Subtitle? _currentSubtitle;

  final List<StreamSubscription> _subscriptions = [];

  static const _tag = 'PlayerViewModel';

  PlayerViewModel({
    required IAudioPlayerService audioService,
    required PlaybackEventHub eventHub,
    required ISubtitleService subtitleService,
  }) : _audioService = audioService,
       _eventHub = eventHub,
       _subtitleService = subtitleService {
    _settings.addListener(_onLlmSettingsChanged);
    _initStreams();
    _requestInitialState();
  }

  bool get isLlmTranslated => _isLlmTranslated;
  bool get isTranslating => _isTranslating;
  bool get hasSubtitles =>
      _subtitleService.subtitleList != null &&
      _subtitleService.subtitleList!.subtitles.isNotEmpty;

  /// One-shot snackbar message for auto-translate failures (consumed by UI).
  String? takeTranslationFeedback() {
    final message = _translationFeedback;
    _translationFeedback = null;
    return message;
  }

  void _onLlmSettingsChanged() {
    if (!_settings.llmTranslationEnabled || _isLlmTranslated || _isTranslating) {
      return;
    }
    final source = _subtitleSourceList ?? _subtitleService.subtitleList;
    final context = currentContext;
    if (source == null || context == null || source.subtitles.isEmpty) return;
    unawaited(() async {
      final err = await _runTranslation(
        source: source,
        context: context,
        auto: true,
      );
      if (err != null) {
        _translationFeedback = err;
        notifyListeners();
      }
    }());
  }

  void _initStreams() {
    // 播放状态事件 - 状态变化时通知（播放/暂停/缓冲等）
    _subscriptions.add(
      _eventHub.playbackState.listen(
        (event) {
          _isPlaying = event.state.playing;
          _position = event.position;  // fallback position for pause/resume
          _duration = event.duration;
          _isBuffering = event.state.processingState == ProcessingState.buffering ||
                         event.state.processingState == ProcessingState.loading;
          notifyListeners();
        },
        onError: (error) => debugPrint(LogStrings.logTagPlayerStateStreamErrorb3257(_tag, error)),
      ),
    );

    // 音轨变更事件
    _subscriptions.add(
      _eventHub.trackChange.listen(
        (event) {
          notifyListeners();
        },
        onError: (error) => debugPrint(LogStrings.logTagTrackChangeStreamErrorce29a(_tag, error)),
      ),
    );

    // 播放进度 - UI更新路径：节流到200ms，减少rebuild频率
    _subscriptions.add(
      _eventHub.playbackProgress
          .throttleTime(const Duration(milliseconds: 200))
          .listen(
        (event) {
          _position = event.position;
          notifyListeners();
        },
        onError: (error) => debugPrint(LogStrings.logTagProgressStreamErrorErro5613a(_tag, error)),
      ),
    );

    // 播放进度 - 字幕同步路径：保持全精度，不触发rebuild
    _subscriptions.add(
      _eventHub.playbackProgress.listen(
        (event) {
          _subtitleService.updatePosition(event.position);
        },
        onError: (error) => debugPrint(LogStrings.logTagSubtitleSyncStreamError0bca2(_tag, error)),
      ),
    );

    // 上下文变更事件
    _subscriptions.add(
      _eventHub.contextChange.listen(
        (event) async {
          await _loadSubtitleIfAvailable(event.context);
          if (_position != null) {
            _subtitleService.updatePosition(_position!);
          }
        },
        onError: (error) => debugPrint(LogStrings.logTagContextStreamErrorErrora0756(_tag, error)),
      ),
    );

    // 初始状态流
    _subscriptions.add(
      _eventHub.initialState.listen(
        (event) {
          if (event.track != null) {
            notifyListeners();
          }
          if (event.context != null) {
            _loadSubtitleIfAvailable(event.context!);
          }
        },
        onError: (error) => debugPrint(LogStrings.logTagInitialStateStreamError36ea4(_tag, error)),
      ),
    );

    // 错误事件
    _subscriptions.add(
      _eventHub.errors.listen(
        (event) {
          _errorMessage = Strings.playbackError(event.operation);
          AppLogger.error(LogStrings.logPlaybackErrorEventEventOpera07a4d(event.operation), event.error, event.stackTrace);
          notifyListeners();
        },
        onError: (error) => debugPrint(LogStrings.logTagErrorEventStreamErrorE48848(_tag, error)),
      ),
    );

    // 清空状态事件
    _subscriptions.add(
      _eventHub.playbackCleared.listen(
        (_) {
          _isPlaying = false;
          _isBuffering = false;
          _position = null;
          _duration = null;
          _isUserImportedSubtitle = false;
          _subtitleService.clearSubtitle();
          notifyListeners();
        },
        onError: (error) => debugPrint(LogStrings.logTagClearedStateStreamError92747(_tag, error)),
      ),
    );

    // 播放完成事件
    _subscriptions.add(
      _eventHub.playbackCompleted.listen(
        (event) {
          _isPlaying = false;
          notifyListeners();
        },
        onError: (error) => debugPrint(LogStrings.logTagCompletedStreamErrorErr77a4c(_tag, error)),
      ),
    );

    _initSubtitleStreams();
  }

  void _initSubtitleStreams() {
    _subscriptions.add(
      _subtitleService.subtitleStream.listen(
        (subtitleList) {
          debugPrint('$_tag - ${LogStrings.logSubtitleListUpdated(subtitleList != null ? LogStrings.logLoaded : LogStrings.logNotLoaded)}');
        },
        onError: (error) => debugPrint(LogStrings.logTagSubtitleStreamErrorErro296b9(_tag, error)),
      ),
    );

    _subscriptions.add(
      _subtitleService.currentSubtitleStream.listen(
        (subtitle) {
          _currentSubtitle = subtitle;
          notifyListeners();
        },
        onError: (error) => debugPrint(LogStrings.logTagCurrentSubtitleStreamErro2fef4(_tag, error)),
      ),
    );
  }

  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  String? get errorMessage => _errorMessage;
  bool get isUserImportedSubtitle => _isUserImportedSubtitle;
  Duration? get position => _position;
  Duration? get duration => _duration;
  Subtitle? get currentSubtitle => _currentSubtitle;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> playPause() async {
    if (_isToggling) return;
    _isToggling = true;
    try {
      if (_isPlaying) {
        await _audioService.pause();
      } else {
        // just_audio's play() Future only completes when playback later
        // pauses/stops, so awaiting resume() here would pin _isToggling and
        // make the next pause tap a no-op. Fire it; playbackState events
        // drive the UI. resume()/play() has no internal error wrapper, so
        // route failures to the existing PlaybackErrorEvent path.
        unawaited(_audioService.resume().catchError((Object e, StackTrace st) {
          _eventHub.emit(PlaybackErrorEvent('resume', e, st));
        }));
      }
    } finally {
      _isToggling = false;
    }
  }

  Future<void> seek(Duration position) async {
    await _audioService.seek(position);
  }

  Future<void> previous() async {
    await _audioService.previous();
  }

  Future<void> next() async {
    await _audioService.next();
  }

  Future<void> stop() async {
    await _audioService.stop();
  }

  @override
  void dispose() {
    _settings.removeListener(_onLlmSettingsChanged);
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    super.dispose();
  }

  // 请求初始状态
  void _requestInitialState() {
    Future.microtask(() {
      _eventHub.emit(RequestInitialStateEvent());
    });
  }

  Future<void> _presentSubtitleList(
    SubtitleList list,
    PlaybackContext context, {
    required int version,
  }) async {
    _subtitleSourceList = list;
    _isLlmTranslated = false;

    if (_settings.llmTranslationEnabled) {
      final err = await _runTranslation(
        source: list,
        context: context,
        auto: true,
        version: version,
      );
      if (_loadVersion != version) return;
      if (err != null) {
        _translationFeedback = err;
        notifyListeners();
      }
      return;
    }

    if (_loadVersion != version) return;
    await _subtitleService.loadSubtitleFromContent(list);
    notifyListeners();
  }

  Future<String?> translateSubtitlesNow({bool forceRefresh = false}) async {
    final context = currentContext;
    final source = _subtitleSourceList ?? _subtitleService.subtitleList;
    if (context == null || source == null || source.subtitles.isEmpty) {
      return Strings.llmErrorNoSubtitles;
    }
    return _runTranslation(
      source: source,
      context: context,
      auto: false,
      forceRefresh: forceRefresh,
    );
  }

  Future<String?> restoreOriginalSubtitles() async {
    final source = _subtitleSourceList;
    if (source == null) return Strings.llmErrorNoSubtitles;
    await _subtitleService.loadSubtitleFromContent(source);
    _isLlmTranslated = false;
    notifyListeners();
    return null;
  }

  Future<String?> _runTranslation({
    required SubtitleList source,
    required PlaybackContext context,
    required bool auto,
    int? version,
    bool forceRefresh = false,
  }) async {
    _isTranslating = true;
    notifyListeners();

    final result = auto
        ? await _translationService.translateIfEnabled(
            source: source,
            context: context,
          )
        : await _translationService.translateNow(
            source: source,
            context: context,
            forceRefresh: forceRefresh,
          );

    _isTranslating = false;
    if (version != null && _loadVersion != version) return null;

    if (result.isFailure) {
      await _subtitleService.loadSubtitleFromContent(source);
      _isLlmTranslated = false;
      notifyListeners();
      return result.error!.userMessage;
    }

    await _subtitleService.loadSubtitleFromContent(result.list);
    _isLlmTranslated = result.translated;
    notifyListeners();

    if (!auto && result.translated) {
      return null;
    }
    if (!auto && !result.translated && !result.skipped) {
      return Strings.llmTranslationNoChange;
    }
    return null;
  }

  Future<void> _loadSubtitleIfAvailable(PlaybackContext context) async {
    final version = ++_loadVersion;
    final workId = context.work.id?.toString();
    final fileName = context.currentFile.title;

    // 1. 用户导入优先
    if (workId != null && fileName != null) {
      final entry = await _importService.findImported(workId, fileName);
      if (_loadVersion != version) return;
      if (entry != null) {
        final subtitleList = await _importService.loadLocalSubtitle(entry.subtitlePath);
        if (_loadVersion != version) return;
        if (subtitleList != null) {
          await _presentSubtitleList(subtitleList, context, version: version);
          if (_loadVersion != version) return;
          _isUserImportedSubtitle = true;
          notifyListeners();
          return;
        }
        // Local file missing/corrupted → remove invalid association
        await _importService.removeImportedSubtitle(workId, fileName);
        if (_loadVersion != version) return;
      }
    }

    // 2. 自动匹配。优先级：已下载本地字幕（离线可用）> 在线 URL。
    _isUserImportedSubtitle = false;
    final subtitleFile = _subtitleLoader.findSubtitleFile(
      context.currentFile,
      context.files,
    );
    if (subtitleFile == null) {
      _subtitleService.clearSubtitle();
      AppLogger.debug(LogStrings.logSubtitleNotFoundClearing);
      return;
    }

    // 2a. 该字幕已随音频下载到本地 → 读本地文件，断网也能显示。
    if (workId != null) {
      final localPath =
          await _downloadService.localPathIfDownloaded(workId, subtitleFile);
      if (_loadVersion != version) return;
      if (localPath != null) {
        final list = await _importService.loadLocalSubtitle(localPath);
        if (_loadVersion != version) return;
        if (list != null) {
          await _presentSubtitleList(list, context, version: version);
          AppLogger.debug(LogStrings.logUsingDownloadedLocalSubtitlef5b14(localPath));
          return;
        }
      }
    }

    // 2b. 在线 URL（需网络）。
    if (subtitleFile.mediaDownloadUrl != null) {
      final list =
          await _subtitleLoader.loadSubtitleContent(subtitleFile.mediaDownloadUrl!);
      if (_loadVersion != version) return;
      if (list != null) {
        await _presentSubtitleList(list, context, version: version);
      } else {
        _subtitleService.clearSubtitle();
      }
    } else {
      _subtitleService.clearSubtitle();
      AppLogger.debug(LogStrings.logSubtitleUrlUnavailableCleari4443f);
    }
  }

  /// Import a subtitle file for the current audio.
  Future<ImportResult> importSubtitle() async {
    final context = currentContext;
    if (context == null) return ImportResult.cancelled;

    final workId = context.work.id?.toString();
    final fileName = context.currentFile.title;
    if (workId == null || fileName == null) return ImportResult.cancelled;

    final response = await _importService.importSubtitle(workId, fileName);
    if (response.result == ImportResult.success && response.subtitleList != null) {
      // Verify we're still on the same track
      final currentWorkId = currentContext?.work.id?.toString();
      final currentFileName = currentContext?.currentFile.title;
      if (currentWorkId == workId && currentFileName == fileName) {
        final ctx = currentContext;
        if (ctx != null) {
          await _presentSubtitleList(
            response.subtitleList!,
            ctx,
            version: _loadVersion,
          );
        } else {
          await _subtitleService.loadSubtitleFromContent(response.subtitleList!);
        }
        _isUserImportedSubtitle = true;
        notifyListeners();
      }
    }
    return response.result;
  }

  /// Remove imported subtitle and fall back to auto-match.
  Future<void> removeImportedSubtitle() async {
    final context = currentContext;
    if (context == null) return;

    final workId = context.work.id?.toString();
    final fileName = context.currentFile.title;
    if (workId == null || fileName == null) return;

    await _importService.removeImportedSubtitle(workId, fileName);
    _isUserImportedSubtitle = false;
    await _loadSubtitleIfAvailable(context);
  }

  AudioTrackInfo? get currentTrackInfo => _audioService.currentTrack;
  PlaybackContext? get currentContext => _audioService.currentContext;

  Future<void> seekToNextLyric() async {
    final currentSubtitle = _subtitleService.currentSubtitleWithState;
    final subtitleList = _subtitleService.subtitleList;
    
    if (currentSubtitle != null && subtitleList != null) {
      final nextSubtitle = currentSubtitle.subtitle.getNext(subtitleList);
      if (nextSubtitle != null) {
        await seek(nextSubtitle.start);
      }
    }
  }

  Future<void> seekToPreviousLyric() async {
    final currentSubtitle = _subtitleService.currentSubtitleWithState;
    final subtitleList = _subtitleService.subtitleList;
    
    if (currentSubtitle != null && subtitleList != null) {
      final previousSubtitle = currentSubtitle.subtitle.getPrevious(subtitleList);
      if (previousSubtitle != null) {
        await seek(previousSubtitle.start);
      }
    }
  }
}
