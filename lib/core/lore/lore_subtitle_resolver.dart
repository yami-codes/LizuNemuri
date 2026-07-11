import 'package:lizunemu/core/download/download_service.dart';
import 'package:lizunemu/core/media/work_media_url_refresher.dart';
import 'package:lizunemu/core/subtitle/subtitle_import_service.dart';
import 'package:lizunemu/core/subtitle/subtitle_loader.dart';
import 'package:lizunemu/data/models/files/child.dart';
import 'package:lizunemu/data/models/files/files.dart';
import 'package:lizunemu/utils/logger.dart';
import 'package:universal_io/io.dart';

/// Resolves subtitle *text* for lore generation — mirrors player priority:
/// user-imported → downloaded local → refreshed online URL.
class LoreSubtitleResolver {
  final SubtitleLoader _loader;
  final DownloadService _downloads;
  final WorkMediaUrlRefresher _urlRefresher;
  final SubtitleImportService _imports;

  LoreSubtitleResolver({
    required SubtitleLoader loader,
    required DownloadService downloads,
    required WorkMediaUrlRefresher urlRefresher,
    required SubtitleImportService imports,
  })  : _loader = loader,
        _downloads = downloads,
        _urlRefresher = urlRefresher,
        _imports = imports;

  Future<String?> resolveText({
    required String workId,
    required Child audio,
    Child? matchedSubtitle,
    Files? files,
  }) async {
    // 1. User-imported subtitle for this audio title (same as player).
    final audioTitle = audio.title;
    if (audioTitle != null && audioTitle.isNotEmpty) {
      try {
        final entry = await _imports.findImported(workId, audioTitle);
        if (entry != null) {
          final raw = await File(entry.subtitlePath).readAsString();
          if (raw.trim().isNotEmpty) return raw;
        }
      } catch (e) {
        AppLogger.debug('LoreSubtitleResolver import skip: $e');
      }
    }

    var sub = matchedSubtitle;
    if (sub == null && files != null) {
      sub = _loader.findSubtitleFile(audio, files);
    }
    if (sub == null) return null;

    // 2. Downloaded local subtitle file.
    try {
      final localPath = await _downloads.localPathIfDownloaded(workId, sub);
      if (localPath != null) {
        final raw = await File(localPath).readAsString();
        if (raw.trim().isNotEmpty) return raw;
      }
    } catch (e) {
      AppLogger.debug('LoreSubtitleResolver local skip: $e');
    }

    // 3. Online — refresh presigned URL first (tree URLs are often stale/null).
    Child refreshed = sub;
    try {
      refreshed = await _urlRefresher.refreshFile(workId: workId, file: sub);
    } catch (e) {
      AppLogger.debug('LoreSubtitleResolver refresh skip: $e');
    }

    final url = refreshed.mediaDownloadUrl ?? refreshed.mediaStreamUrl;
    if (url == null || url.isEmpty) {
      AppLogger.debug(
        'LoreSubtitleResolver: no URL for ${refreshed.title} after refresh',
      );
      return null;
    }

    try {
      final raw = await _loader.loadRawContent(url: url);
      if (raw.trim().isNotEmpty) return raw;
    } catch (e) {
      AppLogger.debug('LoreSubtitleResolver network skip: $e');
    }
    return null;
  }
}
