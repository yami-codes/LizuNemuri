import 'package:xuro/core/audio/models/subtitle.dart';
import 'package:xuro/core/settings/llm_batch_split_mode.dart';

/// Computes subtitle batches for LLM translation requests.
class LlmBatchPlanner {
  static const defaultManualBatchSize = 25;
  static const defaultContextTokens = 128000;

  /// ~chars per token heuristic for CJK / mixed subtitle text.
  static const _charsPerToken = 3.5;

  /// Reserve headroom for system prompt, context block, and model output.
  static const _usableContextFraction = 0.35;

  static List<List<Subtitle>> planBatches({
    required List<Subtitle> subtitles,
    required LlmBatchSplitMode mode,
    required int manualBatchSize,
    int? providerContextTokens,
  }) {
    if (subtitles.isEmpty) return const [];

    switch (mode) {
      case LlmBatchSplitMode.none:
        return [List<Subtitle>.from(subtitles)];
      case LlmBatchSplitMode.manual:
        final size = manualBatchSize.clamp(1, 500);
        return _chunk(subtitles, size);
      case LlmBatchSplitMode.provider:
        final context = providerContextTokens ?? defaultContextTokens;
        final size = _estimateBatchSize(subtitles, context);
        return _chunk(subtitles, size);
    }
  }

  static int _estimateBatchSize(List<Subtitle> subtitles, int contextTokens) {
    final tokenBudget = (contextTokens * _usableContextFraction).floor();
    if (tokenBudget <= 0) return defaultManualBatchSize;

    final sample = subtitles.take(20).toList();
    final avgChars = sample.isEmpty
        ? 40.0
        : sample.map((s) => s.text.length).reduce((a, b) => a + b) /
            sample.length;

    // Input + expected translated output ≈ 2× line text.
    final tokensPerLine = ((avgChars * 2) / _charsPerToken).ceil().clamp(8, 200);
    final batch = (tokenBudget / tokensPerLine).floor();
    return batch.clamp(5, 120);
  }

  static List<List<Subtitle>> _chunk(List<Subtitle> items, int size) {
    final batches = <List<Subtitle>>[];
    for (var i = 0; i < items.length; i += size) {
      final end = (i + size).clamp(0, items.length);
      batches.add(items.sublist(i, end));
    }
    return batches;
  }
}
