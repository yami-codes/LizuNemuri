import 'package:flutter/foundation.dart';
import 'package:xuro/common/constants/strings.dart';
import 'package:xuro/data/models/auth/auth_resp/auth_resp.dart';
import 'package:xuro/data/services/auth_service.dart';
import 'package:xuro/data/repositories/auth_repository.dart';
import 'package:xuro/utils/logger.dart';
import 'package:xuro/common/constants/log_strings.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;
  final AuthRepository _authRepository;
  AuthResp? _authData;
  bool _isLoading = false;
  String? _error;

  AuthViewModel({
    required AuthService authService,
    required AuthRepository authRepository,
  })  : _authService = authService,
        _authRepository = authRepository {
    _loadSavedAuth();
  }

  Future<void> _loadSavedAuth() async {
    _authData = await _authRepository.getAuthData();
    if (_authData != null) {
      AppLogger.info(LogStrings.logLoadedSavedAuth(_authData?.user?.name ?? ''));
    }
    notifyListeners();
  }

  Future<void> login(String name, String password) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      AppLogger.info(LogStrings.logAuthviewmodelLoginStart6547f);
      _authData = await _authService.login(name, password);
      
      // 保存认证数据
      await _authRepository.saveAuthData(_authData!);
      
      AppLogger.info(LogStrings.logAuthLoginSuccessDetail(
        _authData?.token ?? '',
        _authData?.user?.loggedIn?.toString() ?? '',
        _authData?.user?.name ?? '',
        _authData?.user?.group ?? '',
        _authData?.user?.email ?? '',
        _authData?.user?.recommenderUuid ?? '',
      ));

    } catch (e) {
      AppLogger.error(LogStrings.logAuthviewmodelLoginFailedbdfe4, e);
      _error = Strings.loginFailedGeneric;
      _authData = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(
    String name,
    String password, {
    String? recommenderUuid,
  }) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      AppLogger.info(LogStrings.logAuthviewmodelRegisterStarte2fa4);
      _authData = await _authService.register(
        name,
        password,
        recommenderUuid: recommenderUuid,
      );

      await _authRepository.saveAuthData(_authData!);

      AppLogger.info(
        LogStrings.logRegisterSucceeded(_authData?.user?.name ?? '', _authData?.user?.group ?? ''),
      );
    } on RegisteredButNotLoggedInException {
      _error = Strings.registerOkButLoginFailed;
      _authData = null;
    } catch (e) {
      AppLogger.error(LogStrings.logAuthviewmodelRegisterFailed7d876, e);
      _error = Strings.registerFailedGeneric;
      _authData = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    AppLogger.info(LogStrings.logAuthviewmodelLogoute9158);
    AppLogger.info(LogStrings.logAuthLogoutUserInfo(
      _authData?.user?.name ?? '',
      _authData?.user?.group ?? '',
      _authData?.token ?? '',
    ));
    
    await _authRepository.clearAuthData();
    _authData = null;
    notifyListeners();
  }

  bool get isLoggedIn => _authData?.user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Clears the last login/register error so a freshly opened dialog doesn't
  /// inherit a stale message from a previous attempt.
  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }
  String? get username => _authData?.user?.name;
  String? get token => _authData?.token;
  String? get group => _authData?.user?.group;
  bool? get isUserLoggedIn => _authData?.user?.loggedIn;
  String? get recommenderUuid => _authData?.user?.recommenderUuid;

  Future<void> loadSavedAuth() async {
    _authData = await _authRepository.getAuthData();
    if (_authData != null) {
      AppLogger.info(LogStrings.logLoadedSavedAuth(_authData?.user?.name ?? ''));
    }
    notifyListeners();
  }
} 