import 'package:lizunemu/core/audio/models/subtitle.dart';
import 'package:lizunemu/data/services/exceptions/llm_translation_exception.dart';

/// Outcome of an LLM subtitle translation attempt.
class SubtitleTranslationResult {
  final SubtitleList list;
  final bool translated;
  final bool fromCache;
  final LlmTranslationException? error;
  final bool skipped;

  const SubtitleTranslationResult._({
    required this.list,
    this.translated = false,
    this.fromCache = false,
    this.error,
    this.skipped = false,
  });

  factory SubtitleTranslationResult.success(
    SubtitleList list, {
    required bool translated,
    bool fromCache = false,
  }) =>
      SubtitleTranslationResult._(
        list: list,
        translated: translated,
        fromCache: fromCache,
      );

  factory SubtitleTranslationResult.skipped(SubtitleList source) =>
      SubtitleTranslationResult._(list: source, skipped: true);

  factory SubtitleTranslationResult.failure(
    SubtitleList source,
    LlmTranslationException error,
  ) =>
      SubtitleTranslationResult._(list: source, error: error);

  bool get isFailure => error != null;
}
