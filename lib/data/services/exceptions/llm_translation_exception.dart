import 'package:dio/dio.dart';
import 'package:lizunemu/common/constants/strings.dart';

enum LlmTranslationErrorType {
  missingApiKey,
  invalidConfig,
  authError,
  rateLimited,
  network,
  invalidResponse,
  contentBlocked,
  unknown,
}

class LlmTranslationException implements Exception {
  final LlmTranslationErrorType type;
  final String message;

  const LlmTranslationException(this.type, this.message);

  String get userMessage {
    switch (type) {
      case LlmTranslationErrorType.missingApiKey:
        return Strings.llmErrorMissingApiKey;
      case LlmTranslationErrorType.invalidConfig:
        return Strings.llmErrorInvalidConfig;
      case LlmTranslationErrorType.authError:
        return Strings.llmErrorAuth;
      case LlmTranslationErrorType.rateLimited:
        return Strings.llmErrorRateLimited;
      case LlmTranslationErrorType.network:
        return Strings.llmErrorNetwork;
      case LlmTranslationErrorType.invalidResponse:
        return Strings.llmErrorInvalidResponse;
      case LlmTranslationErrorType.contentBlocked:
        return Strings.llmErrorContentBlocked;
      case LlmTranslationErrorType.unknown:
        return Strings.llmErrorUnknown(message);
    }
  }

  static LlmTranslationException fromDioException(DioException e) {
    final status = e.response?.statusCode;
    if (status == 401 || status == 403) {
      return LlmTranslationException(
        LlmTranslationErrorType.authError,
        e.message ?? 'auth',
      );
    }
    if (status == 429) {
      return LlmTranslationException(
        LlmTranslationErrorType.rateLimited,
        e.message ?? 'rate limit',
      );
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return LlmTranslationException(
        LlmTranslationErrorType.network,
        e.message ?? 'network',
      );
    }
    return LlmTranslationException(
      LlmTranslationErrorType.unknown,
      e.message ?? e.toString(),
    );
  }
}
