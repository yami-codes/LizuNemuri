import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:lizunemu/core/llm/llm_usage.dart';
import 'package:lizunemu/core/settings/app_settings_service.dart';
import 'package:lizunemu/data/models/llm/llm_usage_record.dart';
import 'package:lizunemu/data/repositories/llm_api_key_repository.dart';
import 'package:lizunemu/data/services/exceptions/llm_translation_exception.dart';
import 'package:lizunemu/utils/logger.dart';

/// OpenAI-compatible chat client (OpenAI, OpenRouter, local proxies).
class LlmClient {
  final AppSettingsService _settings;
  final LlmApiKeyRepository _apiKeyRepo;
  late final Dio _dio;

  final Map<String, int> _modelContextCache = {};

  LlmClient(this._settings, this._apiKeyRepo) {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 180),
      headers: const {
        'Content-Type': 'application/json',
      },
    ));
    _settings.addListener(_syncBaseUrl);
    _syncBaseUrl();
  }

  void _syncBaseUrl() {
    final endpoint = _normalizeEndpoint(_settings.llmApiEndpoint);
    if (endpoint.isNotEmpty && _dio.options.baseUrl != endpoint) {
      _dio.options.baseUrl = endpoint;
    }
  }

  static String _normalizeEndpoint(String raw) {
    var url = raw.trim();
    if (url.isEmpty) return '';
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  bool get _isOpenRouter =>
      _normalizeEndpoint(_settings.llmApiEndpoint).contains('openrouter.ai');

  Future<Map<String, String>> _authHeaders() async {
    final endpoint = _normalizeEndpoint(_settings.llmApiEndpoint);
    if (endpoint.isEmpty) {
      throw const LlmTranslationException(
        LlmTranslationErrorType.invalidConfig,
        'empty endpoint',
      );
    }

    final apiKey = await _apiKeyRepo.getApiKey();
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw const LlmTranslationException(
        LlmTranslationErrorType.missingApiKey,
        'missing api key',
      );
    }

    final model = _settings.llmModel.trim();
    if (model.isEmpty) {
      throw const LlmTranslationException(
        LlmTranslationErrorType.invalidConfig,
        'empty model',
      );
    }

    final headers = <String, String>{
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };
    if (_isOpenRouter) {
      headers['HTTP-Referer'] = 'https://github.com/yami-codes/LizuNemu';
      headers['X-Title'] = 'Lizunemu';
    }
    return headers;
  }

  Future<String> chatCompletion({
    required List<Map<String, String>> messages,
    double temperature = 0.2,
  }) async {
    final result = await chatCompletionWithUsage(
      messages: messages,
      temperature: temperature,
    );
    return result.content;
  }

  Future<LlmChatResult> chatCompletionWithUsage({
    required List<Map<String, String>> messages,
    double temperature = 0.2,
  }) =>
      _chatCompletionInternal(
        messages: messages,
        temperature: temperature,
        stream: false,
      );

  /// Streaming chat completion — yields text deltas, then a final [LlmChatResult]
  /// event is available via the returned future after the stream ends.
  Stream<String> chatCompletionStream({
    required List<Map<String, String>> messages,
    double temperature = 0.2,
    void Function(LlmUsage? usage)? onUsage,
  }) async* {
    final headers = await _authHeaders();
    final model = _settings.llmModel.trim();

    try {
      final response = await _dio.post<ResponseBody>(
        '/chat/completions',
        data: {
          'model': model,
          'temperature': temperature,
          'stream': true,
          'messages': messages,
        },
        options: Options(
          headers: headers,
          responseType: ResponseType.stream,
        ),
      );

      final stream = response.data?.stream;
      if (stream == null) {
        throw const LlmTranslationException(
          LlmTranslationErrorType.invalidResponse,
          'empty stream',
        );
      }

      LlmUsage? usage;
      final buffer = StringBuffer();
      final utf8ChunkStream = stream.cast<List<int>>().transform(utf8.decoder);

      await for (final textChunk in utf8ChunkStream) {
        final text = textChunk;
        if (text.isEmpty) continue;

        // SSE events may be split across chunks — keep incomplete tail in [buffer].
        buffer.write(text);
        final buffered = buffer.toString();
        buffer.clear();

        final events = buffered.split('\n');
        var remainder = '';
        if (!buffered.endsWith('\n')) {
          remainder = events.removeLast();
        }

        for (final line in events) {
          final trimmed = line.trim();
          if (!trimmed.startsWith('data:')) continue;
          final payload = trimmed.substring(5).trim();
          if (payload == '[DONE]') continue;

          try {
            final json = jsonDecode(payload);
            if (json is! Map) continue;
            final map = json.map((k, v) => MapEntry(k.toString(), v));

            final error = map['error'];
            if (error != null) {
              throw LlmTranslationException(
                LlmTranslationErrorType.unknown,
                error is Map ? (error['message']?.toString() ?? 'stream error') : error.toString(),
              );
            }

            final usageJson = map['usage'];
            if (usageJson is Map) {
              usage = LlmUsage.fromJson(
                usageJson.map((k, v) => MapEntry(k.toString(), v)),
              );
            }

            final choices = map['choices'];
            if (choices is List && choices.isNotEmpty) {
              final choice = choices.first;
              if (choice is Map) {
                final choiceMap = choice.map((k, v) => MapEntry(k.toString(), v));
                final finishReason = choiceMap['finish_reason']?.toString();
                if (finishReason == 'content_filter') {
                  throw const LlmTranslationException(
                    LlmTranslationErrorType.contentBlocked,
                    'content_filter',
                  );
                }

                final delta = choiceMap['delta'];
                if (delta is Map) {
                  final content = delta['content'];
                  if (content is String && content.isNotEmpty) {
                    yield content;
                  }
                }
                final message = choiceMap['message'];
                if (message is Map) {
                  final content = message['content'];
                  if (content is String && content.isNotEmpty) {
                    yield content;
                  }
                }
              }
            }
          } on LlmTranslationException {
            rethrow;
          } catch (_) {
            // Ignore malformed SSE fragments mid-stream.
          }
        }

        if (remainder.isNotEmpty) {
          buffer.write(remainder);
        }
      }

      onUsage?.call(usage);
    } on LlmTranslationException {
      rethrow;
    } on DioException catch (e) {
      AppLogger.warning('LlmClient stream failed: ${e.message}');
      throw LlmTranslationException.fromDioException(e);
    } catch (e) {
      throw LlmTranslationException(
        LlmTranslationErrorType.unknown,
        e.toString(),
      );
    }
  }

  Future<LlmChatResult> _chatCompletionInternal({
    required List<Map<String, String>> messages,
    double temperature = 0.2,
    required bool stream,
  }) async {
    final headers = await _authHeaders();
    final model = _settings.llmModel.trim();

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/chat/completions',
        data: {
          'model': model,
          'temperature': temperature,
          'stream': stream,
          'messages': messages,
        },
        options: Options(headers: headers),
      );

      final data = response.data;
      final content = data?['choices']?[0]?['message']?['content'];
      if (content is! String || content.trim().isEmpty) {
        throw const LlmTranslationException(
          LlmTranslationErrorType.invalidResponse,
          'empty content',
        );
      }

      final usageMap = data?['usage'];
      LlmUsage? usage;
      if (usageMap is Map) {
        usage = LlmUsage.fromJson(
          usageMap.map((k, v) => MapEntry(k.toString(), v)),
        );
      }

      return LlmChatResult(content: content.trim(), usage: usage);
    } on LlmTranslationException {
      rethrow;
    } on DioException catch (e) {
      AppLogger.warning('LlmClient request failed: ${e.message}');
      throw LlmTranslationException.fromDioException(e);
    } catch (e) {
      throw LlmTranslationException(
        LlmTranslationErrorType.unknown,
        e.toString(),
      );
    }
  }

  /// Context window for the configured model (OpenRouter `/models` lookup).
  Future<int?> fetchModelContextLength() async {
    final model = _settings.llmModel.trim();
    if (model.isEmpty) return null;

    final cached = _modelContextCache[model];
    if (cached != null) return cached;

    if (!_isOpenRouter) return null;

    try {
      final headers = await _authHeaders();
      final response = await _dio.get<Map<String, dynamic>>(
        '/models',
        options: Options(headers: headers),
      );
      final data = response.data?['data'];
      if (data is! List) return null;

      for (final item in data) {
        if (item is! Map) continue;
        final map = item.map((k, v) => MapEntry(k.toString(), v));
        if (map['id'] != model) continue;
        final context = map['context_length'];
        if (context is int) {
          _modelContextCache[model] = context;
          return context;
        }
        if (context is num) {
          final value = context.toInt();
          _modelContextCache[model] = value;
          return value;
        }
      }
    } catch (e) {
      AppLogger.warning('LlmClient model context lookup failed: $e');
    }
    return null;
  }

  /// OpenRouter account usage / credit summary (`GET /auth/key`).
  Future<LlmAccountBalance?> fetchOpenRouterBalance() async {
    if (!_isOpenRouter) return null;

    try {
      final headers = await _authHeaders();
      final response = await _dio.get<Map<String, dynamic>>(
        '/auth/key',
        options: Options(headers: headers),
      );
      return LlmAccountBalance.fromOpenRouterJson(response.data);
    } catch (e) {
      AppLogger.warning('LlmClient balance lookup failed: $e');
      return null;
    }
  }

  /// Extract JSON array from model output (may be wrapped in markdown fences).
  static List<Map<String, dynamic>> parseJsonArrayResponse(String raw) {
    var text = raw.trim();
    final fence = RegExp(r'^```(?:json)?\s*([\s\S]*?)\s*```$', multiLine: true);
    final match = fence.firstMatch(text);
    if (match != null) {
      text = match.group(1)!.trim();
    }

    final decoded = jsonDecode(text);
    if (decoded is! List) {
      throw const FormatException('expected JSON array');
    }
    return decoded
        .whereType<Map>()
        .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
        .toList();
  }
}
