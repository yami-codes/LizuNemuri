import 'package:xuro/core/llm/work_title_translation_cache.dart';
import 'package:xuro/core/settings/app_settings_service.dart';
import 'package:xuro/core/settings/llm_subtitle_target_language.dart';
import 'package:xuro/data/repositories/llm_api_key_repository.dart';
import 'package:xuro/data/services/exceptions/llm_translation_exception.dart';
import 'package:xuro/data/services/llm_client.dart';
import 'package:xuro/utils/logger.dart';

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

/// LLM translation for a single work/project title (cached per work + lang).
class WorkTitleTranslationService {
  static const _systemPrompt = '''
You are a professional translator for ASMR audio work titles.
Translate the given title naturally into the target language.
Preserve catalog numbers (RJ codes), episode numbers, and proper nouns when appropriate.
Return ONLY the translated title text — no quotes, labels, or explanation.''';

  final AppSettingsService _settings;
  final LlmClient _client;
  final LlmApiKeyRepository _apiKeyRepo;
  final WorkTitleTranslationCache _cache;

  WorkTitleTranslationService({
    required AppSettingsService settings,
    required LlmClient client,
    required LlmApiKeyRepository apiKeyRepo,
    WorkTitleTranslationCache? cache,
  })  : _settings = settings,
        _client = client,
        _apiKeyRepo = apiKeyRepo,
        _cache = cache ?? WorkTitleTranslationCache();

  String get _targetLang =>
      _settings.llmTargetLanguage.resolveCode(_settings.stringsLocale);

  Future<bool> isCached({
    required String workId,
    required String sourceTitle,
  }) async {
    if (sourceTitle.trim().isEmpty) return false;
    final cached = await _cache.load(
      workId: workId,
      targetLang: _targetLang,
      sourceTitle: sourceTitle,
    );
    return cached != null;
  }

  Future<String?> cachedTitle({
    required String workId,
    required String sourceTitle,
  }) =>
      _cache.load(
        workId: workId,
        targetLang: _targetLang,
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
      final cached = await _cache.load(
        workId: workId,
        targetLang: _targetLang,
        sourceTitle: source,
      );
      if (cached != null) {
        return WorkTitleTranslationResult.success(cached, fromCache: true);
      }
    }

    final key = await _apiKeyRepo.getApiKey();
    if (key == null || key.trim().isEmpty) {
      return WorkTitleTranslationResult.failure(
        const LlmTranslationException(
          LlmTranslationErrorType.missingApiKey,
          'missing api key',
        ),
      );
    }

    try {
      final response = await _client.chatCompletion(
        messages: [
          {'role': 'system', 'content': _systemPrompt},
          {
            'role': 'user',
            'content': 'Translate this ASMR work title to $_targetLang:\n$source',
          },
        ],
      );
      final translated = response.trim();
      if (translated.isEmpty) {
        return WorkTitleTranslationResult.failure(
          const LlmTranslationException(
            LlmTranslationErrorType.invalidResponse,
            'empty title',
          ),
        );
      }
      await _cache.save(
        workId: workId,
        targetLang: _targetLang,
        sourceTitle: source,
        translatedTitle: translated,
      );
      return WorkTitleTranslationResult.success(translated);
    } on LlmTranslationException catch (e) {
      AppLogger.warning('Work title translation failed: ${e.message}');
      return WorkTitleTranslationResult.failure(e);
    } catch (e, st) {
      AppLogger.error('Work title translation failed', e, st);
      return WorkTitleTranslationResult.failure(
        LlmTranslationException(LlmTranslationErrorType.unknown, e.toString()),
      );
    }
  }
}
