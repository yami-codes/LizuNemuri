import 'package:lizunemu/data/models/files/child.dart';
import 'package:lizunemu/data/models/files/files.dart';
import 'package:lizunemu/data/models/works/work.dart';

enum LoreGenerateQueueJobStatus {
  pending,
  running,
  done,
  failed,
  cancelled,
}

enum LoreGenerateKind {
  fullGenerate,
  secretsOnly,
  regenerateWork,
  regenerateTrack,
  regenerateCharacter,
}

enum LoreGenerateTrackStatus {
  pending,
  running,
  done,
  failed,
  skipped,
  cancelled,
}

class LoreGenerateTrackProgress {
  final String trackKey;
  final String title;
  final int index;
  LoreGenerateTrackStatus status;
  int attempts;
  String? error;

  /// Ephemeral NDJSON stream progress (not persisted).
  int streamEventsSeen;
  String? streamLastEventTitle;
  bool streamGotSummary;

  LoreGenerateTrackProgress({
    required this.trackKey,
    required this.title,
    required this.index,
    this.status = LoreGenerateTrackStatus.pending,
    this.attempts = 0,
    this.error,
    this.streamEventsSeen = 0,
    this.streamLastEventTitle,
    this.streamGotSummary = false,
  });

  void clearStreamProgress() {
    streamEventsSeen = 0;
    streamLastEventTitle = null;
    streamGotSummary = false;
  }

  Map<String, dynamic> toJson() => {
        'trackKey': trackKey,
        'title': title,
        'index': index,
        'status': status.name,
        'attempts': attempts,
        if (error != null) 'error': error,
      };

  factory LoreGenerateTrackProgress.fromJson(Map<String, dynamic> json) {
    final statusName = json['status'] as String? ?? 'pending';
    var status = LoreGenerateTrackStatus.values.firstWhere(
      (v) => v.name == statusName,
      orElse: () => LoreGenerateTrackStatus.pending,
    );
    if (status == LoreGenerateTrackStatus.running) {
      status = LoreGenerateTrackStatus.pending;
    }
    return LoreGenerateTrackProgress(
      trackKey: json['trackKey'] as String? ?? '',
      title: json['title'] as String? ?? '',
      index: json['index'] as int? ?? 0,
      status: status,
      attempts: json['attempts'] as int? ?? 0,
      error: json['error'] as String?,
    );
  }
}

class LoreGenerateQueueJob {
  final String id;
  final Work work;
  final Files? files;
  final List<({Child audio, Child? subtitle})> pairs;
  final LoreGenerateKind kind;
  final bool includeSecrets;
  final String? trackKey;
  final String? characterId;
  LoreGenerateQueueJobStatus status;
  String progressStage;
  double progress;
  int attempts;
  String? lastError;
  final DateTime createdAt;
  final List<LoreGenerateTrackProgress> tracks;

  /// True while an LLM HTTP call is in flight (UI shows indeterminate pulse).
  bool waitingOnLlm;

  /// When the current stage / wait started (for elapsed seconds).
  DateTime? stageStartedAt;

  LoreGenerateQueueJob({
    required this.id,
    required this.work,
    required this.pairs,
    required this.kind,
    this.files,
    this.includeSecrets = true,
    this.trackKey,
    this.characterId,
    this.status = LoreGenerateQueueJobStatus.pending,
    this.progressStage = '',
    this.progress = 0,
    this.attempts = 0,
    this.lastError,
    this.waitingOnLlm = false,
    this.stageStartedAt,
    List<LoreGenerateTrackProgress>? tracks,
    DateTime? createdAt,
  })  : tracks = tracks ?? [],
        createdAt = createdAt ?? DateTime.now();

  String get workId => '${work.id ?? work.sourceId ?? 'unknown'}';
  String get workTitle => work.title ?? workId;

  int get tracksDone =>
      tracks.where((t) => t.status == LoreGenerateTrackStatus.done).length;
  int get tracksFailed =>
      tracks.where((t) => t.status == LoreGenerateTrackStatus.failed).length;

