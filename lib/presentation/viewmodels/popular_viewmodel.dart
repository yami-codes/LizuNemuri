import 'dart:convert';

import 'package:lizunemu/presentation/viewmodels/base/paginated_works_viewmodel.dart';
import 'package:lizunemu/data/services/api_service.dart';
import 'package:get_it/get_it.dart';
import 'package:lizunemu/core/settings/app_settings_service.dart';
import 'package:lizunemu/presentation/models/filter_state.dart';
import 'package:lizunemu/presentation/models/age_rating_filter.dart';
import 'package:lizunemu/presentation/models/work_list_filter_preset.dart';
import 'package:lizunemu/presentation/models/work_list_query_builder.dart';
import 'package:lizunemu/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lizunemu/common/constants/log_strings.dart';

class PopularViewModel extends PaginatedWorksViewModel {
  static const String _filterStateKey = 'popular_filter_state';

  final AppSettingsService _settings = GetIt.I<AppSettingsService>();
  bool _filterPanelExpanded = false;
  FilterState _filterState = const FilterState(
    orderField: 'dl_count',
    isDescending: true,
  );

  PopularViewModel() : super(GetIt.I<ApiService>());

  @override
  Future<void> onInit() async {
    await _loadFilterState();
  }

  bool get hasSubtitle => _settings.hasSubtitleFilter;
  bool get filterPanelExpanded => _filterPanelExpanded;
  FilterState get filterState => _filterState;

  /// Uses curated `/recommender/popular` only for default sales sort with no tag/age filter.
  bool get _usesPopularEndpoint =>
      _filterState.orderField == 'dl_count' &&
      _filterState.isDescending &&
      !_filterState.hasTagOrAgeFilter;

  Future<void> _loadFilterState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_filterStateKey);
      if (jsonStr != null) {
        _filterState = FilterState.fromJson(jsonDecode(jsonStr));
        notifyListeners();
      }
    } catch (e) {
      AppLogger.error(LogStrings.logLoadFilterStateFailed, e);
    }
  }

  Future<void> _saveFilterState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_filterStateKey, jsonEncode(_filterState.toJson()));
    } catch (e) {
      AppLogger.error(LogStrings.logSaveFilterStateFailed, e);
    }
  }

  void toggleSubtitleFilter() {
    _settings.setHasSubtitleFilter(!_settings.hasSubtitleFilter);
    notifyListeners();
    refresh();
  }

  void updatePreset(WorkListFilterPreset preset) {
    _filterState = _filterState.copyWithPreset(preset);
    _saveFilterState();
    notifyListeners();
    refresh();
  }

  void updateSortDirection(bool isDescending) {
    if (_filterState.orderField == 'random') return;
    _filterState = _filterState.copyWith(isDescending: isDescending);
    _saveFilterState();
    notifyListeners();
    refresh();
  }

  void toggleFilterPanel() {
    _filterPanelExpanded = !_filterPanelExpanded;
    notifyListeners();
  }

  void closeFilterPanel() {
    if (_filterPanelExpanded) {
      _filterPanelExpanded = false;
      notifyListeners();
    }
  }

  void updateIncludeTags(List<String> tags) {
    _filterState = _filterState.copyWith(includeTags: tags);
    _saveFilterState();
    notifyListeners();
    refresh();
  }

  void updateAgeRating(AgeRatingFilter rating) {
    _filterState = _filterState.copyWith(ageRating: rating);
    _saveFilterState();
    notifyListeners();
    refresh();
  }

  @override
  String get pageName => LogStrings.logPageNamePopular;

  @override
  Future<WorksResponse> fetchPage(int page) {
    if (_usesPopularEndpoint) {
      return apiService.getPopular(
        page: page,
        hasSubtitle: hasSubtitle,
      );
    }
    if (WorkListQueryBuilder.requiresSearchEndpoint(_filterState)) {
      return apiService.searchWorks(
        keyword: WorkListQueryBuilder.buildSearchKeyword(
          includeTags: _filterState.includeTags,
          ageRating: _filterState.ageRating,
        ),
        page: page,
        hasSubtitle: hasSubtitle,
        order: _filterState.orderField,
        sort: _filterState.sortValue,
      );
    }
    return apiService.getWorks(
      page: page,
      hasSubtitle: hasSubtitle,
      order: _filterState.orderField,
      sort: _filterState.sortValue,
    );
  }

  Future<void> loadPopular({bool refresh = false}) =>
      refresh ? this.refresh() : loadPage(1);
}
