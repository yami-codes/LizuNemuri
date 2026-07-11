import 'package:dio/dio.dart';
import 'package:lizunemu/data/services/asmr_api_headers.dart';

/// Injects Chinese `Accept-Language` on every outgoing asmr API request.
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
