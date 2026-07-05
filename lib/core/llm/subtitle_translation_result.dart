import 'package:lizunemu/core/audio/models/subtitle.dart';
import 'package:lizunemu/data/services/exceptions/llm_translation_exception.dart';

/// Outcome of an LLM subtitle translation attempt.
class SubtitleTranslationResult {
  final SubtitleList list;
  final bool translated;
  final bool fromCache;
  final bool partial;
  final int? translatedCount;
  final int? totalCount;
  final LlmTranslationException? error;
  final bool skipped;

  const SubtitleTranslationResult._({
    required this.list,
    this.translated = false,
    this.fromCache = false,
    this.partial = false,
    this.translatedCount,
    this.totalCount,
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

  /// Translation stopped early but [list] carries usable partial lines.
  factory SubtitleTranslationResult.partial(
    SubtitleList list, {
    required int translatedCount,
    required int totalCount,
    LlmTranslationException? error,
  }) =>
      SubtitleTranslationResult._(
        list: list,
        translated: translatedCount > 0,
        partial: true,
        translatedCount: translatedCount,
        totalCount: totalCount,
        error: error,
      );

  bool get isFailure => error != null && !partial;
  bool get isPartial => partial;
}
