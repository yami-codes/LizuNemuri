import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:lizunemu/core/llm/streaming_metadata_parser.dart';
import 'package:lizunemu/core/llm/llm_usage.dart';
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

typedef MetadataPartialCallback = void Function(String id, String text);

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

  static const _liteStreamingSystemPrompt = '''
You are a professional translator for ASMR audio catalog metadata.
Translate each item naturally into the target language.
Preserve catalog numbers (RJ codes), episode/chapter numbers, and file extensions.
Return one JSON object per line (NDJSON), each on its own line:
{"id":"<id>","text":"translated text"}
Do not wrap in markdown fences. Do not return a JSON array wrapper.''';

  static const _googleChunkSize = 12;
  static const _llmChunkSize = 24;

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
  Future<Map<String, String>> translateWorkTitles(
    List<Work> works, {
    MetadataPartialCallback? onPartial,
  }) async {
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
        onPartial?.call(id, cached);
      } else {
        pending.add(_PendingItem(id: id, source: source));
      }
    }

    if (pending.isEmpty) return result;

    await _translateAndPersistBatch(
      scope: _workTitleScope,
      entityIdFor: (id) => id,
      pending: pending,
      userHint: 'ASMR work titles',
      onPartial: (id, text) {
        result[id] = text;
        onPartial?.call(id, text);
      },
    );
    return result;
  }

  /// Translate a single work title (detail page).
  Future<String?> translateWorkTitle({
    required String workId,
    required String sourceTitle,
    bool forceRefresh = false,
    MetadataPartialCallback? onPartial,
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
      if (cached != null) {
        onPartial?.call(workId, cached);
        return cached;
      }
    }

    final pending = [_PendingItem(id: workId, source: source)];
    final map = <String, String>{};
    await _translateAndPersistBatch(
      scope: _workTitleScope,
      entityIdFor: (id) => id,
      pending: pending,
      userHint: 'ASMR work title',
      onPartial: (id, text) {
        map[id] = text;
        onPartial?.call(id, text);
      },
    );
    return map[workId];
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
    MetadataPartialCallback? onPartial,
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
        onPartial?.call(entry.key, cached);
      } else {
        pending.add(_PendingItem(id: entry.key, source: source));
      }
    }

    if (pending.isEmpty) return result;

    await _translateAndPersistBatch(
      scope: _trackNameScope,
      entityIdFor: (fileKey) => '$workId|$fileKey',
      pending: pending,
      userHint: 'ASMR audio track / file names',
      onPartial: (fileKey, text) {
        result[fileKey] = text;
        onPartial?.call(fileKey, text);
      },
    );
    return result;
  }

  Future<void> _translateAndPersistBatch({
    required String scope,
    required String Function(String id) entityIdFor,
    required List<_PendingItem> pending,
    required String userHint,
    required MetadataPartialCallback onPartial,
  }) async {
    final sourceById = {for (final p in pending) p.id: p.source};
    final translated = await _translateBatch(
      pending,
      userHint: userHint,
      onPartial: onPartial,
    );

    for (final entry in translated.entries) {
      final source = sourceById[entry.key];
      if (source == null) continue;
      await _cache.save(
        scope: scope,
        entityId: entityIdFor(entry.key),
        targetLang: _targetLang,
        sourceText: source,
        translatedText: entry.value,
      );
    }
  }

  Future<Map<String, String>> _translateBatch(
    List<_PendingItem> items, {
    required String userHint,
    MetadataPartialCallback? onPartial,
  }) async {
    if (items.isEmpty) return {};

    switch (provider) {
      case MetadataTranslationProvider.google:
        return _translateBatchGoogle(items, onPartial: onPartial);
      case MetadataTranslationProvider.llm:
        return _translateBatchLlm(items, userHint: userHint, onPartial: onPartial);
    }
  }

  Future<Map<String, String>> _translateBatchGoogle(
    List<_PendingItem> items, {
    MetadataPartialCallback? onPartial,
  }) async {
    final result = <String, String>{};

    for (var start = 0; start < items.length; start += _googleChunkSize) {
      final end = start + _googleChunkSize > items.length
          ? items.length
          : start + _googleChunkSize;
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
            onPartial?.call(chunk[i].id, text);
          }
        }
      } catch (e) {
        AppLogger.warning(
          'Google metadata batch chunk failed, falling back sequential: $e',
        );
        await _translateGoogleSequential(
          chunk,
          result: result,
          onPartial: onPartial,
        );
      }

      // Defense in depth: empty/partial chunk (e.g. legacy multi-q parse) →
      // retry missing ids one-by-one.
      final missing = chunk.where((item) => !result.containsKey(item.id)).toList();
      if (missing.isNotEmpty) {
        AppLogger.warning(
          'Google metadata chunk incomplete '
          '(${chunk.length - missing.length}/${chunk.length}), '
          'retrying ${missing.length} sequentially',
        );
        await _translateGoogleSequential(
          missing,
          result: result,
          onPartial: onPartial,
        );
      }
    }
    return result;
  }

  Future<void> _translateGoogleSequential(
    List<_PendingItem> items, {
    required Map<String, String> result,
    MetadataPartialCallback? onPartial,
  }) async {
    for (final item in items) {
      try {
        final text = await _google.translate(
          text: item.source,
          targetLang: _targetLang,
        );
        if (text.trim().isNotEmpty) {
          result[item.id] = text.trim();
          onPartial?.call(item.id, text.trim());
        }
      } catch (inner) {
        AppLogger.warning('Google metadata single failed: $inner');
      }
    }
  }

  Future<Map<String, String>> _translateBatchLlm(
    List<_PendingItem> items, {
    required String userHint,
    MetadataPartialCallback? onPartial,
  }) async {
    final result = <String, String>{};
    final key = await _apiKeyRepo.getApiKey();
    if (key == null || key.trim().isEmpty) {
      AppLogger.warning(
        'LLM metadata translate skipped (no API key) — falling back to Google',
      );
      return _translateBatchGoogle(items, onPartial: onPartial);
    }

    for (var start = 0; start < items.length; start += _llmChunkSize) {
      final end =
          start + _llmChunkSize > items.length ? items.length : start + _llmChunkSize;
      final chunk = items.sublist(start, end);
      try {
        final chunkResult = await _translateLlmChunk(
          chunk,
          userHint: userHint,
          onPartial: onPartial,
        );
        result.addAll(chunkResult);
      } on LlmTranslationException catch (e) {
        AppLogger.warning('LLM metadata chunk failed ($e) — trying Google');
        final google = await _translateBatchGoogle(chunk, onPartial: onPartial);
        result.addAll(google);
        if (google.isEmpty) rethrow;
      } catch (e) {
        AppLogger.warning('LLM metadata chunk error ($e) — trying Google');
        final google = await _translateBatchGoogle(chunk, onPartial: onPartial);
        result.addAll(google);
        if (google.isEmpty) rethrow;
      }
    }
    return result;
  }

  Future<Map<String, String>> _translateLlmChunk(
    List<_PendingItem> items, {
    required String userHint,
    MetadataPartialCallback? onPartial,
  }) async {
    final payload = jsonEncode([
      for (final item in items) {'id': item.id, 'text': item.source},
    ]);

    final messages = [
      {
        'role': 'system',
        'content': _settings.llmStreamingEnabled
            ? _liteStreamingSystemPrompt
            : _liteSystemPrompt,
      },
      {
        'role': 'user',
        'content':
            'Target language: $_targetLang\nContext: $userHint\nTranslate these items:\n$payload',
      },
    ];

    final result = <String, String>{};
    LlmUsage? usage;

    if (_settings.llmStreamingEnabled) {
      final parser = StreamingMetadataParser();
      await for (final chunk in _llm.chatCompletionStream(
        modelSlot: LlmModelSlot.lite,
        messages: messages,
        temperature: 0.2,
        onUsage: (u) => usage = u,
      )) {
        for (final entry in parser.feed(chunk)) {
          result[entry.key] = entry.value;
          onPartial?.call(entry.key, entry.value);
        }
      }
      for (final entry in parser.flush()) {
        result[entry.key] = entry.value;
        onPartial?.call(entry.key, entry.value);
      }
    } else {
      final response = await _llm.chatCompletionWithUsage(
        modelSlot: LlmModelSlot.lite,
        messages: messages,
        temperature: 0.2,
      );
      usage = response.usage;
      final parsed = _parseLlmBatchResponse(response.content, items);
      result.addAll(parsed);
      for (final entry in parsed.entries) {
        onPartial?.call(entry.key, entry.value);
      }
    }

    final recordedUsage = usage;
    if (recordedUsage != null) {
      final repo = _usageRepo;
      if (repo != null) {
        await repo.record(
          model: _settings.llmLiteModel,
          operation: 'metadata_translate',
          usage: recordedUsage,
        );
      }
    }

    if (result.isEmpty) {
      throw const LlmTranslationException(
        LlmTranslationErrorType.invalidResponse,
        'empty metadata LLM response',
      );
    }
    return result;
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
