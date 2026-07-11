import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:lizunemu/core/audio/models/playback_context.dart';
import 'package:lizunemu/core/audio/models/subtitle.dart';
import 'package:lizunemu/core/download/download_service.dart';
import 'package:lizunemu/core/llm/subtitle_translation_progress.dart';
import 'package:lizunemu/core/llm/subtitle_translation_result.dart';
import 'package:lizunemu/core/llm/subtitle_translation_service.dart';
import 'package:lizunemu/core/llm/translation_queue_models.dart';
import 'package:lizunemu/core/llm/translation_queue_notification.dart';
import 'package:lizunemu/core/llm/translation_queue_store.dart';
import 'package:lizunemu/core/settings/app_settings_service.dart';
import 'package:lizunemu/core/subtitle/subtitle_import_service.dart';
import 'package:lizunemu/core/subtitle/subtitle_loader.dart';
import 'package:lizunemu/data/models/files/child.dart';
import 'package:lizunemu/data/models/files/files.dart';
import 'package:lizunemu/data/models/works/work.dart';
import 'package:lizunemu/utils/logger.dart';

/// App-level background queue for bulk LLM subtitle translation.
///
/// Survives navigation (not owned by a dialog). Persists jobs so cold starts
/// resume unfinished tracks without re-burning completed lines.
class TranslationQueueService extends ChangeNotifier {
  static const maxConcurrentTracks = 2;

  final AppSettingsService _settings;
  final SubtitleTranslationService _translation;
  final DownloadService _download;
  final SubtitleLoader _subtitleLoader;
  final SubtitleImportService _importService;
  final TranslationQueueStore _store;
  final TranslationQueueNotification _notification;

  final List<TranslationQueueJob> _jobs = [];
  final Map<String, CancelToken> _cancelTokens = {};
  final Set<String> _activeTrackIds = {};
  bool _filling = false;
  bool _initialized = false;
  Timer? _persistDebounce;
  DateTime _lastNotifyAt = DateTime.fromMillisecondsSinceEpoch(0);

  TranslationQueueService({
    required AppSettingsService settings,
    required SubtitleTranslationService translation,
    required DownloadService download,
    required SubtitleLoader subtitleLoader,
    required SubtitleImportService importService,
    required TranslationQueueStore store,
    TranslationQueueNotification? notification,
  })  : _settings = settings,
        _translation = translation,
        _download = download,
        _subtitleLoader = subtitleLoader,
        _importService = importService,
        _store = store,
        _notification = notification ?? TranslationQueueNotification();

  List<TranslationQueueJob> get jobs => List.unmodifiable(_jobs);

  bool get hasWork => _jobs.any((j) => !j.isFinished);

  TranslationQueueSnapshot get snapshot {
    var total = 0;
    var completed = 0;
    var failed = 0;
    var running = 0;
    String? trackName;
    String? workTitle;
    BatchTranslatePhase? phase;
    int? batch;
    int? batchTotal;

    for (final job in _jobs) {
      for (final track in job.tracks) {
        total++;
        switch (track.status) {
          case TranslationQueueTrackStatus.done:
          case TranslationQueueTrackStatus.cached:
          case TranslationQueueTrackStatus.cancelled:
            completed++;
          case TranslationQueueTrackStatus.failed:
            failed++;
            completed++;
          case TranslationQueueTrackStatus.running:
            running++;
            trackName ??= track.trackName;
            workTitle ??= job.workTitle;
            phase ??= track.phase;
            batch ??= track.llmBatchIndex;
            batchTotal ??= track.llmBatchTotal;
          case TranslationQueueTrackStatus.pending:
            break;
        }
      }
    }

    return TranslationQueueSnapshot(
      totalTracks: total,
      completedTracks: completed,
      failedTracks: failed,
      runningTracks: running,
      isActive: hasWork || running > 0,
      currentTrackName: trackName,
      currentWorkTitle: workTitle,
      phase: phase,
      llmBatchIndex: batch,
      llmBatchTotal: batchTotal,
    );
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    _jobs
      ..clear()
      ..addAll(_store.load());
    // Drop fully finished jobs from a previous session to keep the list tidy,
    // but keep failed tracks so the user can retry.
    _jobs.removeWhere(
      (j) =>
          j.isFinished &&
          j.failedCount == 0 &&
          j.tracks.every(
            (t) =>
                t.status == TranslationQueueTrackStatus.done ||
                t.status == TranslationQueueTrackStatus.cached ||
                t.status == TranslationQueueTrackStatus.cancelled,
          ),
    );
    await _notification.initialize();
    notifyListeners();
    unawaited(_fillSlots());
  }