  bool get isActive =>
      status == LoreGenerateQueueJobStatus.pending ||
      status == LoreGenerateQueueJobStatus.running;

  bool get isFinished =>
      status == LoreGenerateQueueJobStatus.done ||
      status == LoreGenerateQueueJobStatus.failed ||
      status == LoreGenerateQueueJobStatus.cancelled;

  bool get hasPartialFailures =>
      status == LoreGenerateQueueJobStatus.done && tracksFailed > 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'work': work.toJson(),
        if (files != null) 'files': files!.toJson(),
        'pairs': [
          for (final p in pairs)
            {
              'audio': p.audio.toJson(),
              if (p.subtitle != null) 'subtitle': p.subtitle!.toJson(),
            },
        ],
        'kind': kind.name,
        'includeSecrets': includeSecrets,
        if (trackKey != null) 'trackKey': trackKey,
        if (characterId != null) 'characterId': characterId,
        'status': status.name,
        'progressStage': progressStage,
        'progress': progress,
        'attempts': attempts,
        'lastError': lastError,
        'createdAt': createdAt.toIso8601String(),
        'tracks': [for (final t in tracks) t.toJson()],
      };

  factory LoreGenerateQueueJob.fromJson(Map<String, dynamic> json) {
    final statusName = json['status'] as String? ?? 'pending';
    var status = LoreGenerateQueueJobStatus.values.firstWhere(
      (v) => v.name == statusName,
      orElse: () => LoreGenerateQueueJobStatus.pending,
    );
    if (status == LoreGenerateQueueJobStatus.running) {
      status = LoreGenerateQueueJobStatus.pending;
    }

    final kindName = json['kind'] as String? ?? 'fullGenerate';
    final kind = LoreGenerateKind.values.firstWhere(
      (v) => v.name == kindName,
      orElse: () => LoreGenerateKind.fullGenerate,
    );

    final pairsRaw = json['pairs'] as List? ?? const [];
    final pairs = <({Child audio, Child? subtitle})>[];
    for (final e in pairsRaw) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      final audio = Child.fromJson(Map<String, dynamic>.from(m['audio'] as Map));
      final subRaw = m['subtitle'];
      final subtitle = subRaw is Map
          ? Child.fromJson(Map<String, dynamic>.from(subRaw))
          : null;
      pairs.add((audio: audio, subtitle: subtitle));
    }

    final tracksRaw = json['tracks'] as List? ?? const [];
    final tracks = <LoreGenerateTrackProgress>[];
    for (final e in tracksRaw) {
      if (e is Map) {
        tracks.add(
          LoreGenerateTrackProgress.fromJson(Map<String, dynamic>.from(e)),
        );
      }
    }

    return LoreGenerateQueueJob(
      id: json['id'] as String,
      work: Work.fromJson(Map<String, dynamic>.from(json['work'] as Map)),
      files: json['files'] is Map
          ? Files.fromJson(Map<String, dynamic>.from(json['files'] as Map))
          : null,
      pairs: pairs,
      kind: kind,
      includeSecrets: json['includeSecrets'] as bool? ?? true,
      trackKey: json['trackKey'] as String?,
      characterId: json['characterId'] as String?,
      status: status,
      progressStage: json['progressStage'] as String? ?? '',
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      attempts: json['attempts'] as int? ?? 0,
      lastError: json['lastError'] as String?,
      tracks: tracks,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class LoreGenerateQueueSnapshot {
  final int totalJobs;
  final int completedJobs;
  final int failedJobs;
  final int runningJobs;
  final bool isActive;
  final String? currentWorkTitle;
  final String? progressStage;
  final double? progress;
  final bool waitingOnLlm;
  final DateTime? stageStartedAt;
  final int? tracksDone;
  final int? tracksTotal;

  const LoreGenerateQueueSnapshot({
    required this.totalJobs,
    required this.completedJobs,
    required this.failedJobs,
    required this.runningJobs,
    required this.isActive,
    this.currentWorkTitle,
    this.progressStage,
    this.progress,
    this.waitingOnLlm = false,
    this.stageStartedAt,
    this.tracksDone,
    this.tracksTotal,
  });
}
