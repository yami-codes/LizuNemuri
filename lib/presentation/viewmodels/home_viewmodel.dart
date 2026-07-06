import 'dart:convert';
import 'package:lizunemu/presentation/viewmodels/base/paginated_works_viewmodel.dart';
import 'package:lizunemu/data/services/api_service.dart';
import 'package:get_it/get_it.dart';
import 'package:lizunemu/core/settings/app_settings_service.dart';
import 'package:lizunemu/presentation/models/filter_state.dart';
import 'package:lizunemu/presentation/models/work_list_filter_preset.dart';
import 'package:lizunemu/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lizunemu/common/constants/log_strings.dart';

class HomeViewModel extends PaginatedWorksViewModel {
  // home_filter_state (sort) is page-private prefs; shared subtitle filter uses AppSettingsService.
  static const String _filterStateKey = 'home_filter_state';

  final AppSettingsService _settings = GetIt.I<AppSettingsService>();
  bool _filterPanelExpanded = false;
  FilterState _filterState = const FilterState();

  bool get filterPanelExpanded => _filterPanelExpanded;
  bool get hasSubtitle => _settings.hasSubtitleFilter;
  FilterState get filterState => _filterState;

  HomeViewModel() : super(GetIt.I<ApiService>());

  @override
  Future<void> onInit() async {
    await _loadFilterState();
  }

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

  void toggleFilterPanel() {
    _filterPanelExpanded = !_filterPanelExpanded;
    notifyListeners();
  }

  void updateSubtitle(bool value) {
    _settings.setHasSubtitleFilter(value);
    notifyListeners();
    refresh();
  }

  void updatePreset(WorkListFilterPreset preset) {
    _filterState = _filterState.copyWithPreset(preset);
    _saveFilterState();
    notifyListeners();
    refresh();
  }

  void updateOrderField(String value) {
    updatePreset(
      WorkListFilterPresetX.fromOrder(
        orderField: value,
        isDescending: value == 'random' ? true : _filterState.isDescending,
      ),
    );
  }

  void updateSortDirection(bool isDescending) {
    if (_filterState.orderField == 'random') return;
    _filterState = _filterState.copyWith(isDescending: isDescending);
    _saveFilterState();
    notifyListeners();
    refresh();
  }

  void closeFilterPanel() {
    if (_filterPanelExpanded) {
      _filterPanelExpanded = false;
      notifyListeners();
    }
  }

  @override
  String get pageName => LogStrings.logPageNameHome;

  @override
  Future<WorksResponse> fetchPage(int page) {
    return apiService.getWorks(
      page: page,
      hasSubtitle: hasSubtitle,
      order: _filterState.orderField,
      sort: _filterState.sortValue,
    );
  }

}
