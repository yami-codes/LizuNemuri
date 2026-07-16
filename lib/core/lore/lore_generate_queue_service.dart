import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/core/lore/lore_generate_queue_models.dart';
import 'package:lizunemu/core/lore/lore_generate_queue_notification.dart';
import 'package:lizunemu/core/lore/lore_generate_queue_store.dart';
import 'package:lizunemu/core/lore/lore_track_input_builder.dart';
import 'package:lizunemu/core/lore/models/work_lore_pack.dart';
import 'package:lizunemu/core/lore/work_lore_service.dart';
import 'package:lizunemu/core/platform/llm_background_keeper.dart';
import 'package:lizunemu/core/settings/app_settings_service.dart';
import 'package:lizunemu/data/models/files/child.dart';
import 'package:lizunemu/data/models/files/files.dart';
import 'package:lizunemu/data/models/works/work.dart';
import 'package:lizunemu/data/services/exceptions/llm_translation_exception.dart';
import 'package:lizunemu/utils/logger.dart';

/// App-level background queue for work-lore generation (survives detail pop).
class LoreGenerateQueueService extends ChangeNotifier {
  static const maxConcurrentJobs = 1;
  static const _keeperOwner = 'lore';

  final AppSettingsService _settings;
  final WorkLoreService _lore;
  final LoreTrackInputBuilder _trackBuilder;
  final LoreGenerateQueueStore _store;
  final LoreGenerateQueueNotification _notification;
  final LlmBackgroundKeeper? _keeper;

  final List<LoreGenerateQueueJob> _jobs = [];
  final Map<String, CancelToken> _cancelTokens = {};
  String? _activeJobId;
  bool _filling = false;
  bool _initialized = false;
  bool _keeperHeld = false;
  Timer? _persistDebounce;
  Timer? _heartbeat;

