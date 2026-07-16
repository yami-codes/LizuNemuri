import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/data/models/playlists_with_exist_statu/pagination.dart';
import 'package:lizunemu/data/models/playlists_with_exist_statu/playlist.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter/material.dart';
import 'package:lizunemu/data/models/files/files.dart';
import 'package:lizunemu/data/models/files/child.dart';
import 'package:lizunemu/data/models/works/work.dart';
import 'package:lizunemu/data/services/api_service.dart';
import 'package:lizunemu/core/audio/i_audio_player_service.dart';
import 'package:lizunemu/core/download/download_service.dart';
import 'package:lizunemu/utils/mark_status_strings.dart';
import 'package:lizunemu/utils/user_facing_error.dart';
import 'package:lizunemu/core/logging/app_log_tags.dart';
import 'package:lizunemu/utils/logger.dart';
import 'package:lizunemu/core/audio/models/playback_context.dart';
import 'package:lizunemu/widgets/detail/playlist_selection_dialog.dart';
import 'package:lizunemu/data/models/mark_status.dart';
import 'package:lizunemu/widgets/detail/mark_selection_dialog.dart';
import 'package:lizunemu/data/models/works/work_info.dart';
import 'package:lizunemu/widgets/detail/work_folder_item.dart';
import 'package:lizunemu/core/audio/models/file_path.dart';
import 'package:lizunemu/core/subtitle/utils/subtitle_matcher.dart';
import 'package:lizunemu/utils/image_file_extensions.dart';
import 'package:lizunemu/core/llm/subtitle_translation_service.dart';
import 'package:lizunemu/core/llm/subtitle_translation_progress.dart';
import 'package:lizunemu/core/llm/work_title_translation_service.dart';
import 'package:lizunemu/core/settings/app_settings_service.dart';
import 'package:lizunemu/core/settings/metadata_translation_mode.dart';
import 'package:lizunemu/core/translation/metadata_translation_service.dart';
import 'package:lizunemu/core/subtitle/subtitle_loader.dart';
import 'package:lizunemu/core/media/work_media_url_refresher.dart';
import 'package:lizunemu/core/subtitle/subtitle_import_service.dart';
import 'package:lizunemu/core/audio/models/subtitle.dart';
import 'package:lizunemu/data/services/exceptions/llm_translation_exception.dart';
import 'package:dio/dio.dart';
import 'package:lizunemu/common/constants/log_strings.dart';

/// One batch download item: audio + matched subtitle in the same directory (optional).
typedef DownloadPair = ({Child audio, Child? subtitle});

/// Aggregated batch download outcome.
class BatchDownloadOutcome {
  final int ok;
  final int skipped;
  final int failed;
  final bool cancelled;
  const BatchDownloadOutcome({
    required this.ok,
    required this.skipped,
    required this.failed,
    required this.cancelled,
  });
}

/// One checklist row for bulk LLM translate on a work.
class TranslateSelectionItem {
  final DownloadPair pair;
  final String title;
  final bool isCached;

  const TranslateSelectionItem({
    required this.pair,
    required this.title,
    required this.isCached,
  });
}

/// Bulk LLM subtitle translation result.
class BatchTranslateOutcome {
  final int translated;
  final int cached;
  final int failed;
  final bool cancelled;

  const BatchTranslateOutcome({
    required this.translated,
    required this.cached,
    required this.failed,
    required this.cancelled,
  });
}

class DetailViewModel extends ChangeNotifier {
  late final ApiService _apiService;
  late final IAudioPlayerService _audioService;
  late final DownloadService _downloadService;
  late final SubtitleTranslationService _translationService;
  late final WorkTitleTranslationService _titleTranslationService;
  late final MetadataTranslationService _metadataTranslationService;
  late final AppSettingsService _appSettings;
  late final SubtitleLoader _subtitleLoader;
  late final SubtitleImportService _importService;
  late final WorkMediaUrlRefresher _mediaUrlRefresher;
  final Work work;

  static const _videoExtensions = {'mp4', 'mkv', 'mov', 'avi', 'webm', 'm4v'};

