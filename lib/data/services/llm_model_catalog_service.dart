import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:lizunemu/core/llm/llm_endpoint_utils.dart';
import 'package:lizunemu/core/settings/llm_provider_kind.dart';
import 'package:lizunemu/data/models/llm/llm_model_option.dart';
import 'package:lizunemu/utils/logger.dart';

/// Fetches model lists for autocomplete (OpenRouter, Gemini, OpenAI, custom).
class LlmModelCatalogService {
  final Dio _dio;

  final Map<String, _CacheEntry> _cache = {};
  static const _cacheTtl = Duration(minutes: 10);

  LlmModelCatalogService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 30),
            ));

  Future<List<LlmModelOption>> searchModels({
    required String endpoint,
    required String apiKey,
    required String query,
    int limit = 20,
  }) async {
    final kind = LlmEndpointUtils.detect(endpoint);
    if (kind == LlmProviderKind.custom) {
      return _searchCustom(endpoint: endpoint, apiKey: apiKey, query: query, limit: limit);
    }

    final q = query.trim().toLowerCase();
    List<LlmModelOption> all;
    try {
      all = await _loadCatalog(
        endpoint: endpoint,
        apiKey: apiKey,
        kind: kind,
      );
    } catch (e) {
      AppLogger.warning('LlmModelCatalogService load failed: $e');
      return const [];
    }

    if (q.isEmpty) return all.take(limit).toList();

    final scored = <({LlmModelOption option, int score})>[];
    for (final option in all) {
      final score = _matchScore(option, q);
      if (score > 0) scored.add((option: option, score: score));
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(limit).map((e) => e.option).toList();
  }

  static int _matchScore(LlmModelOption option, String q) {
    final id = option.id.toLowerCase();
    final name = option.name?.toLowerCase() ?? '';
    if (id == q || name == q) return 100;
    if (id.startsWith(q) || name.startsWith(q)) return 80;
    if (id.contains(q) || name.contains(q)) return 50;
    if (option.description?.toLowerCase().contains(q) == true) return 30;
    return 0;
  }

  Future<List<LlmModelOption>> _loadCatalog({
    required String endpoint,
    required String apiKey,
    required LlmProviderKind kind,
  }) async {
    final cacheKey = '${kind.name}:${LlmEndpointUtils.normalize(endpoint)}';
    final cached = _cache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.fetchedAt) < _cacheTtl) {
      return cached.models;
    }

    final List<LlmModelOption> models = switch (kind) {
      LlmProviderKind.openRouter => await _fetchOpenRouter(endpoint, apiKey),
      LlmProviderKind.gemini => await _fetchGemini(endpoint, apiKey),
      LlmProviderKind.openAi => await _fetchOpenAi(endpoint, apiKey),
      LlmProviderKind.custom => const <LlmModelOption>[],
    };

    _cache[cacheKey] = _CacheEntry(models, DateTime.now());
    return models;
  }

  Future<List<LlmModelOption>> _fetchOpenRouter(
    String endpoint,
    String apiKey,
  ) async {
    final base = LlmEndpointUtils.normalize(endpoint);
    final headers = <String, String>{};
    if (apiKey.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${apiKey.trim()}';
    }
    headers['HTTP-Referer'] = 'https://github.com/yami-codes/LizuNemu';
    headers['X-Title'] = 'Lizunemu';

    final response = await _dio.get<Map<String, dynamic>>(
      '$base/models',
      queryParameters: const {
        'output_modalities': 'text',
        'sort': 'most-popular',
      },
      options: Options(headers: headers),
    );

    final data = response.data?['data'];
    if (data is! List) return const [];

    return [
      for (final item in data)
        if (item is Map) _parseOpenRouterModel(item),
    ];
  }

  @visibleForTesting
  static LlmModelOption parseOpenRouterModelForTest(Map<dynamic, dynamic> raw) =>
      _parseOpenRouterModel(raw);

  static LlmModelOption _parseOpenRouterModel(Map<dynamic, dynamic> raw) {
    final map = raw.map((k, v) => MapEntry(k.toString(), v));
    final id = map['id']?.toString() ?? '';
    final name = map['name']?.toString();
    final description = map['description']?.toString();
    final context = map['context_length'];
    int? contextLength;
    if (context is int) {
      contextLength = context;
    } else if (context is num) {
      contextLength = context.toInt();
    }

    String? priceHint;
    final pricing = map['pricing'];
    if (pricing is Map) {
      final prompt = pricing['prompt'];
      final completion = pricing['completion'];
      if (prompt != null || completion != null) {
        priceHint = 'prompt \$${prompt ?? '?'} / completion \$${completion ?? '?'} per M';
      }
    }

    return LlmModelOption(
      id: id,
      name: name,
      description: description,
      contextLength: contextLength,
      priceHint: priceHint,
    );
  }

  Future<List<LlmModelOption>> _fetchGemini(
    String endpoint,
    String apiKey,
  ) async {
    if (apiKey.trim().isEmpty) return const [];

    final base = LlmEndpointUtils.normalize(endpoint);
    // Prefer OpenAI-compatible models list (matches chat endpoint).
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$base/models',
        options: Options(
          headers: {'Authorization': 'Bearer ${apiKey.trim()}'},
        ),
      );
      final data = response.data?['data'];
      if (data is List && data.isNotEmpty) {
        return [
          for (final item in data)
            if (item is Map) _parseOpenAiStyleModel(item),
        ];
      }
    } catch (e) {
      AppLogger.warning('Gemini OpenAI-compat models failed: $e');
    }

    // Fallback: native Gemini models API.
    final response = await _dio.get<Map<String, dynamic>>(
      'https://generativelanguage.googleapis.com/v1beta/models',
      queryParameters: {'key': apiKey.trim(), 'pageSize': 100},
    );
    final models = response.data?['models'];
    if (models is! List) return const [];

    return [
      for (final item in models)
        if (item is Map)
          () {
            final option = _parseGeminiNativeModel(item);
            return option.id.isNotEmpty ? option : null;
          }(),
    ].whereType<LlmModelOption>().toList();
  }

  static LlmModelOption _parseOpenAiStyleModel(Map<dynamic, dynamic> raw) {
    final map = raw.map((k, v) => MapEntry(k.toString(), v));
    final id = map['id']?.toString() ?? '';
    return LlmModelOption(
      id: id,
      name: map['name']?.toString(),
      description: map['description']?.toString(),
    );
  }

  static LlmModelOption _parseGeminiNativeModel(Map<dynamic, dynamic> raw) {
    final map = raw.map((k, v) => MapEntry(k.toString(), v));
    var id = map['name']?.toString() ?? '';
    if (id.startsWith('models/')) {
      id = id.substring('models/'.length);
    }
    final methods = map['supportedGenerationMethods'];
    if (methods is List &&
        !methods.any((m) => m.toString().contains('generateContent'))) {
      return const LlmModelOption(id: '');
    }
    return LlmModelOption(
      id: id,
      name: map['displayName']?.toString(),
      description: map['description']?.toString(),
    );
  }

  Future<List<LlmModelOption>> _fetchOpenAi(
    String endpoint,
    String apiKey,
  ) async {
    if (apiKey.trim().isEmpty) return const [];
    final base = LlmEndpointUtils.normalize(endpoint);
    final response = await _dio.get<Map<String, dynamic>>(
      '$base/models',
      options: Options(
        headers: {'Authorization': 'Bearer ${apiKey.trim()}'},
      ),
    );
    final data = response.data?['data'];
    if (data is! List) return const [];

    return [
      for (final item in data)
        if (item is Map) _parseOpenAiStyleModel(item),
    ];
  }

  Future<List<LlmModelOption>> _searchCustom({
    required String endpoint,
    required String apiKey,
    required String query,
    int limit = 20,
  }) async {
    final base = LlmEndpointUtils.normalize(endpoint);
    if (base.isEmpty) return const [];
    try {
      final headers = <String, String>{};
      if (apiKey.trim().isNotEmpty) {
        headers['Authorization'] = 'Bearer ${apiKey.trim()}';
      }
      final response = await _dio.get<Map<String, dynamic>>(
        '$base/models',
        options: Options(headers: headers),
      );
      final data = response.data?['data'];
      if (data is! List) return const [];
      final all = [
        for (final item in data)
          if (item is Map) _parseOpenAiStyleModel(item),
      ];
      final q = query.trim().toLowerCase();
      if (q.isEmpty) return all.take(limit).toList();
      return all.where((o) => _matchScore(o, q) > 0).take(limit).toList();
    } catch (_) {
      return const [];
    }
  }

  void invalidateCache() => _cache.clear();
}

class _CacheEntry {
  final List<LlmModelOption> models;
  final DateTime fetchedAt;

  _CacheEntry(this.models, this.fetchedAt);
}
