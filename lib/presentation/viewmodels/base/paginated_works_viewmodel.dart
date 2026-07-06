import 'package:flutter/foundation.dart';
import 'package:lizunemu/data/models/works/work.dart';
import 'package:lizunemu/data/models/works/pagination.dart';
import 'package:lizunemu/data/services/api_service.dart';
import 'package:lizunemu/data/services/exceptions/network_exception.dart';
import 'package:lizunemu/utils/user_facing_error.dart';
import 'package:lizunemu/utils/logger.dart';
import 'package:lizunemu/common/constants/log_strings.dart';

abstract class PaginatedWorksViewModel extends ChangeNotifier {
  final ApiService _apiService;
  List<Work> _works = [];
  bool _isLoading = false;
  String? _error;
  bool _isLoginError = false;
  Pagination? _pagination;
  int _currentPage = 1;
  bool _isPrefetching = false;
  WorksResponse? _prefetchedResponse;
  int? _prefetchedPage;

  PaginatedWorksViewModel(this._apiService) {
    _init();
  }

  // Async initialization
  Future<void> _init() async {
    await onInit(); // Subclass init hook
    loadPage(1);
  }

  // Init hook for subclasses
  Future<void> onInit() async {}

  // Getters
  List<Work> get works => _works;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoginError => _isLoginError;
  int get currentPage => _currentPage;
  int? get totalPages => _pagination?.totalCount != null && _pagination?.pageSize != null
      ? (_pagination!.totalCount! / _pagination!.pageSize!).ceil()
      : null;

  // Page name for logging
  String get pageName;

  // Methods subclasses must implement
  Future<WorksResponse> fetchPage(int page);

  // ApiService accessor for subclasses
  ApiService get apiService => _apiService;

  // Shared load logic
  Future<void> loadPage(int page) async {
    if (_isLoading) return;
    if (page < 1 || (totalPages != null && page > totalPages!)) return;

    _isLoading = true;
    _error = null;
    _isLoginError = false;
    notifyListeners();

    try {
      WorksResponse response;
      if (_prefetchedPage == page && _prefetchedResponse != null) {
        response = _prefetchedResponse!;
        _prefetchedResponse = null;
        _prefetchedPage = null;
        AppLogger.info(LogStrings.logUsingPreloadedData(page.toString(), pageName));
      } else {
        AppLogger.info(LogStrings.logLoadingPageName(pageName, page.toString()));
        response = await fetchPage(page);
      }
      _works = response.works;
      _pagination = response.pagination;
      _currentPage = page;
      AppLogger.info(LogStrings.logPageWorksLoaded(page.toString(), pageName, response.works.length.toString()));
    } catch (e) {
      AppLogger.error(LogStrings.logPageLoadFailed(pageName), e);
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

  /// Preload next page when idle to reduce page-turn latency.
  void maybePrefetchNext() {
    final nextPage = _currentPage + 1;
    if (_isPrefetching) return;
    if (_isLoading) return;
    if (totalPages != null && nextPage > totalPages!) return;
    if (_prefetchedPage == nextPage) return;

    _isPrefetching = true;
    fetchPage(nextPage).then((response) {
      _prefetchedResponse = response;
      _prefetchedPage = nextPage;
      AppLogger.debug(LogStrings.logPreloadDone(pageName, nextPage.toString()));
    }).catchError((e) {
      AppLogger.debug(LogStrings.logPreloadFailed(pageName, nextPage.toString(), e.toString()));
    }).whenComplete(() {
      _isPrefetching = false;
    });
  }

  /// Clear preload cache when query filters change.
  void _invalidatePrefetch() {
    _prefetchedResponse = null;
    _prefetchedPage = null;
  }

  // Refresh
  Future<void> refresh() async {
    _invalidatePrefetch();
    AppLogger.info(LogStrings.logRefreshingPagenamee3eb2(pageName));
    await loadPage(1);
  }

  @override
  void dispose() {
    AppLogger.info(LogStrings.logDisposingPagenameViewmodelfc71e(pageName));
    super.dispose();
  }

  // Pagination getter
  Pagination? get pagination => _pagination;
} 