  /// Enqueue selected audio+subtitle pairs for [work]. Returns track count added.
  Future<int> enqueue({
    required Work work,
    required Files files,
    required List<({Child audio, Child subtitle})> pairs,
  }) async {
    if (pairs.isEmpty) return 0;
    final jobId =
        '${work.id ?? 'w'}_${DateTime.now().millisecondsSinceEpoch}';
    final tracks = <TranslationQueueTrack>[];
    for (var i = 0; i < pairs.length; i++) {
      final p = pairs[i];
      final base =
          '${jobId}_${p.audio.hash ?? p.audio.title ?? 't'}_$i';
      tracks.add(
        TranslationQueueTrack(
          id: base,
          audio: p.audio,
          subtitle: p.subtitle,
        ),
      );
    }

    _jobs.add(
      TranslationQueueJob(
        id: jobId,
        work: work,
        files: files,
        tracks: tracks,
      ),
    );
    await _persistNow();
    notifyListeners();
    unawaited(_fillSlots());
    return tracks.length;
  }

  Future<void> cancelTrack(String trackId) async {
    _cancelTokens[trackId]?.cancel('user');
    for (final job in _jobs) {
      for (final track in job.tracks) {
        if (track.id != trackId) continue;
        if (track.status == TranslationQueueTrackStatus.pending ||
            track.status == TranslationQueueTrackStatus.running) {
          track.status = TranslationQueueTrackStatus.cancelled;
          track.phase = null;
        }
      }
    }
    await _persistNow();
    notifyListeners();
    unawaited(_syncNotification());
  }

  Future<void> cancelAll() async {
    for (final token in _cancelTokens.values) {
      token.cancel('user');
    }
    for (final job in _jobs) {
      for (final track in job.tracks) {
        if (track.status == TranslationQueueTrackStatus.pending ||
            track.status == TranslationQueueTrackStatus.running) {
          track.status = TranslationQueueTrackStatus.cancelled;
          track.phase = null;
        }
      }
    }
    await _persistNow();
    notifyListeners();
    await _notification.clear();
  }

  Future<void> retryFailed() async {
    for (final job in _jobs) {
      for (final track in job.tracks) {
        if (track.status == TranslationQueueTrackStatus.failed) {
          track.status = TranslationQueueTrackStatus.pending;
          track.attempts = 0;
          track.lastError = null;
        }
      }
    }
    await _persistNow();
    notifyListeners();
    unawaited(_fillSlots());
  }

  Future<void> retryTrack(String trackId) async {
    for (final job in _jobs) {
      for (final track in job.tracks) {
        if (track.id != trackId) continue;
        track.status = TranslationQueueTrackStatus.pending;
        track.attempts = 0;
        track.lastError = null;
      }
    }
    await _persistNow();
    notifyListeners();
    unawaited(_fillSlots());
  }

  Future<void> clearFinished() async {
    _jobs.removeWhere((j) => j.isFinished);
    await _persistNow();
    notifyListeners();
  }

  Future<void> _fillSlots() async {
    if (_filling) return;
    _filling = true;
    try {
      while (_activeTrackIds.length < maxConcurrentTracks) {
        final next = _nextPending();
        if (next == null) break;
        final (job, track) = next;
        track.status = TranslationQueueTrackStatus.running;
        _activeTrackIds.add(track.id);
        notifyListeners();
        unawaited(_runTrack(job, track));
      }
    } finally {
      _filling = false;
    }
  }

  (TranslationQueueJob, TranslationQueueTrack)? _nextPending() {
    for (final job in _jobs) {
      for (final track in job.tracks) {
        if (track.status == TranslationQueueTrackStatus.pending &&
            !_activeTrackIds.contains(track.id)) {
          return (job, track);
        }
      }
    }
    return null;
  }