  Files? _files;
  bool _isLoading = false;
  String? _error;
  bool _disposed = false;

  WorkInfo? _workInfo;
  bool _isLoadingInfo = false;

  bool _hasRecommendations = false;
  bool _checkingRecommendations = false;

  // Playlist / favorites state
  bool _loadingPlaylists = false;
  String? _playlistsError;
  List<Playlist>? _playlists;
  Pagination? _playlistsPagination;

  bool _loadingFavorite = false;
  bool get loadingFavorite => _loadingFavorite;

  MarkStatus? _currentMarkStatus;
  MarkStatus? get currentMarkStatus => _currentMarkStatus;

  String? _translatedTitle;
  bool _isTitleTranslating = false;
  bool _showOriginalTitle = false;

  final Map<String, String> _translatedTrackNames = {};
  bool _isTranslatingTracks = false;
  bool _showOriginalTrackNames = false;

  String get displayTitle =>
      (!_showOriginalTitle && _translatedTitle != null)
          ? _translatedTitle!
          : (work.title ?? '');

  bool get isTitleTranslated =>
      _translatedTitle != null && !_showOriginalTitle;

  bool get isTitleTranslating => _isTitleTranslating;

  bool get canRestoreOriginalTitle =>
      _translatedTitle != null && !_showOriginalTitle;

  bool get canShowTranslatedTitle =>
      _translatedTitle != null && _showOriginalTitle;

  bool get isTranslatingTracks => _isTranslatingTracks;

  bool get hasTranslatedTrackNames =>
      _translatedTrackNames.isNotEmpty && !_showOriginalTrackNames;

  String displayTrackTitle(Child file) {
    if (_showOriginalTrackNames) return file.title ?? '';
    final key = _labelKey(file);
    return _translatedTrackNames[key] ?? file.title ?? '';
  }

  /// Resolves translated label for any tree node (folder or leaf).
  String displayTreeTitle(Child node, {String pathPrefix = ''}) {
    if (_showOriginalTrackNames) return node.title ?? '';
    if (node.type == 'folder') {
      final key = _folderLabelKey(node, pathPrefix: pathPrefix);
      return _translatedTrackNames[key] ?? node.title ?? '';
    }
    return _translatedTrackNames[_labelKey(node)] ?? node.title ?? '';
  }

  void showOriginalTrackNames() {
    _showOriginalTrackNames = true;
    notifyListeners();
  }

  void showTranslatedTrackNames() {
    if (_translatedTrackNames.isEmpty) return;
    _showOriginalTrackNames = false;
    notifyListeners();
  }

  bool _loadingMark = false;
  bool get loadingMark => _loadingMark;

  // Cancellation flag
  final _cancelToken = CancelToken();

  DetailViewModel({
    required this.work,
  }) {
    _audioService = GetIt.I<IAudioPlayerService>();
    _apiService = GetIt.I<ApiService>();
    _downloadService = GetIt.I<DownloadService>();
    _translationService = GetIt.I<SubtitleTranslationService>();
    _titleTranslationService = GetIt.I<WorkTitleTranslationService>();
    _metadataTranslationService = GetIt.I<MetadataTranslationService>();
    _appSettings = GetIt.I<AppSettingsService>();
    _subtitleLoader = GetIt.I<SubtitleLoader>();
    _importService = GetIt.I<SubtitleImportService>();
    _mediaUrlRefresher = GetIt.I<WorkMediaUrlRefresher>();
    _checkRecommendations();
  }

  Files? get files => _files;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasRecommendations => _hasRecommendations;
  bool get checkingRecommendations => _checkingRecommendations;
  WorkInfo? get workInfo => _workInfo;
  bool get isLoadingInfo => _isLoadingInfo;

  // Playlist / favorites getters
  bool get loadingPlaylists => _loadingPlaylists;
  String? get playlistsError => _playlistsError;
  List<Playlist>? get playlists => _playlists;
  int? get playlistsTotalPages => 
      _playlistsPagination?.totalCount != null && _playlistsPagination?.pageSize != null
          ? (_playlistsPagination!.totalCount! / _playlistsPagination!.pageSize!).ceil()
          : null;

