import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:lizunemu/core/settings/app_settings_service.dart';
import 'package:lizunemu/core/settings/llm_model_slot.dart';
import 'package:lizunemu/core/settings/llm_subtitle_target_language.dart';
import 'package:lizunemu/core/settings/metadata_translation_provider.dart';
import 'package:lizunemu/core/translation/metadata_translation_cache.dart';
import 'package:lizunemu/data/models/works/work.dart';
import 'package:lizunemu/data/repositories/llm_api_key_repository.dart';
import 'package:lizunemu/data/repositories/llm_usage_repository.dart';
import 'package:lizunemu/data/services/exceptions/llm_translation_exception.dart';
import 'package:lizunemu/data/services/google_translate_client.dart';
import 'package:lizunemu/data/services/llm_client.dart';
import 'package:lizunemu/utils/logger.dart';

/// Translates short metadata (work titles, track names) via Google or LLM Lite.
class MetadataTranslationService {
  static const _workTitleScope = 'work_title';
  static const _trackNameScope = 'track_name';

  static const _liteSystemPrompt = '''
You are a professional translator for ASMR audio catalog metadata.
Translate each item naturally into the target language.
Preserve catalog numbers (RJ codes), episode/chapter numbers, and file extensions.
Return ONLY a JSON array with one object per input item in the same order:
{"id":"<id>","text":"translated text"}
Do not wrap in markdown fences.''';

  final AppSettingsService _settings;
  final GoogleTranslateClient _google;
  final LlmClient _llm;
  final LlmApiKeyRepository _apiKeyRepo;
  final MetadataTranslationCache _cache;
  final LlmUsageRepository? _usageRepo;

  MetadataTranslationService({
    required AppSettingsService settings,
    GoogleTranslateClient? google,
    required LlmClient llm,
    required LlmApiKeyRepository apiKeyRepo,
    MetadataTranslationCache? cache,
    LlmUsageRepository? usageRepo,
  })  : _settings = settings,
        _google = google ?? GoogleTranslateClient(),
        _llm = llm,
        _apiKeyRepo = apiKeyRepo,
        _cache = cache ?? MetadataTranslationCache(),
        _usageRepo = usageRepo;

  bool get isEnabled => _settings.metadataTranslationEnabled;

  String get _targetLang =>
      _settings.llmTargetLanguage.resolveCode(_settings.stringsLocale);

  MetadataTranslationProvider get provider =>
      _settings.metadataTranslationProvider;

  /// Bulk-translate work titles for a list page. Returns workId → translated title.
  Future<Map<String, String>> translateWorkTitles(List<Work> works) async {
    if (!isEnabled || works.isEmpty) return {};

    final pending = <_PendingItem>[];
    final result = <String, String>{};

    for (final work in works) {
      final id = work.id?.toString();
      final source = work.title?.trim();
      if (id == null || source == null || source.isEmpty) continue;

      final cached = await _cache.load(
        scope: _workTitleScope,
        entityId: id,
        targetLang: _targetLang,
        sourceText: source,
      );
      if (cached != null) {
        result[id] = cached;
      } else {
        pending.add(_PendingItem(id: id, source: source));
      }
    }

    if (pending.isEmpty) return result;

    final translated = await _translateBatch(
      pending,
      userHint: 'ASMR work titles',
    );
    for (final entry in translated.entries) {
      result[entry.key] = entry.value;
      final source = pending.firstWhere((p) => p.id == entry.key).source;
      await _cache.save(
        scope: _workTitleScope,
        entityId: entry.key,
        targetLang: _targetLang,
        sourceText: source,
        translatedText: entry.value,
      );
    }
    return result;
  }

  /// Translate a single work title (detail page).
  Future<String?> translateWorkTitle({
    required String workId,
    required String sourceTitle,
    bool forceRefresh = false,
  }) async {
    final source = sourceTitle.trim();
    if (source.isEmpty) return null;

    if (!forceRefresh) {
      final cached = await _cache.load(
        scope: _workTitleScope,
        entityId: workId,
        targetLang: _targetLang,
        sourceText: source,
      );
      if (cached != null) return cached;
    }

    final map = await _translateBatch(
      [_PendingItem(id: workId, source: source)],
      userHint: 'ASMR work title',
    );
    final translated = map[workId];
    if (translated != null) {
      await _cache.save(
        scope: _workTitleScope,
        entityId: workId,
        targetLang: _targetLang,
        sourceText: source,
        translatedText: translated,
      );
    }
    return translated;
  }

  Future<String?> cachedWorkTitle({
    required String workId,
    required String sourceTitle,
  }) =>
      _cache.load(
        scope: _workTitleScope,
        entityId: workId,
        targetLang: _targetLang,
        sourceText: sourceTitle,
      );

