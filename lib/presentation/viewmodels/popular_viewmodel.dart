import 'package:lizunemu/presentation/viewmodels/base/paginated_works_viewmodel.dart';
import 'package:lizunemu/data/services/api_service.dart';
import 'package:get_it/get_it.dart';
import 'package:lizunemu/core/settings/app_settings_service.dart';
import 'package:lizunemu/common/constants/log_strings.dart';

class PopularViewModel extends PaginatedWorksViewModel {
  final AppSettingsService _settings = GetIt.I<AppSettingsService>();
  bool _filterPanelExpanded = false;

  PopularViewModel() : super(GetIt.I<ApiService>());

  bool get hasSubtitle => _settings.hasSubtitleFilter;
  bool get filterPanelExpanded => _filterPanelExpanded;

  void toggleSubtitleFilter() {
    _settings.setHasSubtitleFilter(!_settings.hasSubtitleFilter);
    notifyListeners();
    refresh(); // Refresh list
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

  @override
  String get pageName => LogStrings.logPageNamePopular;

  @override
  Future<WorksResponse> fetchPage(int page) {
    return apiService.getPopular(
      page: page,
      hasSubtitle: hasSubtitle,
    );
  }

  // Keep existing convenience methods
  Future<void> loadPopular({bool refresh = false}) =>
    refresh ? this.refresh() : loadPage(1);
} 