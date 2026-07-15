import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:lizunemu/core/lore/lore_generate_queue_models.dart';
import 'package:lizunemu/core/lore/lore_generate_queue_notification.dart';
import 'package:lizunemu/core/lore/lore_generate_queue_store.dart';
import 'package:lizunemu/core/lore/lore_track_input_builder.dart';
import 'package:lizunemu/core/lore/work_lore_service.dart';
import 'package:lizunemu/core/settings/app_settings_service.dart';
import 'package:lizunemu/data/models/files/child.dart';
import 'package:lizunemu/data/models/files/files.dart';
import 'package:lizunemu/data/models/works/work.dart';
import 'package:lizunemu/data/services/exceptions/llm_translation_exception.dart';
import 'package:lizunemu/utils/logger.dart';

/// App-level background queue for work-lore generation (survives detail pop).
class LoreGenerateQueueService extends ChangeNotifier {
  static const maxConcurrentJobs = 1;

  final AppSettingsService _settings;
  final WorkLoreService _lore;
  final LoreTrackInputBuilder _trackBuilder;
  final LoreGenerateQueueStore _store;
  final LoreGenerateQueueNotification _notification;

  final List<LoreGenerateQueueJob> _jobs = [];
  final Map<String, CancelToken> _cancelTokens = {};
  String? _activeJobId;
  bool _filling = false;
  bool _initialized = false;
  Timer? _persistDebounce;

  LoreGenerateQueueService({
    required AppSettingsService settings,
    required WorkLoreService lore,
    required LoreTrackInputBuilder trackBuilder,
    required LoreGenerateQueueStore store,
    LoreGenerateQueueNotification? notification,
  })  : _settings = settings,
        _lore = lore,
        _trackBuilder = trackBuilder,
        _store = store,
        _notification = notification ?? LoreGenerateQueueNotification();

  List<LoreGenerateQueueJob> get jobs => List.unmodifiable(_jobs);

  bool get hasWork => _jobs.any((j) => j.isActive);

  LoreGenerateQueueJob? activeJobForWork(String workId) {
    for (final j in _jobs) {
      if (j.workId == workId && j.isActive) return j;
    }
    return null;
  }

  bool isWorkQueued(String workId) => activeJobForWork(workId) != null;

  LoreGenerateQueueSnapshot get snapshot {
    var total = 0;
    var completed = 0;
    var failed = 0;
    var running = 0;
    String? workTitle;
    String? stage;
    double? progress;

    for (final job in _jobs) {
      total++;
      switch (job.status) {
        case LoreGenerateQueueJobStatus.done:
        case LoreGenerateQueueJobStatus.cancelled:
          completed++;
        case LoreGenerateQueueJobStatus.failed:
          failed++;
          completed++;
        case LoreGenerateQueueJobStatus.running:
          running++;
          workTitle ??= job.workTitle;
          stage ??= job.progressStage;
          progress ??= job.progress;
        case LoreGenerateQueueJobStatus.pending:
          break;
      }
    }

    return LoreGenerateQueueSnapshot(
      totalJobs: total,
      completedJobs: completed,
      failedJobs: failed,
      runningJobs: running,
      isActive: hasWork || running > 0,
      currentWorkTitle: workTitle,
      progressStage: stage,
      progress: progress,
    );
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    _jobs
      ..clear()
      ..addAll(_store.load());
    _jobs.removeWhere(
      (j) =>
          j.isFinished &&
          j.status != LoreGenerateQueueJobStatus.failed,
    );
    await _notification.initialize();
    notifyListeners();
    unawaited(_fillSlots());
  }

  Future<int> enqueueGenerate({
    required Work work,
    Files? files,
    required List<({Child audio, Child? subtitle})> pairs,
    bool includeSecrets = true,
  }) {
    return _enqueue(
      LoreGenerateQueueJob(
        id: _newId(work),
        work: work,
        files: files,
        pairs: pairs,
        kind: LoreGenerateKind.fullGenerate,
        includeSecrets: includeSecrets,
      ),
    );
  }

  Future<int> enqueueSecrets({
    required Work work,
    Files? files,
    required List<({Child audio, Child? subtitle})> pairs,
  }) {
    return _enqueue(
      LoreGenerateQueueJob(
        id: _newId(work),
        work: work,
        files: files,
        pairs: pairs,
        kind: LoreGenerateKind.secretsOnly,
        includeSecrets: true,
      ),
    );
  }

  Future<int> enqueueRegenerate({
    required Work work,
    Files? files,
    required List<({Child audio, Child? subtitle})> pairs,
    required LoreGenerateKind kind,
    String? trackKey,
    String? characterId,
  }) {
    assert(
      kind == LoreGenerateKind.regenerateWork ||
          kind == LoreGenerateKind.regenerateTrack ||
          kind == LoreGenerateKind.regenerateCharacter,
    );
    return _enqueue(
      LoreGenerateQueueJob(
        id: _newId(work),
        work: work,
        files: files,
        pairs: pairs,
        kind: kind,
        trackKey: trackKey,
        characterId: characterId,
      ),
    );
  }

  Future<int> _enqueue(LoreGenerateQueueJob job) async {
    final workId = job.workId;
    if (isWorkQueued(workId)) {
      AppLogger.debug('Lore queue: skip duplicate enqueue for $workId');
      return 0;
    }
    _jobs.add(job);
    await _persistNow();
    notifyListeners();
    unawaited(_fillSlots());
    return 1;
  }

