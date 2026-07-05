import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:xuro/core/settings/app_settings_service.dart';
import 'package:xuro/data/repositories/llm_api_key_repository.dart';
import 'package:xuro/data/services/exceptions/llm_translation_exception.dart';
import 'package:xuro/utils/logger.dart';

/// OpenAI-compatible chat client (OpenAI, OpenRouter, local proxies).
class LlmClient {
  final AppSettingsService _settings;
  final LlmApiKeyRepository _apiKeyRepo;
  late final Dio _dio;

  LlmClient(this._settings, this._apiKeyRepo) {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 120),
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

  Future<String> chatCompletion({
    required List<Map<String, String>> messages,
    double temperature = 0.2,
  }) async {
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

    final headers = <String, dynamic>{
      'Authorization': 'Bearer $apiKey',
    };
    if (endpoint.contains('openrouter.ai')) {
      headers['HTTP-Referer'] = 'https://github.com/yami-codes/Xuro';
      headers['X-Title'] = 'Xuro';
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/chat/completions',
        data: {
          'model': model,
          'temperature': temperature,
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
      return content.trim();
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