  /// Bulk-translate track/file display names under a work.
  Future<Map<String, String>> translateTrackNames({
    required String workId,
    required Map<String, String> fileKeyToTitle,
    bool force = false,
  }) async {
    if (!force && !isEnabled) return {};
    if (fileKeyToTitle.isEmpty) return {};

    final pending = <_PendingItem>[];
    final result = <String, String>{};

    for (final entry in fileKeyToTitle.entries) {
      final source = entry.value.trim();
      if (source.isEmpty) continue;
      final entityId = '$workId|${entry.key}';

      final cached = await _cache.load(
        scope: _trackNameScope,
        entityId: entityId,
        targetLang: _targetLang,
        sourceText: source,
      );
      if (cached != null) {
        result[entry.key] = cached;
      } else {
        pending.add(_PendingItem(id: entry.key, source: source));
      }
    }

    if (pending.isEmpty) return result;

    final translated = await _translateBatch(
      pending,
      userHint: 'ASMR audio track / file names',
    );

    for (final entry in translated.entries) {
      result[entry.key] = entry.value;
      final source = pending.firstWhere((p) => p.id == entry.key).source;
      await _cache.save(
        scope: _trackNameScope,
        entityId: '$workId|${entry.key}',
        targetLang: _targetLang,
        sourceText: source,
        translatedText: entry.value,
      );
    }
    return result;
  }

  Future<Map<String, String>> _translateBatch(
    List<_PendingItem> items, {
    required String userHint,
  }) async {
    if (items.isEmpty) return {};

    switch (provider) {
      case MetadataTranslationProvider.google:
        return _translateBatchGoogle(items);
      case MetadataTranslationProvider.llm:
        return _translateBatchLlm(items, userHint: userHint);
    }
  }

  Future<Map<String, String>> _translateBatchGoogle(
    List<_PendingItem> items,
  ) async {
    final result = <String, String>{};
    const chunkSize = 12;

    for (var start = 0; start < items.length; start += chunkSize) {
      final end = start + chunkSize > items.length ? items.length : start + chunkSize;
      final chunk = items.sublist(start, end);
      try {
        final texts = chunk.map((e) => e.source).toList();
        final translated = await _google.translateBatch(
          texts: texts,
          targetLang: _targetLang,
        );
        for (var i = 0; i < chunk.length; i++) {
          final text = i < translated.length ? translated[i].trim() : '';
          if (text.isNotEmpty) {
            result[chunk[i].id] = text;
          }
        }
      } catch (e) {
        AppLogger.warning(
          'Google metadata batch chunk failed, falling back sequential: $e',
        );
        for (final item in chunk) {
          try {
            final text = await _google.translate(
              text: item.source,
              targetLang: _targetLang,
            );
            if (text.trim().isNotEmpty) {
              result[item.id] = text.trim();
            }
          } catch (inner) {
            AppLogger.warning('Google metadata single failed: $inner');
          }
        }
      }
    }
    return result;
  }

  Future<Map<String, String>> _translateBatchLlm(
    List<_PendingItem> items, {
    required String userHint,
  }) async {
    final key = await _apiKeyRepo.getApiKey();
    if (key == null || key.trim().isEmpty) {
      AppLogger.warning(
        'LLM metadata translate skipped (no API key) — falling back to Google',
      );
      return _translateBatchGoogle(items);
    }

    try {
      final payload = jsonEncode([
        for (final item in items) {'id': item.id, 'text': item.source},
      ]);

      final result = await _llm.chatCompletionWithUsage(
        modelSlot: LlmModelSlot.lite,
        messages: [
          {'role': 'system', 'content': _liteSystemPrompt},
          {
            'role': 'user',
            'content':
                'Target language: $_targetLang\nContext: $userHint\nTranslate these items:\n$payload',
          },
        ],
        temperature: 0.2,
      );

      if (result.usage != null && _usageRepo != null) {
        await _usageRepo.record(
          model: _settings.llmLiteModel,
          operation: 'metadata_translate',
          usage: result.usage!,
        );
      }

      return _parseLlmBatchResponse(result.content, items);
    } on LlmTranslationException catch (e) {
      AppLogger.warning('LLM metadata batch failed ($e) — trying Google');
      final google = await _translateBatchGoogle(items);
      if (google.isNotEmpty) return google;
      rethrow;
    } catch (e) {
      AppLogger.warning('LLM metadata batch error ($e) — trying Google');
      final google = await _translateBatchGoogle(items);
      if (google.isNotEmpty) return google;
      rethrow;
    }
  }

  @visibleForTesting
  static Map<String, String> parseLlmBatchResponse(
    String raw,
    List<({String id, String source})> items,
  ) {
    final pending = [
      for (final item in items) _PendingItem(id: item.id, source: item.source),
    ];
    return _parseLlmBatchResponse(raw, pending);
  }

  static Map<String, String> _parseLlmBatchResponse(
    String raw,
    List<_PendingItem> items,
  ) {
    final rows = LlmClient.parseJsonArrayResponse(raw);
    final result = <String, String>{};
    for (final row in rows) {
      final id = row['id']?.toString();
      final text = row['text']?.toString().trim();
      if (id != null && text != null && text.isNotEmpty) {
        result[id] = text;
      }
    }

    if (result.length == items.length) return result;

    // Positional fallback when model omitted ids.
    if (result.isEmpty && rows.length == items.length) {
      for (var i = 0; i < items.length; i++) {
        final text = rows[i]['text']?.toString().trim() ??
            rows[i]['translation']?.toString().trim();
        if (text != null && text.isNotEmpty) {
          result[items[i].id] = text;
        }
      }
    }
    return result;
  }
}

class _PendingItem {
  final String id;
  final String source;

  const _PendingItem({required this.id, required this.source});
}
