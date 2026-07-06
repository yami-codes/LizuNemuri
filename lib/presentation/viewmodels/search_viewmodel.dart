import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:lizunemu/data/models/works/work.dart';
import 'package:lizunemu/data/models/works/pagination.dart';
import 'package:lizunemu/data/services/api_service.dart';
import 'package:lizunemu/core/settings/app_settings_service.dart';
import 'package:lizunemu/presentation/models/filter_state.dart';
import 'package:lizunemu/presentation/models/work_list_filter_preset.dart';
import 'package:lizunemu/utils/user_facing_error.dart';
import 'package:lizunemu/utils/logger.dart';
import 'package:lizunemu/common/constants/log_strings.dart';

class SearchViewModel extends ChangeNotifier {
  final _apiService = GetIt.I<ApiService>();
  final _settings = GetIt.I<AppSettingsService>();

  List<Work> _works = [];
  List<Work> get works => _works;

  String _keyword = '';
  String get keyword => _keyword;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Pagination? _pagination;
  int get totalPages =>
      _pagination?.totalCount != null && _pagination?.pageSize != null
          ? (_pagination!.totalCount! / _pagination!.pageSize!).ceil()
          : 1;
  int _currentPage = 1;
  int get currentPage => _currentPage;

  bool get hasSubtitle => _settings.hasSubtitleFilter;

  FilterState _filterState = const FilterState();
  FilterState get filterState => _filterState;

  void toggleSubtitle() {
    _settings.setHasSubtitleFilter(!_settings.hasSubtitleFilter);
    notifyListeners();
    if (_keyword.isNotEmpty) {
      search(_keyword);
    }
  }

  void updatePreset(WorkListFilterPreset preset) {
    _filterState = _filterState.copyWithPreset(preset);
    notifyListeners();
    if (_keyword.isNotEmpty) {
      search(_keyword);
    }
  }

  void updateSortDirection(bool isDescending) {
    if (_filterState.orderField == 'random') return;
    _filterState = _filterState.copyWith(isDescending: isDescending);
    notifyListeners();
    if (_keyword.isNotEmpty) {
      search(_keyword);
    }
  }

  /// Run search.
  Future<void> search(String keyword, {int page = 1}) async {
    if (keyword.isEmpty) return;

    _keyword = keyword;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      AppLogger.info(LogStrings.logSearchKeywordKeywordPage420d8(keyword, page));
      final response = await _apiService.searchWorks(
        keyword: keyword,
        page: page,
        order: _filterState.orderField,
        sort: _filterState.sortValue,
        hasSubtitle: hasSubtitle,
      );

      _works = response.works;
      _pagination = response.pagination;
      _currentPage = page;
      AppLogger.info(
        LogStrings.logSearchSucceededResponseWorks55719(response.works.length),
      );
    } catch (e) {
      AppLogger.error(LogStrings.logSearchFailed, e);
      _error = userFacingError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load a page.
  Future<void> loadPage(int page) async {
    if (_keyword.isEmpty) return;
    await search(_keyword, page: page);
  }

  /// Clear search results.
  void clear() {
    _works = [];
    _keyword = '';
    _error = null;
    _pagination = null;
    _currentPage = 1;
    notifyListeners();
  }
}
