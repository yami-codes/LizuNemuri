import 'package:flutter/foundation.dart';
import 'package:xuro/data/models/circles/circle_item.dart';
import 'package:xuro/data/services/api_service.dart';
import 'package:xuro/utils/i18n_name_resolver.dart';
import 'package:xuro/utils/user_facing_error.dart';
import 'package:xuro/utils/logger.dart';
import 'package:get_it/get_it.dart';
import 'package:xuro/common/constants/log_strings.dart';

class CirclesViewModel extends ChangeNotifier {
  final ApiService _apiService = GetIt.I<ApiService>();

  List<CircleItem> _allCircles = [];
  List<CircleItem> _filteredCircles = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  CirclesViewModel() {
    loadCircles();
  }

  List<CircleItem> get circles => _filteredCircles;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  Future<void> loadCircles() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _allCircles = await _apiService.getCircles();
      _allCircles.sort((a, b) => (b.count ?? 0).compareTo(a.count ?? 0));
      _applyFilter();
      AppLogger.info(LogStrings.logCirclesLoadedAllcirclesLengtbf4e0(_allCircles.length));
    } catch (e) {
      AppLogger.error(LogStrings.logLoadCirclesFailed, e);
      _error = userFacingError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void search(String query) {
    _searchQuery = query;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredCircles = List.from(_allCircles);
    } else {
      final lowerQuery = _searchQuery.toLowerCase();
      _filteredCircles = _allCircles.where((circle) {
        final name = circle.name?.toLowerCase() ?? '';
        final localized = I18nNameResolver.searchableNames(circle.i18n)
            .map((n) => n.toLowerCase())
            .any((n) => n.contains(lowerQuery));
        return name.contains(lowerQuery) || localized;
      }).toList();
    }
  }

  Future<void> refresh() async {
    await loadCircles();
  }
}
