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
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get workId => '${work.id ?? work.sourceId ?? 'unknown'}';
  String get workTitle => work.title ?? workId;

  bool get isActive =>
      status == LoreGenerateQueueJobStatus.pending ||
      status == LoreGenerateQueueJobStatus.running;

  bool get isFinished =>
      status == LoreGenerateQueueJobStatus.done ||
      status == LoreGenerateQueueJobStatus.failed ||
      status == LoreGenerateQueueJobStatus.cancelled;

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
      };

  factory LoreGenerateQueueJob.fromJson(Map<String, dynamic> json) {
    final statusName = json['status'] as String? ?? 'pending';
    var status = LoreGenerateQueueJobStatus.values.firstWhere(
      (v) => v.name == statusName,
      orElse: () => LoreGenerateQueueJobStatus.pending,
    );
    // Cold start: in-flight → pending (lore has no mid-job resume).
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

  const LoreGenerateQueueSnapshot({
    required this.totalJobs,
    required this.completedJobs,
    required this.failedJobs,
    required this.runningJobs,
    required this.isActive,
    this.currentWorkTitle,
    this.progressStage,
    this.progress,
  });
}