  Future<void> _runTrack(
    TranslationQueueJob job,
    TranslationQueueTrack track,
  ) async {
    final token = CancelToken();
    _cancelTokens[track.id] = token;
    final maxAttempts = _settings.llmTranslateRetryCount + 1;

    try {
      while (track.attempts < maxAttempts) {
        if (token.isCancelled ||
            track.status == TranslationQueueTrackStatus.cancelled) {
          track.status = TranslationQueueTrackStatus.cancelled;
          break;
        }

        track.attempts++;
        track.phase = BatchTranslatePhase.loadingSubtitle;
        _notifyProgress();

        final list = await _loadSubtitle(job.workId, track.subtitle);
        if (list == null) {
          track.lastError = 'subtitle load failed';
          track.phase = BatchTranslatePhase.failed;
          if (track.attempts >= maxAttempts) {
            track.status = TranslationQueueTrackStatus.failed;
            break;
          }
          continue;
        }

        if (token.isCancelled) {
          track.status = TranslationQueueTrackStatus.cancelled;
          break;
        }

        final ctx = PlaybackContext(
          work: job.work,
          files: job.files,
          currentFile: track.audio,
        );

        track.phase = BatchTranslatePhase.checkingCache;
        _notifyProgress();
        if (await _translation.isCached(source: list, context: ctx)) {
          track.status = TranslationQueueTrackStatus.cached;
          track.phase = BatchTranslatePhase.cached;
          break;
        }

        track.phase = BatchTranslatePhase.translating;
        _notifyProgress();

        final result = await _translation.translateNow(
          source: list,
          context: ctx,
          onProgress: (p) {
            if (p.phase == SubtitleTranslationPhase.translating) {
              track.phase = BatchTranslatePhase.translating;
              track.llmBatchIndex = p.batchIndex;
              track.llmBatchTotal = p.batchTotal;
              _notifyProgress();
            }
          },
        );

        if (token.isCancelled) {
          // Partial lines already persisted by the translation service.
          track.status = TranslationQueueTrackStatus.cancelled;
          break;
        }

        if (_isSuccess(result)) {
          track.status = result.fromCache
              ? TranslationQueueTrackStatus.cached
              : TranslationQueueTrackStatus.done;
          track.phase = result.fromCache
              ? BatchTranslatePhase.cached
              : BatchTranslatePhase.translating;
          track.lastError = null;
          break;
        }

        track.lastError = result.error?.message ?? 'translation failed';
        track.phase = BatchTranslatePhase.failed;
        if (track.attempts >= maxAttempts) {
          track.status = TranslationQueueTrackStatus.failed;
          break;
        }
        // Retry — partial cache will resume unfinished lines.
      }
    } catch (e, st) {
      AppLogger.error('Translation queue track failed', e, st);
      track.lastError = e.toString();
      if (track.attempts >= maxAttempts) {
        track.status = TranslationQueueTrackStatus.failed;
      } else if (track.status == TranslationQueueTrackStatus.running) {
        // Schedule another attempt via pending.
        track.status = TranslationQueueTrackStatus.pending;
      }
    } finally {
      _cancelTokens.remove(track.id);
      _activeTrackIds.remove(track.id);
      if (track.status == TranslationQueueTrackStatus.running) {
        track.status = TranslationQueueTrackStatus.failed;
      }
      _persistDebounced();
      notifyListeners();
      unawaited(_syncNotification());
      unawaited(_fillSlots());
    }
  }

  bool _isSuccess(SubtitleTranslationResult result) {
    if (result.isFailure) return false;
    if (result.skipped) return false;
    // Partial without error still counts as incomplete — retry.
    if (result.isPartial) return false;
    return result.translated || result.fromCache;
  }

  Future<SubtitleList?> _loadSubtitle(String workId, Child subtitle) async {
    final localPath =
        await _download.localPathIfDownloaded(workId, subtitle);
    if (localPath != null) {
      return _importService.loadLocalSubtitle(localPath);
    }
    final url = subtitle.mediaDownloadUrl;
    if (url == null) return null;
    try {
      return await _subtitleLoader.loadSubtitleContent(url);
    } catch (e) {
      AppLogger.warning('Queue subtitle load failed: $e');
      return null;
    }
  }

  void _notifyProgress() {
    notifyListeners();
    final now = DateTime.now();
    if (now.difference(_lastNotifyAt) >= const Duration(milliseconds: 400)) {
      _lastNotifyAt = now;
      unawaited(_syncNotification());
    }
  }

  Future<void> _syncNotification() => _notification.update(snapshot);

  void _persistDebounced() {
    _persistDebounce?.cancel();
    _persistDebounce = Timer(const Duration(milliseconds: 300), () {
      unawaited(_persistNow());
    });
  }

  Future<void> _persistNow() async {
    await _store.save(_jobs);
  }
}
