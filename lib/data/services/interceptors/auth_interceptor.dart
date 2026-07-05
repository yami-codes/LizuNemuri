import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:lizunemu/data/repositories/auth_repository.dart';
import 'package:lizunemu/utils/logger.dart';
import 'package:lizunemu/common/constants/log_strings.dart';

class AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options, 
    RequestInterceptorHandler handler,
  ) async {
    try {
      final authRepository = GetIt.I<AuthRepository>();
      final authData = await authRepository.getAuthData();
      
      if (authData?.token != null) {
        options.headers['Authorization'] = 'Bearer ${authData!.token}';
      }
      
      handler.next(options);
    } catch (e) {
      AppLogger.error(LogStrings.logAuthinterceptorRequestFailed68aba, e);
      handler.next(options);  // 即使出错也继续请求
    }
  }
} 