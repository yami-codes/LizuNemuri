import 'package:lizunemu/data/models/files/child.dart';
import 'package:lizunemu/data/models/files/files.dart';
import 'package:lizunemu/data/models/works/work.dart';
import 'package:lizunemu/core/llm/subtitle_translation_progress.dart';

/// Lifecycle of one track in the background translation queue.
enum TranslationQueueTrackStatus {
  pending,
  running,
  done,
  cached,
  failed,
  cancelled,
}

/// One enqueued work batch (shared work/files tree + track list).
class TranslationQueueJob {
  final String id;
  final Work work;
  final Files files;
  final List<TranslationQueueTrack> tracks;
  final DateTime createdAt;

  TranslationQueueJob({
    required this.id,
    required this.work,
    required this.files,
    required this.tracks,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get workId => work.id?.toString() ?? 'unknown';
  String get workTitle => work.title ?? workId;

  int get pendingCount => tracks
      .where((t) =>
          t.status == TranslationQueueTrackStatus.pending ||
          t.status == TranslationQueueTrackStatus.running)
      .length;

  int get doneCount => tracks
      .where((t) =>
          t.status == TranslationQueueTrackStatus.done ||
          t.status == TranslationQueueTrackStatus.cached)
      .length;

  int get failedCount => tracks
      .where((t) => t.status == TranslationQueueTrackStatus.failed)
      .length;

  bool get isFinished => tracks.every((t) =>
      t.status == TranslationQueueTrackStatus.done ||
      t.status == TranslationQueueTrackStatus.cached ||
      t.status == TranslationQueueTrackStatus.failed ||
      t.status == TranslationQueueTrackStatus.cancelled);

  Map<String, dynamic> toJson() => {
        'id': id,
        'work': work.toJson(),
        'files': files.toJson(),
        'tracks': tracks.map((t) => t.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory TranslationQueueJob.fromJson(Map<String, dynamic> json) {
    return TranslationQueueJob(
      id: json['id'] as String,
      work: Work.fromJson(Map<String, dynamic>.from(json['work'] as Map)),
      files: Files.fromJson(Map<String, dynamic>.from(json['files'] as Map)),
      tracks: (json['tracks'] as List)
          .map((e) => TranslationQueueTrack.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class TranslationQueueTrack {
  final String id;
  final Child audio;
  final Child subtitle;
  TranslationQueueTrackStatus status;
  int attempts;
  String? lastError;
  BatchTranslatePhase? phase;
  int? llmBatchIndex;
  int? llmBatchTotal;

  TranslationQueueTrack({
    required this.id,
    required this.audio,
    required this.subtitle,
    this.status = TranslationQueueTrackStatus.pending,
    this.attempts = 0,
    this.lastError,
    this.phase,
    this.llmBatchIndex,
    this.llmBatchTotal,
  });

  String get trackName => audio.title ?? id;

  Map<String, dynamic> toJson() => {
        'id': id,
        'audio': audio.toJson(),
        'subtitle': subtitle.toJson(),
        'status': status.name,
        'attempts': attempts,
        'lastError': lastError,
      };

  factory TranslationQueueTrack.fromJson(Map<String, dynamic> json) {
    final statusName = json['status'] as String? ?? 'pending';
    final status = TranslationQueueTrackStatus.values.firstWhere(
      (v) => v.name == statusName,
      orElse: () => TranslationQueueTrackStatus.pending,
    );
    // Running at persist time becomes pending so cold-start can resume.
    final restored = status == TranslationQueueTrackStatus.running
        ? TranslationQueueTrackStatus.pending
        : status;
    return TranslationQueueTrack(
      id: json['id'] as String,
      audio: Child.fromJson(Map<String, dynamic>.from(json['audio'] as Map)),
      subtitle:
          Child.fromJson(Map<String, dynamic>.from(json['subtitle'] as Map)),
      status: restored,
      attempts: json['attempts'] as int? ?? 0,
      lastError: json['lastError'] as String?,
    );
  }
}

/// Aggregate snapshot for mini indicator / notifications.
class TranslationQueueSnapshot {
  final int totalTracks;
  final int completedTracks;
  final int failedTracks;
  final int runningTracks;
  final String? currentTrackName;
  final String? currentWorkTitle;
  final BatchTranslatePhase? phase;
  final int? llmBatchIndex;
  final int? llmBatchTotal;
  final bool isActive;

  const TranslationQueueSnapshot({
    required this.totalTracks,
    required this.completedTracks,
    required this.failedTracks,
    required this.runningTracks,
    required this.isActive,
    this.currentTrackName,
    this.currentWorkTitle,
    this.phase,
    this.llmBatchIndex,
    this.llmBatchTotal,
  });

  double? get progress {
    if (totalTracks <= 0) return null;
    return completedTracks / totalTracks;
  }
}
