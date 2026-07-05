/// Phase of an in-flight LLM subtitle translation (single track).
enum SubtitleTranslationPhase {
  checkingCache,
  loading,
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

  const SubtitleTranslationProgress({
    required this.phase,
    this.batchIndex,
    this.batchTotal,
  });
}

typedef SubtitleTranslationProgressCallback = void Function(
  SubtitleTranslationProgress progress,
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
