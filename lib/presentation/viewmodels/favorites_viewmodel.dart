import 'package:flutter/foundation.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/data/models/works/work.dart';
import 'package:lizunemu/data/models/works/pagination.dart';
import 'package:lizunemu/data/services/api_service.dart';
import 'package:lizunemu/data/services/exceptions/network_exception.dart';
import 'package:lizunemu/presentation/viewmodels/auth_viewmodel.dart';
import 'package:lizunemu/utils/user_facing_error.dart';
import 'package:lizunemu/utils/logger.dart';
import 'package:get_it/get_it.dart';
import 'package:lizunemu/common/constants/log_strings.dart';

import 'package:lizunemu/presentation/viewmodels/base/work_list_translation_mixin.dart';

class FavoritesViewModel extends ChangeNotifier with WorkListTranslationMixin {
  final ApiService _apiService;
  final AuthViewModel _authViewModel;
  List<Work> _works = [];
  bool _isLoading = false;
  String? _error;
  bool _isLoginError = false;
  Pagination? _pagination;
  int _currentPage = 1;

  FavoritesViewModel(this._authViewModel) : _apiService = GetIt.I<ApiService>();

  List<Work> get works => _works;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// True when [error] is a "not logged in" / auth failure, so the UI can
  /// offer a login action instead of a (useless) retry.
  bool get isLoginError => _isLoginError;
  int get currentPage => _currentPage;
  int? get totalCount => _pagination?.totalCount;
  int? get totalPages =>
      _pagination?.totalCount != null && _pagination?.pageSize != null
          ? (_pagination!.totalCount! / _pagination!.pageSize!).ceil()
          : null;

  /// Load a specific page.
  Future<void> loadPage(int page) async {
    if (_isLoading) return;
    if (page < 1 || (totalPages != null && page > totalPages!)) return;

    if (!_authViewModel.isLoggedIn) {
      _error = Strings.loginRequired;
      _isLoginError = true;
      _works = [];
      _pagination = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    _isLoginError = false;
    notifyListeners();

    try {
      final response = await _apiService.getFavorites(page: page);
      _works = response.works;
      _pagination = response.pagination;
      _currentPage = page;
      AppLogger.info(LogStrings.logPageListLoaded(page.toString(), LogStrings.logPageNameFavorites, response.works.length.toString()));
      await maybeAutoTranslateWorks(_works);
    } catch (e) {
      AppLogger.error(LogStrings.logLoadFavoritesFailed, e);
      if (e is NetworkException) {
        _error = e.userMessage;
        _isLoginError = e.isAuthError;
      } else {
        _error = userFacingError(e);
        _isLoginError = false;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load favorites (initial load and refresh).
  Future<void> loadFavorites({bool refresh = false}) async {
    if (refresh) clearTranslatedWorkTitles();
    await loadPage(1);
  }
} 