  Future<void> cancelJob(String jobId) async {
    _cancelTokens[jobId]?.cancel('user');
    for (final job in _jobs) {
      if (job.id != jobId) continue;
      if (job.isActive) {
        job.status = LoreGenerateQueueJobStatus.cancelled;
        job.progressStage = 'cancelled';
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
      if (job.isActive) {
        job.status = LoreGenerateQueueJobStatus.cancelled;
      }
    }
    await _persistNow();
    notifyListeners();
    unawaited(_syncNotification());
  }

  Future<void> retryFailed() async {
    for (final job in _jobs) {
      if (job.status == LoreGenerateQueueJobStatus.failed) {
        job.status = LoreGenerateQueueJobStatus.pending;
        job.lastError = null;
        job.progress = 0;
        job.progressStage = '';
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

  String _newId(Work work) =>
      '${work.id ?? work.sourceId ?? 'w'}_${DateTime.now().millisecondsSinceEpoch}';

  Future<void> _fillSlots() async {
    if (_filling) return;
    _filling = true;
    try {
      while (_activeJobId == null) {
        LoreGenerateQueueJob? next;
        for (final j in _jobs) {
          if (j.status == LoreGenerateQueueJobStatus.pending) {
            next = j;
            break;
          }
        }
        if (next == null) break;
        await _runJob(next);
      }
    } finally {
      _filling = false;
      unawaited(_syncNotification());
    }
  }

  Future<void> _runJob(LoreGenerateQueueJob job) async {
    _activeJobId = job.id;
    job.status = LoreGenerateQueueJobStatus.running;
    job.attempts += 1;
    final token = CancelToken();
    _cancelTokens[job.id] = token;
    notifyListeners();
    await _persistNow();

    try {
      final workId = job.workId;
      final pack = await _lore.load(workId);

      Future<List<LoreTrackInput>> buildTracks() => _trackBuilder.build(
            work: job.work,
            workId: workId,
            pairs: job.pairs,
            files: job.files,
            alignToPack: pack,
          );

      switch (job.kind) {
        case LoreGenerateKind.fullGenerate:
          await _lore.generate(
            work: job.work,
            tracks: await buildTracks(),
            includeSecrets: job.includeSecrets,
            seedNotes: pack?.seedNotes ?? const [],
            onProgress: (stage, p) {
              job.progressStage = stage;
              job.progress = p;
              _softNotify();
            },
            cancelToken: token,
          );
        case LoreGenerateKind.secretsOnly:
          if (pack == null) {
            throw StateError('no lore pack for secrets');
          }
          await _lore.generateSecrets(
            pack,
            work: job.work,
            tracks: await buildTracks(),
            onProgress: (stage, p) {
              job.progressStage = stage;
              job.progress = p;
              _softNotify();
            },
            cancelToken: token,
          );
        case LoreGenerateKind.regenerateWork:
          if (pack == null) throw StateError('no lore pack');
          await _lore.regenerateSection(
            work: job.work,
            pack: pack,
            section: LoreRegenSection.work,
            tracks: await buildTracks(),
            onProgress: (stage, p) {
              job.progressStage = stage;
              job.progress = p;
              _softNotify();
            },
            cancelToken: token,
          );
        case LoreGenerateKind.regenerateTrack:
          if (pack == null || job.trackKey == null) {
            throw StateError('track regen requires pack + trackKey');
          }
          await _lore.regenerateSection(
            work: job.work,
            pack: pack,
            section: LoreRegenSection.track,
            trackKey: job.trackKey,
            tracks: await buildTracks(),
            onProgress: (stage, p) {
              job.progressStage = stage;
              job.progress = p;
              _softNotify();
            },
            cancelToken: token,
          );
        case LoreGenerateKind.regenerateCharacter:
          if (pack == null || job.characterId == null) {
            throw StateError('character regen requires pack + characterId');
          }
          await _lore.regenerateSection(
            work: job.work,
            pack: pack,
            section: LoreRegenSection.character,
            characterId: job.characterId,
            onProgress: (stage, p) {
              job.progressStage = stage;
              job.progress = p;
              _softNotify();
            },
            cancelToken: token,
          );
      }

      if (token.isCancelled) {
        job.status = LoreGenerateQueueJobStatus.cancelled;
      } else {
        job.status = LoreGenerateQueueJobStatus.done;
        job.progress = 1;
        job.progressStage = 'done';
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        job.status = LoreGenerateQueueJobStatus.cancelled;
      } else {
        await _failOrRetry(job, e.message ?? e.toString());
      }
    } on LlmTranslationException catch (e) {
      await _failOrRetry(job, e.userMessage);
    } catch (e, st) {
      AppLogger.error('Lore queue job failed: ${job.id}', e, st);
      await _failOrRetry(job, e.toString());
    } finally {
      _cancelTokens.remove(job.id);
      _activeJobId = null;
      await _persistNow();
      notifyListeners();
      unawaited(_fillSlots());
    }
  }

  Future<void> _failOrRetry(LoreGenerateQueueJob job, String error) async {
    job.lastError = error;
    final maxRetries = _settings.llmTranslateRetryCount;
    if (job.attempts <= maxRetries) {
      job.status = LoreGenerateQueueJobStatus.pending;
      job.progressStage = 'retry';
    } else {
      job.status = LoreGenerateQueueJobStatus.failed;
    }
  }

  DateTime _lastSoft = DateTime.fromMillisecondsSinceEpoch(0);
  void _softNotify() {
    final now = DateTime.now();
    if (now.difference(_lastSoft).inMilliseconds < 200) return;
    _lastSoft = now;
    notifyListeners();
    _persistDebounced();
    unawaited(_syncNotification());
  }

  void _persistDebounced() {
    _persistDebounce?.cancel();
    _persistDebounce = Timer(const Duration(milliseconds: 300), () {
      unawaited(_persistNow());
    });
  }

  Future<void> _persistNow() async {
    await _store.save(_jobs);
  }

  Future<void> _syncNotification() async {
    await _notification.update(snapshot);
  }
}
