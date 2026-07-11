import 'package:dio/dio.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/core/settings/app_settings_service.dart';
import 'package:lizunemu/data/services/asmr_api_headers.dart';
import 'package:lizunemu/data/services/interceptors/accept_language_interceptor.dart';
import 'package:lizunemu/data/models/auth/auth_resp/auth_resp.dart';
import 'package:lizunemu/data/services/exceptions/network_exception.dart';
import '../../utils/logger.dart';
import 'package:lizunemu/common/constants/log_strings.dart';

/// Thrown when `/auth/reg` succeeded (account exists on the server) but the
/// follow-up auto-login call failed. The account is real; the user just needs
/// to log in manually with the credentials they just submitted.
class RegisteredButNotLoggedInException implements Exception {
  const RegisteredButNotLoggedInException(this.cause);
  final Object cause;

  @override
  String toString() => Strings.registerOkButLoginFailed;
}

class AuthService {
  final AppSettingsService _settings;
  final Dio _dio;

  AuthService({required AppSettingsService settings})
      : _settings = settings,
        _dio = Dio(
          BaseOptions(
            baseUrl: settings.serverUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 15),
            headers: AsmrApiHeaders.defaultHeaders,
          ),
        ) {
    _dio.interceptors.add(const AcceptLanguageInterceptor());
    _settings.addListener(_onSettingsChanged);
  }

  void _onSettingsChanged() {
    if (_dio.options.baseUrl != _settings.serverUrl) {
      _dio.options.baseUrl = _settings.serverUrl;
      AppLogger.info(LogStrings.logAuthApiServerSwitchedSetting7985a(_settings.serverUrl));
    }
  }

  Future<AuthResp> login(String name, String password) async {
    try {
      AppLogger.info(LogStrings.logStartLoginRequestNameNameBasa9cd2(_dio.options.baseUrl, name));
      final response = await _dio.post(
        '/auth/me',
        data: {
          'name': name,
          'password': password,
        },
      );

      AppLogger.info(LogStrings.logLoginResponseReceivedStatuscc6594(response.statusCode));

      if (response.statusCode == 200) {
        final authResp = AuthResp.fromJson(response.data);
        AppLogger.info(LogStrings.logLoginSucceeded(authResp.user?.name ?? '', authResp.user?.group ?? ''));
        return authResp;
      }

      throw Exception(LogStrings.logLoginFailedCode(response.statusCode.toString()));
    } on DioException catch (e) {
      AppLogger.error(LogStrings.logLoginRequestFailed, e);
      AppLogger.error(LogStrings.logErrorDetails(e.response?.data.toString() ?? ''));
      throw NetworkException.fromDioException(e);
    } catch (e) {
      AppLogger.error(LogStrings.logLoginFailed, e);
      throw Exception(LogStrings.logLoginFailedDetail(e.toString()));
    }
  }

  /// Registers a new account via `POST /auth/reg` and returns an authenticated
  /// [AuthResp]. If the server response omits a token (i.e. doesn't auto-login
  /// on register), this transparently calls [login] with the same credentials
  /// so callers can treat register and login as equivalent state transitions.
  Future<AuthResp> register(
    String name,
    String password, {
    String? recommenderUuid,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        'password': password,
      };
      if (recommenderUuid != null && recommenderUuid.isNotEmpty) {
        body['recommenderUuid'] = recommenderUuid;
      }

      AppLogger.info(
        LogStrings.logStartRegisterRequest(
          name,
          body.containsKey('recommenderUuid').toString(),
          _dio.options.baseUrl,
        ),
      );
      final response = await _dio.post('/auth/reg', data: body);
      AppLogger.info(LogStrings.logRegisterResponseReceivedStat806f3(response.statusCode));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final raw = response.data;
        if (raw is Map<String, dynamic>) {
          final authResp = AuthResp.fromJson(raw);
          if (authResp.token != null && authResp.user != null) {
            AppLogger.info(LogStrings.logRegisteredWithTokenSkipFollo54265);
            return authResp;
          }
        }
        AppLogger.info(LogStrings.logRegisteredWithoutTokenFallba780d3);
        try {
          return await login(name, password);
        } catch (loginErr) {
          // Account creation already succeeded server-side. Surface a distinct
          // exception so callers can guide the user to log in manually instead
          // of asking them to "retry" the registration (which would now fail
          // with "name already exists").
          AppLogger.error(LogStrings.logRegisterOkLoginFailed, loginErr);
          throw RegisteredButNotLoggedInException(loginErr);
        }
      }

      throw Exception(LogStrings.logRegisterFailedCode(response.statusCode.toString()));
    } on RegisteredButNotLoggedInException {
      rethrow;
    } on DioException catch (e) {
      AppLogger.error(LogStrings.logRegisterRequestFailed, e);
      AppLogger.error(LogStrings.logErrorDetails(e.response?.data.toString() ?? ''));
      throw NetworkException.fromDioException(e);
    } catch (e) {
      AppLogger.error(LogStrings.logRegisterFailed, e);
      throw Exception(LogStrings.logRegisterFailedDetail(e.toString()));
    }
  }
}
