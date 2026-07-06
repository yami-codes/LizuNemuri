import 'package:flutter/foundation.dart';
import 'package:lizunemu/data/models/works/work.dart';
import 'package:lizunemu/data/models/works/pagination.dart';
import 'package:lizunemu/data/services/api_service.dart';
import 'package:lizunemu/utils/user_facing_error.dart';
import 'package:lizunemu/utils/logger.dart';
import 'package:get_it/get_it.dart';
import 'package:lizunemu/core/settings/app_settings_service.dart';
import 'package:lizunemu/common/constants/log_strings.dart';

import 'package:lizunemu/presentation/viewmodels/base/work_list_translation_mixin.dart';

class SimilarWorksViewModel extends ChangeNotifier with WorkListTranslationMixin {
  final ApiService _apiService;
  final AppSettingsService _settings;
  final Work work;
  List<Work> _works = [];
  bool _isLoading = false;
  String? _error;
  Pagination? _pagination;
  int _currentPage = 1;
  bool _filterPanelExpanded = false;

  SimilarWorksViewModel(this.work)
      : _apiService = GetIt.I<ApiService>(),
        _settings = GetIt.I<AppSettingsService>() {
    // Shared filter from AppSettingsService; load on construct.
    loadSimilarWorks(refresh: true);
  }

  // Getters
  List<Work> get works => _works;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  bool get hasSubtitle => _settings.hasSubtitleFilter;
  bool get filterPanelExpanded => _filterPanelExpanded;
  int? get totalPages =>
      _pagination?.totalCount != null && _pagination?.pageSize != null
          ? (_pagination!.totalCount! / _pagination!.pageSize!).ceil()
          : null;

  // Toggle subtitle filter
  void toggleSubtitleFilter() {
    _settings.setHasSubtitleFilter(!_settings.hasSubtitleFilter);
    notifyListeners();
    loadSimilarWorks(refresh: true);
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

  /// Load a specific page.
  Future<void> loadPage(int page) async {
    if (_isLoading) return;
    if (page < 1 || (totalPages != null && page > totalPages!)) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getItemNeighbors(
        itemId: work.id.toString(),
        page: page,
        hasSubtitle: hasSubtitle, // Subtitle filter param
      );
      _works = response.works;
      _pagination = response.pagination;
      _currentPage = page;
      AppLogger.info(LogStrings.logPageListLoaded(page.toString(), LogStrings.logPageNameSimilar, response.works.length.toString()));
      await maybeAutoTranslateWorks(_works);
    } catch (e) {
      AppLogger.error(LogStrings.logLoadSimilarFailed, e);
      _error = userFacingError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load similar works (initial load and refresh).
  Future<void> loadSimilarWorks({bool refresh = false}) async {
    if (refresh) clearTranslatedWorkTitles();
    await loadPage(1);
  }

} 