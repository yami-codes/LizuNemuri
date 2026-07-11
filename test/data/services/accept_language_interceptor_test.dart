import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizunemu/data/services/asmr_api_headers.dart';
import 'package:lizunemu/data/services/interceptors/accept_language_interceptor.dart';

void main() {
  test('acceptLanguage is zh-CN and never includes en', () {
    expect(AsmrApiHeaders.acceptLanguage, AsmrApiHeaders.zhAcceptLanguage);
    expect(AsmrApiHeaders.acceptLanguage, isNot(contains('en')));
    expect(AsmrApiHeaders.acceptLanguage, startsWith('zh-CN'));
  });

  test('cdnFetchHeaders use the same Chinese Accept-Language', () {
    expect(
      AsmrApiHeaders.cdnFetchHeaders['Accept-Language'],
      AsmrApiHeaders.acceptLanguage,
    );
  });

  group('AcceptLanguageInterceptor', () {
    test('always injects Chinese Accept-Language', () async {
      final dio = Dio();
      dio.interceptors.add(const AcceptLanguageInterceptor());
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(
              options.headers['Accept-Language'],
              AsmrApiHeaders.acceptLanguage,
            );
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.cancel,
              ),
            );
          },
        ),
      );

      await expectLater(
        dio.get('https://api.asmr.one/api/works'),
        throwsA(isA<DioException>()),
      );
    });

    test('does not override caller-provided Accept-Language', () async {
      final dio = Dio();
      dio.interceptors.add(const AcceptLanguageInterceptor());
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.headers['Accept-Language'], 'custom-lang');
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.cancel,
              ),
            );
          },
        ),
      );

      await expectLater(
        dio.get(
          'https://api.asmr.one/api/works',
          options: Options(headers: {'Accept-Language': 'custom-lang'}),
        ),
        throwsA(isA<DioException>()),
      );
    });
  });
}
