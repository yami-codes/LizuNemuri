import 'package:dio/dio.dart';
import 'package:lizunemu/data/services/asmr_api_headers.dart';

/// Injects [AsmrApiHeaders.acceptLanguage] on every outgoing request.
class AcceptLanguageInterceptor extends Interceptor {
  const AcceptLanguageInterceptor();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers.putIfAbsent(
      'Accept-Language',
      () => AsmrApiHeaders.acceptLanguage,
    );
    handler.next(options);
  }
}
