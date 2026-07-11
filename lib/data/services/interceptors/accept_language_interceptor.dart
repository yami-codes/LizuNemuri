import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:lizunemu/core/settings/app_settings_service.dart';
import 'package:lizunemu/data/services/asmr_api_headers.dart';

/// Injects locale-aware [AsmrApiHeaders] on every outgoing request.
class AcceptLanguageInterceptor extends Interceptor {
  const AcceptLanguageInterceptor();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (GetIt.I.isRegistered<AppSettingsService>()) {
      final settings = GetIt.I<AppSettingsService>();
      options.headers.putIfAbsent(
        'Accept-Language',
        () => AsmrApiHeaders.acceptLanguageFor(
          appLanguage: settings.appLanguage,
          stringsLocale: settings.stringsLocale,
        ),
      );
    } else {
      options.headers.putIfAbsent(
        'Accept-Language',
        () => AsmrApiHeaders.zhAcceptLanguage,
      );
    }
    handler.next(options);
  }
}