  LoreGenerateQueueService({
    required AppSettingsService settings,
    required WorkLoreService lore,
    required LoreTrackInputBuilder trackBuilder,
    required LoreGenerateQueueStore store,
    LoreGenerateQueueNotification? notification,
    LlmBackgroundKeeper? keeper,
  })  : _settings = settings,
        _lore = lore,
        _trackBuilder = trackBuilder,
        _store = store,
        _notification = notification ?? LoreGenerateQueueNotification(),
        _keeper = keeper;

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
    var waiting = false;
    DateTime? stageStartedAt;

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
          waiting = job.waitingOnLlm;
          stageStartedAt ??= job.stageStartedAt;
        case LoreGenerateQueueJobStatus.pending:
          break;
      }
    }

    LoreGenerateQueueJob? runningJob;
    for (final job in _jobs) {
      if (job.status == LoreGenerateQueueJobStatus.running) {
        runningJob = job;
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
      waitingOnLlm: waiting,
      stageStartedAt: stageStartedAt,
      tracksDone: runningJob?.tracksDone,
      tracksTotal: runningJob != null && runningJob.tracks.isNotEmpty
          ? runningJob.tracks.length
          : null,
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
        for (final t in job.tracks) {
          if (t.status == LoreGenerateTrackStatus.pending ||
              t.status == LoreGenerateTrackStatus.running) {
            t.status = LoreGenerateTrackStatus.cancelled;
          }
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
      if (job.isActive) {
        job.status = LoreGenerateQueueJobStatus.cancelled;
        for (final t in job.tracks) {
          if (t.status == LoreGenerateTrackStatus.pending ||
              t.status == LoreGenerateTrackStatus.running) {
            t.status = LoreGenerateTrackStatus.cancelled;
          }
        }
      }
    }
    await _persistNow();
    notifyListeners();
    unawaited(_syncNotification());
  }

  Future<void> retryFailed() async {
    for (final job in _jobs) {
      var touched = false;
      if (job.status == LoreGenerateQueueJobStatus.failed) {
        job.status = LoreGenerateQueueJobStatus.pending;
        job.lastError = null;
        job.progress = 0;
        job.progressStage = '';
        for (final t in job.tracks) {
          if (t.status == LoreGenerateTrackStatus.cancelled) continue;
          t.status = LoreGenerateTrackStatus.pending;
          t.error = null;
          t.attempts = 0;
        }
        touched = true;
      } else {
        for (final t in job.tracks) {
          if (t.status != LoreGenerateTrackStatus.failed) continue;
          t.status = LoreGenerateTrackStatus.pending;
          t.error = null;
          t.attempts = 0;
          touched = true;
        }
        if (touched && job.isFinished) {
          job.status = LoreGenerateQueueJobStatus.pending;
          job.lastError = null;
          job.progress = 0;
          job.progressStage = '';
        }
      }
      if (!touched) continue;
    }
    await _persistNow();
    notifyListeners();
    unawaited(_fillSlots());
  }

  Future<void> retryTrack(String jobId, String trackKey) async {
    for (final job in _jobs) {
      if (job.id != jobId) continue;
      for (final t in job.tracks) {
        if (t.trackKey != trackKey) continue;
        t.status = LoreGenerateTrackStatus.pending;
        t.error = null;
        t.attempts = 0;
      }
      if (job.isFinished || job.status == LoreGenerateQueueJobStatus.failed) {
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
    job.waitingOnLlm = false;
    job.progressStage = 'subs:resolve';
    job.progress = 0.01;
    job.stageStartedAt = DateTime.now();
    final token = CancelToken();
    _cancelTokens[job.id] = token;
    _startHeartbeat();
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
            onProgress: (stage, p) => _setProgress(job, stage, p),
          );

      void onWaiting(bool waiting) => _setWaiting(job, waiting);

      switch (job.kind) {
        case LoreGenerateKind.fullGenerate:
          final tracks = await buildTracks();
          _seedTracks(job, tracks);
          final pendingOnly = job.tracks.any(
                (t) => t.status == LoreGenerateTrackStatus.done,
              ) &&
              job.tracks.any(
                (t) =>
                    t.status == LoreGenerateTrackStatus.pending ||
                    t.status == LoreGenerateTrackStatus.failed,
              );
          if (pendingOnly) {
            final retryPack = pack ?? await _lore.load(workId);
            if (retryPack == null) {
              throw StateError('no lore pack for partial retry');
            }
            await _runFailedTracksOnly(
              job: job,
              pack: retryPack,
              allTracks: tracks,
              onWaiting: onWaiting,
              cancelToken: token,
            );
          } else {
            await _lore.generate(
              work: job.work,
              tracks: tracks,
              includeSecrets: job.includeSecrets,
              seedNotes: pack?.seedNotes ?? const [],
              onProgress: (stage, p) => _setProgress(job, stage, p),
              onWaiting: onWaiting,
              cancelToken: token,
            );
          }
          await _applyOutcomesFromPack(job);
        case LoreGenerateKind.secretsOnly:
          if (pack == null) {
            throw StateError('no lore pack for secrets');
          }
          final tracks = await buildTracks();
          _seedTracks(job, tracks);
          await _lore.generateSecrets(
            pack,
            work: job.work,
            tracks: tracks,
            onProgress: (stage, p) => _setProgress(job, stage, p),
            onWaiting: onWaiting,
            cancelToken: token,
          );
          await _applyOutcomesFromPack(job);
        case LoreGenerateKind.regenerateWork:
          if (pack == null) throw StateError('no lore pack');
          final tracks = await buildTracks();
          _seedTracks(job, tracks);
          await _lore.regenerateSection(
            work: job.work,
            pack: pack,
            section: LoreRegenSection.work,
            tracks: tracks,
            onProgress: (stage, p) => _setProgress(job, stage, p),
            onWaiting: onWaiting,
            cancelToken: token,
          );
        case LoreGenerateKind.regenerateTrack:
          if (pack == null || job.trackKey == null) {
            throw StateError('track regen requires pack + trackKey');
          }
          final tracks = await buildTracks();
          _seedTracks(job, tracks, onlyKey: job.trackKey);
          await _lore.regenerateSection(
            work: job.work,
            pack: pack,
            section: LoreRegenSection.track,
            trackKey: job.trackKey,
            tracks: tracks,
            onProgress: (stage, p) => _setProgress(job, stage, p),
            onWaiting: onWaiting,
            cancelToken: token,
          );
          await _applyOutcomesFromPack(job);
        case LoreGenerateKind.regenerateCharacter:
          if (pack == null || job.characterId == null) {
            throw StateError('character regen requires pack + characterId');
          }
          await _lore.regenerateSection(
            work: job.work,
            pack: pack,
            section: LoreRegenSection.character,
            characterId: job.characterId,
            onProgress: (stage, p) => _setProgress(job, stage, p),
            onWaiting: onWaiting,
            cancelToken: token,
          );
      }

      if (token.isCancelled) {
        job.status = LoreGenerateQueueJobStatus.cancelled;
      } else if (job.tracks.isNotEmpty &&
          job.tracks.every((t) => t.status == LoreGenerateTrackStatus.failed)) {
        job.status = LoreGenerateQueueJobStatus.failed;
        job.lastError ??= 'all tracks failed';
      } else {
        job.status = LoreGenerateQueueJobStatus.done;
        job.progress = 1;
        job.progressStage = 'done';
        job.waitingOnLlm = false;
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
      job.waitingOnLlm = false;
      _stopHeartbeat();
      _cancelTokens.remove(job.id);
      _activeJobId = null;
      await _persistNow();
      notifyListeners();
      unawaited(_fillSlots());
    }
  }

  Future<void> _runFailedTracksOnly({
    required LoreGenerateQueueJob job,
    required WorkLorePack pack,
    required List<LoreTrackInput> allTracks,
    required LoreWaitingCallback onWaiting,
    required CancelToken cancelToken,
  }) async {
    var current = pack;
    final byKey = {for (final t in allTracks) t.trackKey: t};
    for (final progress in job.tracks) {
      if (progress.status == LoreGenerateTrackStatus.done ||
          progress.status == LoreGenerateTrackStatus.skipped ||
          progress.status == LoreGenerateTrackStatus.cancelled) {
        continue;
      }
      progress.status = LoreGenerateTrackStatus.running;
      progress.attempts += 1;
      _forceNotify();
      final input = byKey[progress.trackKey];
      if (input == null) {
        progress.status = LoreGenerateTrackStatus.failed;
        progress.error = 'track missing';
        continue;
      }
      await _lore.regenerateSection(
        work: job.work,
        pack: current,
        section: LoreRegenSection.track,
        trackKey: progress.trackKey,
        tracks: allTracks,
        onProgress: (stage, p) => _setProgress(job, stage, p),
        onWaiting: onWaiting,
        cancelToken: cancelToken,
      );
      current = await _lore.load(job.workId) ?? current;
    }
  }

  void _seedTracks(
    LoreGenerateQueueJob job,
    List<LoreTrackInput> tracks, {
    String? onlyKey,
  }) {
    final filtered = onlyKey == null
        ? tracks
        : tracks.where((t) => t.trackKey == onlyKey).toList();
    if (job.tracks.isEmpty) {
      job.tracks.addAll([
        for (final t in filtered)
          LoreGenerateTrackProgress(
            trackKey: t.trackKey,
            title: t.title,
            index: t.index,
          ),
      ]);
      return;
    }
    // Keep existing statuses (partial retry); ensure rows exist for new keys.
    final existing = {for (final t in job.tracks) t.trackKey: t};
    for (final t in filtered) {
      if (existing.containsKey(t.trackKey)) continue;
      job.tracks.add(
        LoreGenerateTrackProgress(
          trackKey: t.trackKey,
          title: t.title,
          index: t.index,
        ),
      );
    }
  }

  void _applyStageToTracks(LoreGenerateQueueJob job, String stage) {
    final match = RegExp(r'^track:(\d+)/(\d+)').firstMatch(stage);
    if (match == null) return;
    final oneBased = int.tryParse(match.group(1) ?? '') ?? 0;
    if (oneBased <= 0) return;
    final idx = oneBased - 1;
    for (final t in job.tracks) {
      if (t.status == LoreGenerateTrackStatus.cancelled ||
          t.status == LoreGenerateTrackStatus.failed ||
          t.status == LoreGenerateTrackStatus.skipped) {
        continue;
      }
      if (t.index < idx && t.status == LoreGenerateTrackStatus.running) {
        t.status = LoreGenerateTrackStatus.done;
      } else if (t.index == idx) {
        if (t.status == LoreGenerateTrackStatus.pending) {
          t.attempts = t.attempts <= 0 ? 1 : t.attempts;
        }
        t.status = LoreGenerateTrackStatus.running;
      }
    }
  }

  Future<void> _applyOutcomesFromPack(LoreGenerateQueueJob job) async {
    if (job.tracks.isEmpty) return;
    final pack = await _lore.load(job.workId);
    if (pack == null) return;
    final byKey = {
      for (final s in pack.trackSummaries) s.trackKey: s,
    };
    for (final t in job.tracks) {
      if (t.status == LoreGenerateTrackStatus.cancelled ||
          t.status == LoreGenerateTrackStatus.skipped) {
        continue;
      }
      final summary = byKey[t.trackKey];
      final emptySoft = summary == null ||
          (summary.summary.trim().isEmpty && summary.lowConfidence);
      if (emptySoft) {
        t.status = LoreGenerateTrackStatus.failed;
        t.error ??= 'empty summary';
      } else {
        t.status = LoreGenerateTrackStatus.done;
        t.error = null;
      }
    }
  }

  void _setProgress(LoreGenerateQueueJob job, String stage, double p) {
    final changed = job.progressStage != stage;
    job.progressStage = stage;
    job.progress = p;
    _applyStageToTracks(job, stage);
    if (changed) {
      job.stageStartedAt = DateTime.now();
      _forceNotify();
    } else {
      _softNotify();
    }
  }

  void _setWaiting(LoreGenerateQueueJob job, bool waiting) {
    if (job.waitingOnLlm == waiting) return;
    job.waitingOnLlm = waiting;
    if (waiting) {
      job.stageStartedAt = DateTime.now();
    }
    _forceNotify();
  }

  void _startHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_activeJobId == null) return;
      notifyListeners();
    });
  }

  void _stopHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = null;
  }

  Future<void> _failOrRetry(LoreGenerateQueueJob job, String error) async {
    job.lastError = error;
    job.waitingOnLlm = false;
    for (final t in job.tracks) {
      if (t.status == LoreGenerateTrackStatus.running) {
        t.status = LoreGenerateTrackStatus.failed;
        t.error = error;
      }
    }
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

  void _forceNotify() {
    _lastSoft = DateTime.now();
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
    final snap = snapshot;
    if (_keeper != null) {
      if (snap.isActive) {
        if (!_keeperHeld) {
          await _keeper.acquire(_keeperOwner);
          _keeperHeld = true;
        }
        final name = snap.currentWorkTitle ?? '';
        final body = snap.waitingOnLlm
            ? Strings.loreProgressWaitingLlm
            : (snap.tracksDone != null && snap.tracksTotal != null
                ? Strings.loreQueueNotificationBody(
                    snap.tracksDone!,
                    snap.tracksTotal!,
                    name,
                  )
                : Strings.loreQueueNotificationIdle(
                    snap.completedJobs,
                    snap.totalJobs,
                  ));
        final progressPct = snap.progress == null
            ? null
            : (snap.progress! * 100).round().clamp(0, 100);
        await _keeper.update(
          title: Strings.loreQueueNotificationTitle,
          body: body,
          progress: progressPct,
          indeterminate: snap.waitingOnLlm,
        );
      } else if (_keeperHeld) {
        await _keeper.release(_keeperOwner);
        _keeperHeld = false;
      }
      return;
    }
    await _notification.update(snap);
  }
}
