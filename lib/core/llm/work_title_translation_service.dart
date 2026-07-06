import 'package:lizunemu/core/translation/metadata_translation_service.dart';
import 'package:lizunemu/data/services/exceptions/llm_translation_exception.dart';

/// Result of translating a work title.
class WorkTitleTranslationResult {
  final String? title;
  final bool fromCache;
  final LlmTranslationException? error;

  const WorkTitleTranslationResult._({
    this.title,
    this.fromCache = false,
    this.error,
  });

  factory WorkTitleTranslationResult.success(
    String title, {
    bool fromCache = false,
  }) =>
      WorkTitleTranslationResult._(title: title, fromCache: fromCache);

  factory WorkTitleTranslationResult.failure(LlmTranslationException error) =>
      WorkTitleTranslationResult._(error: error);

  bool get isFailure => error != null;
}

/// Work title translation — delegates to [MetadataTranslationService].
class WorkTitleTranslationService {
  final MetadataTranslationService _metadata;

  WorkTitleTranslationService({required MetadataTranslationService metadata})
      : _metadata = metadata;

  Future<bool> isCached({
    required String workId,
    required String sourceTitle,
  }) async {
    final cached = await _metadata.cachedWorkTitle(
      workId: workId,
      sourceTitle: sourceTitle,
    );
    return cached != null;
  }

  Future<String?> cachedTitle({
    required String workId,
    required String sourceTitle,
  }) =>
      _metadata.cachedWorkTitle(
        workId: workId,
        sourceTitle: sourceTitle,
      );

  Future<WorkTitleTranslationResult> translate({
    required String workId,
    required String sourceTitle,
    bool forceRefresh = false,
  }) async {
    final source = sourceTitle.trim();
    if (source.isEmpty) {
      return WorkTitleTranslationResult.failure(
        const LlmTranslationException(
          LlmTranslationErrorType.invalidConfig,
          'empty title',
        ),
      );
    }

    if (!forceRefresh) {
      final cached = await _metadata.cachedWorkTitle(
        workId: workId,
        sourceTitle: source,
      );
      if (cached != null) {
        return WorkTitleTranslationResult.success(cached, fromCache: true);
      }
    }

    try {
      final translated = await _metadata.translateWorkTitle(
        workId: workId,
        sourceTitle: source,
        forceRefresh: forceRefresh,
      );
      if (translated == null || translated.isEmpty) {
        return WorkTitleTranslationResult.failure(
          const LlmTranslationException(
            LlmTranslationErrorType.invalidResponse,
            'empty title',
          ),
        );
      }
      return WorkTitleTranslationResult.success(translated);
    } on LlmTranslationException catch (e) {
      return WorkTitleTranslationResult.failure(e);
    } catch (e) {
      return WorkTitleTranslationResult.failure(
        LlmTranslationException(LlmTranslationErrorType.unknown, e.toString()),
      );
    }
  }
}
