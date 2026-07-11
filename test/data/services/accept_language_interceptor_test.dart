import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:lizunemu/core/settings/app_language.dart';
import 'package:lizunemu/core/settings/app_settings_service.dart';
import 'package:lizunemu/data/services/asmr_api_headers.dart';
import 'package:lizunemu/data/services/interceptors/accept_language_interceptor.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AsmrApiHeaders.acceptLanguageFor', () {
    test('English UI maps to Thai header (no en tag)', () {
      expect(
        AsmrApiHeaders.acceptLanguageFor(
          appLanguage: AppLanguage.en,
          stringsLocale: const Locale('en'),
        ),
        AsmrApiHeaders.thAcceptLanguage,
      );
      expect(
        AsmrApiHeaders.acceptLanguageFor(
          appLanguage: AppLanguage.en,
          stringsLocale: const Locale('en'),
        ),
        isNot(contains('en')),
      );
    });

    test('Chinese UI uses zh header', () {
      expect(
        AsmrApiHeaders.acceptLanguageFor(
          appLanguage: AppLanguage.zh,
          stringsLocale: const Locale('zh'),
        ),
        AsmrApiHeaders.zhAcceptLanguage,
      );
    });

    test('system + English OS locale uses Thai header', () {
      expect(
        AsmrApiHeaders.acceptLanguageFor(
          appLanguage: AppLanguage.system,
          stringsLocale: const Locale('en'),
        ),
        AsmrApiHeaders.thAcceptLanguage,
      );
    });
  });

  group('AcceptLanguageInterceptor', () {
    late AppSettingsService settings;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      settings = AppSettingsService(prefs);
      await settings.setAppLanguage(AppLanguage.en);
      if (GetIt.I.isRegistered<AppSettingsService>()) {
        GetIt.I.unregister<AppSettingsService>();
      }
      GetIt.I.registerSingleton<AppSettingsService>(settings);
    });

    tearDown(() {
      if (GetIt.I.isRegistered<AppSettingsService>()) {
        GetIt.I.unregister<AppSettingsService>();
      }
    });

    test('uses Thai header when app language is English', () async {
      final dio = Dio();
      dio.interceptors.add(const AcceptLanguageInterceptor());
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(
              options.headers['Accept-Language'],
              AsmrApiHeaders.thAcceptLanguage,
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

  test('cdnFetchHeaders always use zh Accept-Language', () {
    expect(
      AsmrApiHeaders.cdnFetchHeaders['Accept-Language'],
      AsmrApiHeaders.zhAcceptLanguage,
    );
    expect(
      AsmrApiHeaders.cdnFetchHeaders['Accept-Language'],
      isNot(contains('en')),
    );
  });
}
