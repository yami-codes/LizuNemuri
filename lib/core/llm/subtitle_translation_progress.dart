import 'package:lizunemu/core/audio/models/subtitle.dart';

/// Phase of an in-flight LLM subtitle translation (single track).
enum SubtitleTranslationPhase {
  checkingCache,
  loading,
  resuming,
  translating,
  saving,
  cached,
  done,
}

/// Progress update for one track's LLM translation.
class SubtitleTranslationProgress {
  final SubtitleTranslationPhase phase;
  final int? batchIndex;
  final int? batchTotal;
  final int? linesTranslated;
  final int? linesTotal;

  const SubtitleTranslationProgress({
    required this.phase,
    this.batchIndex,
    this.batchTotal,
    this.linesTranslated,
    this.linesTotal,
  });
}

typedef SubtitleTranslationProgressCallback = void Function(
  SubtitleTranslationProgress progress,
);

/// Called when streaming translation produces new lines (may fire many times).
typedef SubtitlePartialTranslationCallback = void Function(
  SubtitleList partialList,
  int translatedCount,
  int totalCount,
);

/// Phase while translating multiple tracks on a work detail page.
enum BatchTranslatePhase {
  loadingSubtitle,
  checkingCache,
  translating,
  cached,
  failed,
}

/// Progress for bulk translate on a work.
class BatchTranslateProgress {
  final int index;
  final int total;
  final String trackName;
  final BatchTranslatePhase phase;
  final int? llmBatchIndex;
  final int? llmBatchTotal;

  const BatchTranslateProgress({
    required this.index,
    required this.total,
    required this.trackName,
    required this.phase,
    this.llmBatchIndex,
    this.llmBatchTotal,
  });
}

typedef BatchTranslateProgressCallback = void Function(
  BatchTranslateProgress progress,
);