  Future<void> _checkRecommendations() async {
    _checkingRecommendations = true;
    notifyListeners();

    try {
      final response = await _apiService.getItemNeighbors(
        itemId: work.id.toString(),
        page: 1,
      );
      _hasRecommendations = (response.pagination.totalCount ?? 0) > 0;
    } catch (e) {
      AppLogger.error(LogStrings.logCheckSimilarFailed, e);
      _hasRecommendations = false;
    } finally {
      if (!_disposed) {
        _checkingRecommendations = false;
        notifyListeners();
      }
    }
  }

  /// Batch-load files and work info with minimal notifyListeners calls.
  /// Called once from the screen instead of separate loadFiles + loadWorkInfo.
  Future<void> loadInitialData() async {
    _isLoading = true;
    _isLoadingInfo = true;
    _error = null;
    notifyListeners(); // Single notify for "loading started"

    // Run both fetches concurrently
    await Future.wait([
      _loadFilesInternal(),
      _loadWorkInfoInternal(),
      _loadCachedTitle(),
    ]);

    if (!_disposed) {
      notifyListeners(); // Single notify for "loading complete"
    }
    await _maybeAutoTranslateWorkTitle();
    await _maybeAutoTranslateTrackNames();
  }

  Future<void> _loadFilesInternal() async {
    try {
      AppLogger.info(LogStrings.logStartLoadingWorkFilesWorkId5bb3d(work.id));
      _files = await _apiService.getWorkFiles(
        work.id.toString(),
        cancelToken: _cancelToken,
      );
      WorkFolderItem.resetExpandState(); // Reset on new data load, not on every build
      AppLogger.info(LogStrings.logFilesLoadedWorkId92bd2(work.id));
    } catch (e) {
      if (e is! DioException || e.type != DioExceptionType.cancel) {
        AppLogger.info(LogStrings.logLoadFilesFailed);
        _error = userFacingError(e);
      }
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _loadWorkInfoInternal() async {
    try {
      final workId = _extractNumericId(work.sourceId) ?? work.id.toString();
      _workInfo = await _apiService.getWorkInfo(workId, cancelToken: _cancelToken);
      AppLogger.info(LogStrings.logWorkDetailLoadedWorkId3f489(work.id));
    } catch (e) {
      if (e is! DioException || e.type != DioExceptionType.cancel) {
        AppLogger.error(LogStrings.logLoadWorkDetailFailed, e);
      }
    } finally {
      _isLoadingInfo = false;
    }
  }

  Future<void> loadWorkInfo() async {
    if (_isLoadingInfo) return;
    _isLoadingInfo = true;
    notifyListeners();
    await _loadWorkInfoInternal();
    if (!_disposed) notifyListeners();
  }

  Future<void> loadFiles() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    await _loadFilesInternal();
    if (!_disposed) notifyListeners();
  }

  /// Known video extension check — **more reliable than API `type`** (mislabeled videos).
  static bool _hasVideoExtension(String? title) {
    final ext = title?.split('.').last.toLowerCase();
    return ext != null && _videoExtensions.contains(ext);
  }

  /// Whether file is video (`type==video` or video extension) — download + external player.
  bool isVideoFile(Child file) =>
      (file.type ?? '').toLowerCase() == 'video' ||
      _hasVideoExtension(file.title);

  /// Static: audio and not a video extension (extension wins over API `type`).
  static bool _isAudioChild(Child c) =>
      (c.type ?? '').toLowerCase() == 'audio' &&
      !_hasVideoExtension(c.title);

  bool isAudioFile(Child file) => _isAudioChild(file);

  static const _subtitleExtensions = {'vtt', 'lrc', 'srt', 'txt'};

  /// Whether file is a previewable subtitle (.vtt/.lrc/.srt/.txt).
  bool isSubtitleFile(Child file) {
    final ext = file.title?.split('.').last.toLowerCase();
    return ext != null && _subtitleExtensions.contains(ext);
  }

  /// Raster image preview (.jpg/.png/.webp/…) or API `type: image`.
  static bool isPreviewableImageFile(Child file) {
    if ((file.type ?? '').toLowerCase() == 'image') {
      return true;
    }
    return ImageFileExtensions.hasPreviewableExtension(file.title);
  }

  bool isImageFile(Child file) => isPreviewableImageFile(file);

  /// Matched sibling subtitle for a media file (audio or video).
  static Child? matchingSubtitleFor(Child file, Files? files) {
    if (files == null || file.title == null) return null;
    final siblings = FilePath.getSiblings(file, files);
    return SubtitleMatcher.findMatchingSubtitle(file.title!, siblings);
  }

  Child? subtitleForFile(Child file) => matchingSubtitleFor(file, _files);

  /// Pure: collect audio under subtree and pair subtitles from same-directory siblings.
  static List<DownloadPair> collectAudioWithSubtitles(List<Child>? children) {
    final out = <DownloadPair>[];
    if (children == null) return out;
    for (final c in children) {
      if ((c.type ?? '').toLowerCase() == 'folder') {
        out.addAll(collectAudioWithSubtitles(c.children));
      } else if (_isAudioChild(c)) {
        final sub = c.title != null
            ? SubtitleMatcher.findMatchingSubtitle(c.title!, children)
            : null;
        out.add((audio: c, subtitle: sub));
      }
    }
    return out;
  }

  List<Child>? _nodeChildren(Child? folder) =>
      folder == null ? _files?.children : folder.children;

  /// Count of downloadable audio under node (null = whole work).
  int batchAudioCount(Child? folder) =>
      collectAudioWithSubtitles(_nodeChildren(folder)).length;

  /// Single audio download + best-effort matched subtitle. UI owns confirm/progress dialogs.
  Future<DownloadResult> downloadFile(
    Child file, {
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final result = await _downloadService.download(
      workId: work.id.toString(),
      file: file,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
    if (result.isPlayable &&
        isAudioFile(file) &&
        !(cancelToken?.isCancelled ?? false)) {
      final sub = _matchedSubtitle(file);
      if (sub != null) {
        try {
          await _downloadService.download(
            workId: work.id.toString(),
            file: sub,
            cancelToken: cancelToken,
          );
        } catch (e) {
          AppLogger.warning(LogStrings.logPairedSubtitleDownloadFailedd44d7(e));
        }
      }
    }
    return result;
  }

  Child? _matchedSubtitle(Child audio) {
    if (_files == null || audio.title == null) return null;
    final siblings = FilePath.getSiblings(audio, _files!);
    return SubtitleMatcher.findMatchingSubtitle(audio.title!, siblings);
  }

  /// Sequential batch download of audio + subtitles under [folder] (null = whole work).
  Future<BatchDownloadOutcome> downloadFolder({
    Child? folder,
    required void Function(int index, int total, String name, double progress)
        onProgress,
    CancelToken? cancelToken,
  }) async {
    final items = collectAudioWithSubtitles(_nodeChildren(folder));
    var ok = 0, skipped = 0, failed = 0;
    var cancelled = false;
    for (var i = 0; i < items.length; i++) {
      if (cancelToken?.isCancelled ?? false) {
        cancelled = true;
        break;
      }
      final audio = items[i].audio;
      final sub = items[i].subtitle;
      final name = audio.title ?? '';
      onProgress(i + 1, items.length, name, 0);
      final r = await _downloadService.download(
        workId: work.id.toString(),
        file: audio,
        cancelToken: cancelToken,
        onProgress: (p) => onProgress(i + 1, items.length, name, p),
      );
      switch (r.status) {
        case DownloadStatus.success:
          ok++;
        case DownloadStatus.alreadyExists:
          skipped++;
        case DownloadStatus.cancelled:
          cancelled = true;
        case DownloadStatus.networkError:
        case DownloadStatus.ioError:
          failed++;
      }
      if (cancelled) break;
      if (sub != null && !(cancelToken?.isCancelled ?? false)) {
        try {
          final sr = await _downloadService.download(
            workId: work.id.toString(),
            file: sub,
            cancelToken: cancelToken,
          );
          // Subtitle cancel must mark whole batch cancelled (last item subtitle phase).
          if (sr.status == DownloadStatus.cancelled) {
            cancelled = true;
            break;
          }
          // Subtitle network/IO failure is best-effort — log only, not failed.
        } catch (e) {
          AppLogger.warning(LogStrings.logPairedSubtitleDownloadFailedd44d7(e));
        }
      }
      // Tail cancel check after last item (no loop head check).
      if (cancelToken?.isCancelled ?? false) {
        cancelled = true;
        break;
      }
    }
    return BatchDownloadOutcome(
      ok: ok,
      skipped: skipped,
      failed: failed,
      cancelled: cancelled,
    );
  }

  Future<void> _loadCachedTitle() async {
    final source = work.title?.trim();
    final workId = work.id?.toString();
    if (source == null || source.isEmpty || workId == null) return;
    final cached = await _titleTranslationService.cachedTitle(
      workId: workId,
      sourceTitle: source,
    );
    if (_disposed) return;
    if (cached != null) {
      _translatedTitle = cached;
      notifyListeners();
    }
  }

  Future<String?> translateWorkTitle({bool forceRefresh = false}) async {
    final source = work.title?.trim();
    final workId = work.id?.toString();
    if (source == null || source.isEmpty) return Strings.llmErrorNoTitle;
    if (workId == null) return Strings.llmErrorNoTitle;

    _isTitleTranslating = true;
    _showOriginalTitle = false;
    notifyListeners();

    final result = await _titleTranslationService.translate(
      workId: workId,
      sourceTitle: source,
      forceRefresh: forceRefresh,
      onPartial: (_, text) {
        _translatedTitle = text;
        notifyListeners();
      },
    );

    _isTitleTranslating = false;
    if (result.isFailure) {
      notifyListeners();
      return result.error!.userMessage;
    }

    _translatedTitle = result.title;
    notifyListeners();
    return result.fromCache ? Strings.llmTitleFromCache : null;
  }

  void showOriginalTitle() {
    _showOriginalTitle = true;
    notifyListeners();
  }

  void showTranslatedTitle() {
    if (_translatedTitle == null) return;
    _showOriginalTitle = false;
    notifyListeners();
  }

  Future<bool> isWorkTitleCached() async {
    final source = work.title?.trim();
    final workId = work.id?.toString();
    if (source == null || source.isEmpty || workId == null) return false;
    return _titleTranslationService.isCached(
      workId: workId,
      sourceTitle: source,
    );
  }

  Future<void> _maybeAutoTranslateWorkTitle() async {
    if (!_appSettings.metadataTranslationEnabled) return;
    if (_appSettings.metadataTranslationMode != MetadataTranslationMode.auto) {
      return;
    }
    await translateWorkTitle();
  }

  Future<Child> _freshFile(Child file) async {
    final workId = work.id?.toString();
    if (workId == null) return file;
    return _mediaUrlRefresher.refreshFile(
      workId: workId,
      file: file,
      patchInto: _files,
      onTreePatched: (patched) {
        _files = patched;
        notifyListeners();
      },
    );
  }

  Future<String?> translateTrackNames({bool force = false}) async {
    final workId = work.id?.toString();
    if (workId == null || _files == null) {
      return Strings.metadataTrackTranslationFailed;
    }

    final titles = _collectTreeLabels(_files!.children);
    if (titles.isEmpty) return Strings.metadataTrackTranslationFailed;

    _isTranslatingTracks = true;
    _showOriginalTrackNames = false;
    notifyListeners();

    try {
      await _metadataTranslationService.translateTrackNames(
        workId: workId,
        fileKeyToTitle: titles,
        force: force,
        onPartial: (fileKey, text) {
          _translatedTrackNames[fileKey] = text;
          notifyListeners();
        },
      );
      return _translatedTrackNames.isEmpty
          ? Strings.metadataTrackTranslationFailed
          : null;
    } on LlmTranslationException catch (e) {
      AppLogger.warning(
        'Track name LLM translation failed: ${e.message}',
        error: e,
        tag: AppLogTags.translation,
      );
      if (_translatedTrackNames.isNotEmpty) return null;
      return e.userMessage;
    } catch (e) {
      AppLogger.warning(
        'Track name translation failed: $e',
        error: e,
        tag: AppLogTags.translation,
      );
      if (_translatedTrackNames.isNotEmpty) return null;
      return Strings.metadataTrackTranslationFailed;
    } finally {
      _isTranslatingTracks = false;
      notifyListeners();
    }
  }

  Future<void> _maybeAutoTranslateTrackNames() async {
    if (!_appSettings.metadataTranslationEnabled) return;
    if (_appSettings.metadataTranslationMode != MetadataTranslationMode.auto) {
      return;
    }
    await translateTrackNames();
  }

  static String _labelKey(Child file) => file.hash ?? file.title ?? '';

  static String _folderLabelKey(Child folder, {String pathPrefix = ''}) {
    final title = folder.title?.trim() ?? '';
    return 'folder:$pathPrefix/$title';
  }

  /// Folder names + all leaf file titles (audio/video/subtitle/etc.).
  Map<String, String> _collectTreeLabels(List<Child>? nodes) {
    final map = <String, String>{};
    void walk(List<Child>? children, String pathPrefix) {
      if (children == null) return;
      for (final node in children) {
        final title = node.title?.trim();
        if (title == null || title.isEmpty) continue;
        if (node.type == 'folder') {
          final key = _folderLabelKey(node, pathPrefix: pathPrefix);
          map[key] = title;
          walk(node.children, '$pathPrefix/$title');
        } else {
          final key = _labelKey(node);
          if (key.isNotEmpty) {
            map[key] = title;
          }
        }
      }
    }

    walk(nodes, '');
    return map;
  }

  /// Audio + matched subtitle pairs under [folder] (null = whole work).
  List<DownloadPair> translatablePairs(Child? folder) =>
      collectAudioWithSubtitles(_nodeChildren(folder))
          .where((p) => p.subtitle != null)
          .toList();

  int batchTranslateCount(Child? folder) => translatablePairs(folder).length;

  /// Cached translation file count saved for this work (all target langs).
  Future<int> cachedTranslationCount() =>
      _translationService.cachedCountForWork(work.id.toString());

  /// Build selection rows with per-track cache status (loads subtitle text).
  Future<List<TranslateSelectionItem>> prepareTranslateSelection(
    Child? folder,
  ) async {
    if (_files == null) return [];
    final pairs = translatablePairs(folder);
    final items = <TranslateSelectionItem>[];
    for (final pair in pairs) {
      final title = pair.audio.title ?? '';
      var isCached = false;
      final list = await _loadSubtitleListForPair(pair);
      if (list != null) {
        final ctx = PlaybackContext(
          work: work,
          files: _files!,
          currentFile: pair.audio,
        );
        isCached = await _translationService.isCached(
          source: list,
          context: ctx,
        );
      }
      items.add(TranslateSelectionItem(
        pair: pair,
        title: title,
        isCached: isCached,
      ));
    }
    return items;
  }

  /// Pre-translate selected audio+subtitle pairs; skips already-cached by default.
  Future<BatchTranslateOutcome> translatePairs({
    required List<DownloadPair> items,
    required BatchTranslateProgressCallback onProgress,
    CancelToken? cancelToken,
    bool skipCached = true,
    bool forceRefresh = false,
  }) async {
    if (_files == null) {
      return const BatchTranslateOutcome(
        translated: 0,
        cached: 0,
        failed: 0,
        cancelled: false,
      );
    }

    var translated = 0, cached = 0, failed = 0;
    var cancelled = false;

    for (var i = 0; i < items.length; i++) {
      if (cancelToken?.isCancelled ?? false) {
        cancelled = true;
        break;
      }

      final pair = items[i];
      final subtitle = pair.subtitle;
      if (subtitle == null) continue;

      final name = pair.audio.title ?? '';
      onProgress(BatchTranslateProgress(
        index: i + 1,
        total: items.length,
        trackName: name,
        phase: BatchTranslatePhase.loadingSubtitle,
      ));

      final list = await _loadSubtitleListForPair(pair);
      if (list == null) {
        failed++;
        onProgress(BatchTranslateProgress(
          index: i + 1,
          total: items.length,
          trackName: name,
          phase: BatchTranslatePhase.failed,
        ));
        continue;
      }

      final ctx = PlaybackContext(
        work: work,
        files: _files!,
        currentFile: pair.audio,
      );

      if (!forceRefresh && skipCached) {
        onProgress(BatchTranslateProgress(
          index: i + 1,
          total: items.length,
          trackName: name,
          phase: BatchTranslatePhase.checkingCache,
        ));
        if (await _translationService.isCached(source: list, context: ctx)) {
          cached++;
          onProgress(BatchTranslateProgress(
            index: i + 1,
            total: items.length,
            trackName: name,
            phase: BatchTranslatePhase.cached,
          ));
          continue;
        }
      }

      if (cancelToken?.isCancelled ?? false) {
        cancelled = true;
        break;
      }

      onProgress(BatchTranslateProgress(
        index: i + 1,
        total: items.length,
        trackName: name,
        phase: BatchTranslatePhase.translating,
      ));

      final result = await _translationService.translateNow(
        source: list,
        context: ctx,
        forceRefresh: forceRefresh,
        onProgress: (p) {
          if (p.phase == SubtitleTranslationPhase.translating) {
            onProgress(BatchTranslateProgress(
              index: i + 1,
              total: items.length,
              trackName: name,
              phase: BatchTranslatePhase.translating,
              llmBatchIndex: p.batchIndex,
              llmBatchTotal: p.batchTotal,
            ));
          }
        },
      );

      if (result.isFailure) {
        failed++;
        onProgress(BatchTranslateProgress(
          index: i + 1,
          total: items.length,
          trackName: name,
          phase: BatchTranslatePhase.failed,
        ));
      } else if (result.fromCache) {
        cached++;
        onProgress(BatchTranslateProgress(
          index: i + 1,
          total: items.length,
          trackName: name,
          phase: BatchTranslatePhase.cached,
        ));
      } else if (result.translated) {
        translated++;
      } else {
        cached++;
      }

      if (cancelToken?.isCancelled ?? false) {
        cancelled = true;
        break;
      }
    }

    return BatchTranslateOutcome(
      translated: translated,
      cached: cached,
      failed: failed,
      cancelled: cancelled,
    );
  }

  Future<SubtitleList?> _loadSubtitleListForPair(DownloadPair pair) async {
    final subtitle = pair.subtitle;
    if (subtitle == null || _files == null) return null;
    final workId = work.id?.toString();
    if (workId != null) {
      final localPath =
          await _downloadService.localPathIfDownloaded(workId, subtitle);
      if (localPath != null) {
        return _importService.loadLocalSubtitle(localPath);
      }
    }
    final url = subtitle.mediaDownloadUrl;
    if (url == null) return null;
    try {
      return await _subtitleLoader.loadSubtitleContent(url);
    } catch (e) {
      AppLogger.warning('Bulk translate subtitle load failed: $e');
      return null;
    }
  }

  Future<void> playFile(Child file, BuildContext context) async {
    // Unified classifier blocks mislabeled videos with a clear error, not empty playlist.
    if (!isAudioFile(file)) {
      throw UserFacingException(
        Strings.unsupportedVideoFile(file.title ?? ''),
      );
    }

    final resolved = await _freshFile(file);

    if (resolved.mediaDownloadUrl == null) {
      AppLogger.error(
        'Playback aborted: mediaDownloadUrl missing for ${resolved.title}',
        null,
        null,
        AppLogTags.playback,
      );
      throw UserFacingException(Strings.fileUrlMissing);
    }

    if (_files == null) {
      AppLogger.error(
        'Playback aborted: file list not loaded for work ${work.id}',
        null,
        null,
        AppLogTags.playback,
      );
      throw UserFacingException(Strings.fileListNotLoaded);
    }

    try {
      final playbackContext = PlaybackContext(
        work: work,
        files: _files!,
        currentFile: resolved,
      );

      AppLogger.info(
        'Starting playback: work=${work.id} file=${resolved.title} url=${resolved.mediaDownloadUrl}',
        tag: AppLogTags.playback,
      );
      await _audioService.playWithContext(playbackContext);
    } catch (e, st) {
      if (!_disposed) {
        AppLogger.error(
          LogStrings.logPlaybackFailed,
          e,
          st,
          AppLogTags.playback,
        );
      }
      rethrow;
    }
  }

  /// Load user playlists.
  Future<void> loadPlaylists({int page = 1}) async {
    if (_loadingPlaylists) return;

    _loadingPlaylists = true;
    _playlistsError = null;
    notifyListeners();

    try {
      final response = await _apiService.getWorkExistStatusInPlaylists(
        workId: work.id.toString(),
        page: page,
      );
      
      _playlists = response.playlists;
      _playlistsPagination = response.pagination;
      AppLogger.info(LogStrings.logWorkPlaylistsLoaded((_playlists?.length ?? 0).toString()));
    } catch (e) {
      AppLogger.error(LogStrings.logLoadWorkPlaylistsFailed, e);
      _playlistsError = userFacingError(e);
    } finally {
      _loadingPlaylists = false;
      notifyListeners();
    }
  }

  Future<void> showPlaylistsDialog(BuildContext context) async {
    _loadingFavorite = true;
    notifyListeners();
    
    try {
      await loadPlaylists();
      _loadingFavorite = false;
      notifyListeners();
      
      if (!context.mounted) return;
      
      await showDialog(
        context: context,
        builder: (context) => PlaylistSelectionDialog(
          playlists: playlists,
          isLoading: loadingPlaylists,
          error: playlistsError,
          onRetry: () => loadPlaylists(),
          onPlaylistTap: (playlist) async {
            try {
              await togglePlaylistWork(playlist);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(localizedOperationFailed(e))),
                );
              }
            }
          },
        ),
      );
    } catch (e) {
      _loadingFavorite = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> togglePlaylistWork(Playlist playlist) async {
    try {
      if (playlist.exist ?? false) {
        await _apiService.removeWorkFromPlaylist(
          playlistId: playlist.id!,
          workId: work.id.toString(),
        );
      } else {
        await _apiService.addWorkToPlaylist(
          playlistId: playlist.id!,
          workId: work.id.toString(),
        );
      }
      
      // Update local playlist state
      final index = _playlists?.indexWhere((p) => p.id == playlist.id);
      if (index != null && index != -1) {
        _playlists = List<Playlist>.from(_playlists!)
          ..[index] = playlist.copyWith(exist: !(playlist.exist ?? false));
        notifyListeners();
      }
      
      final action = (playlist.exist ?? false) ? LogStrings.logActionRemove : LogStrings.logActionAdd;
      AppLogger.info(LogStrings.logFavoriteUpdated(action, playlist.name ?? ''));
    } catch (e) {
      AppLogger.error(LogStrings.logToggleFavoriteFailed, e);
      rethrow;
    }
  }

  Future<void> updateMarkStatus(MarkStatus status) async {
    _loadingMark = true;
    notifyListeners();

    try {
      await _apiService.updateWorkMarkStatus(
        work.id.toString(),
        _apiService.convertMarkStatusToApi(status),
      );
      
      _currentMarkStatus = status;
      AppLogger.info(LogStrings.logMarkStatusUpdated(status.localizedLabel));
    } catch (e) {
      AppLogger.error(LogStrings.logUpdateMarkFailed, e);
      rethrow;
    } finally {
      _loadingMark = false;
      notifyListeners();
    }
  }

  void showMarkDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => MarkSelectionDialog(
        currentStatus: _currentMarkStatus,
        loading: _loadingMark,
        onMarkSelected: (status) async {
          try {
            await updateMarkStatus(status);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(Strings.markedAs(status.localizedLabel)),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(localizedMarkFailed(e))),
              );
            }
          }
        },
      ),
    );
  }

  String? _extractNumericId(String? sourceId) {
    if (sourceId == null) return null;
    final match = RegExp(r'\d+').firstMatch(sourceId);
    return match?.group(0);
  }

  @override
  void dispose() {
    // Cancel all in-flight requests
    _cancelToken.cancel('ViewModel disposed');
    _disposed = true;
    super.dispose();
  }
}
