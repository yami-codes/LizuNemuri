import 'package:universal_io/io.dart';

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:lizunemu/common/constants/log_strings.dart';
import 'package:lizunemu/core/audio/i_audio_player_service.dart';
import 'package:lizunemu/core/audio/models/playback_context.dart';
import 'package:lizunemu/core/download/models/download_entry.dart';
import 'package:lizunemu/core/download/storage/i_download_repository.dart';
import 'package:lizunemu/core/download/utils/download_grouping.dart';
import 'package:lizunemu/data/models/files/child.dart';
import 'package:lizunemu/data/models/files/files.dart';
import 'package:lizunemu/data/models/works/work.dart';
import 'package:lizunemu/data/models/works/work_info.dart';
import 'package:lizunemu/data/services/api_service.dart';
import 'package:lizunemu/utils/logger.dart';
import 'package:lizunemu/utils/user_facing_error.dart';

/// Cached metadata for a downloaded work (best-effort from API).
class DownloadWorkMeta {
  final String? title;
  final String? sourceId;
  final String? coverUrl;

  const DownloadWorkMeta({this.title, this.sourceId, this.coverUrl});
}

class DownloadsViewModel extends ChangeNotifier {
  final IDownloadRepository _repository;
  final ApiService _apiService;
  final IAudioPlayerService _audioService;

  DownloadsViewModel({
    IDownloadRepository? repository,
    ApiService? apiService,
    IAudioPlayerService? audioService,
  })  : _repository = repository ?? GetIt.I<IDownloadRepository>(),
        _apiService = apiService ?? GetIt.I<ApiService>(),
        _audioService = audioService ?? GetIt.I<IAudioPlayerService>();

  List<DownloadWorkGroup> _groups = [];
  final Map<String, DownloadWorkMeta> _metaByWorkId = {};
  bool _isLoading = false;
  String? _error;
  bool _disposed = false;

  List<DownloadWorkGroup> get groups => _groups;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isEmpty => !_isLoading && _error == null && _groups.isEmpty;

  DownloadWorkMeta? metaFor(String workId) => _metaByWorkId[workId];

  String displayTitleFor(DownloadWorkGroup group) {
    final meta = _metaByWorkId[group.workId];
    if (meta?.title != null && meta!.title!.isNotEmpty) {
      return meta.title!;
    }
    if (meta?.sourceId != null && meta!.sourceId!.isNotEmpty) {
      return meta.sourceId!;
    }
    return group.workId;
  }

  String? subtitleIdFor(DownloadWorkGroup group) {
    final meta = _metaByWorkId[group.workId];
    final sourceId = meta?.sourceId;
    if (sourceId == null || sourceId.isEmpty) return null;
    final title = displayTitleFor(group);
    if (title == sourceId) return null;
    return sourceId;
  }

  Work workFor(DownloadWorkGroup group) {
    final meta = _metaByWorkId[group.workId];
    return Work(
      id: int.tryParse(group.workId),
      title: meta?.title,
      sourceId: meta?.sourceId,
      mainCoverUrl: meta?.coverUrl,
    );
  }

  Future<void> load() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final all = await _repository.listAllOldestFirst();
      final live = <DownloadEntry>[];
      for (final entry in all) {
        if (await File(entry.filePath).exists()) {
          live.add(entry);
        }
      }
      _groups = groupDownloadsByWork(live);
      _isLoading = false;
      notifyListeners();
      await _enrichMetadata();
    } catch (e) {
      AppLogger.error(LogStrings.logLoadDownloadsFailed, e);
      _error = userFacingError(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load();

  Future<void> playGroup(DownloadWorkGroup group) async {
    final audio = group.audioEntries;
    if (audio.isEmpty) return;

    final children = audio.map(_childFromEntry).toList();
    final work = workFor(group);
    final files = Files(children: children);
    final context = PlaybackContext.withFilteredPlaylist(
      work: work,
      files: files,
      currentFile: children.first,
      playlist: children,
    );

    try {
      await _audioService.playWithContext(context);
    } catch (e) {
      AppLogger.error(LogStrings.logPlaybackFailed, e);
      rethrow;
    }
  }

  Child _childFromEntry(DownloadEntry entry) => Child(
        type: entry.mediaType,
        title: entry.fileName,
        mediaDownloadUrl: entry.sourceUrl,
        size: entry.size,
      );

  Future<void> _enrichMetadata() async {
    final ids = _groups.map((g) => g.workId).toList();
    for (final workId in ids) {
      if (_disposed) return;
      try {
        final info = await _apiService.getWorkInfo(workId);
        _applyWorkInfo(workId, info);
      } catch (_) {
        // Best-effort metadata; offline hub still lists by workId.
      }
    }
  }

  void _applyWorkInfo(String workId, WorkInfo info) {
    _metaByWorkId[workId] = DownloadWorkMeta(
      title: info.title,
      sourceId: info.sourceId,
      coverUrl: info.mainCoverUrl ?? info.thumbnailCoverUrl,
    );
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
