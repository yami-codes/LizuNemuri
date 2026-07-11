import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizunemu/data/services/exceptions/llm_translation_exception.dart';
import 'package:lizunemu/data/services/llm_client.dart';

void main() {
  test('fromDioException maps 429 to rateLimited', () {
    final e = DioException(
      requestOptions: RequestOptions(path: '/chat/completions'),
      response: Response(
        requestOptions: RequestOptions(path: '/chat/completions'),
        statusCode: 429,
      ),
      type: DioExceptionType.badResponse,
    );
    final mapped = LlmTranslationException.fromDioException(e);
    expect(mapped.type, LlmTranslationErrorType.rateLimited);
  });

  test('rateLimitBackoff honors Retry-After seconds', () {
    final e = DioException(
      requestOptions: RequestOptions(path: '/chat/completions'),
      response: Response(
        requestOptions: RequestOptions(path: '/chat/completions'),
        statusCode: 429,
        headers: Headers.fromMap({
          'retry-after': ['8'],
        }),
      ),
      type: DioExceptionType.badResponse,
    );
    final delay = LlmClient.rateLimitBackoffForTest(e, 0);
    expect(delay, const Duration(seconds: 8));
  });

  test('rateLimitBackoff falls back to exponential', () {
    final e = DioException(
      requestOptions: RequestOptions(path: '/chat/completions'),
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: RequestOptions(path: '/chat/completions'),
        statusCode: 429,
      ),
    );
    expect(LlmClient.rateLimitBackoffForTest(e, 0).inSeconds, 2);
    expect(LlmClient.rateLimitBackoffForTest(e, 1).inSeconds, 4);
    expect(LlmClient.rateLimitBackoffForTest(e, 2).inSeconds, 8);
  });
}
