import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:lizunemu/data/models/works/i18n.dart';
import 'package:lizunemu/data/models/works/work.dart';
import 'package:lizunemu/data/models/works/pagination.dart';
import 'package:lizunemu/data/services/api_service.dart';
import 'package:lizunemu/core/settings/app_settings_service.dart';
import 'package:lizunemu/presentation/models/filter_state.dart';
import 'package:lizunemu/presentation/models/age_rating_filter.dart';
import 'package:lizunemu/presentation/models/work_list_filter_preset.dart';
import 'package:lizunemu/presentation/models/work_list_query_builder.dart';
import 'package:lizunemu/presentation/models/search_command_parser.dart';
import 'package:lizunemu/presentation/models/search_command_suggestions.dart';
import 'package:lizunemu/presentation/models/tag_filter_helper.dart';
import 'package:lizunemu/utils/user_facing_error.dart';
import 'package:lizunemu/utils/logger.dart';
import 'package:lizunemu/common/constants/log_strings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lizunemu/presentation/viewmodels/base/work_list_translation_mixin.dart';

class SearchViewModel extends ChangeNotifier with WorkListTranslationMixin {
  static const String _filterStateKey = 'search_filter_state';
  static const String _keywordKey = 'search_last_keyword';
  static const Duration _debounceDuration = Duration(milliseconds: 450);

  final _apiService = GetIt.I<ApiService>();
  final _settings = GetIt.I<AppSettingsService>();

  Timer? _debounceTimer;
  int _searchGeneration = 0;
  bool _initialized = false;
  bool get initialized => _initialized;

  List<Work> _works = [];
  List<Work> get works => _works;

  String _keyword = '';
  String get keyword => _keyword;

  List<String> _commandTokens = [];
  List<String> get commandTokens => _commandTokens;

  List<String> _tagNames = [];
  List<String> get tagNames => _tagNames;

  Map<String, I18n> _tagCatalog = {};
  Map<String, I18n> get tagCatalog => _tagCatalog;

  bool _tagsLoaded = false;
  bool get tagsLoaded => _tagsLoaded;

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

  SearchViewModel({this.initialKeyword}) {
    _bootstrap();
  }

  final String? initialKeyword;

  Future<void> _bootstrap() async {
    await _loadFilterState();
    await loadTagCatalog();
    if (initialKeyword != null && initialKeyword!.isNotEmpty) {
      loadInitialKeyword(initialKeyword);
    } else {
      await _loadKeyword();
    }
    _initialized = true;
    notifyListeners();
    if (_canSearch) {
      await search(_keyword);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void scheduleDebouncedSearch(String draft) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      final trimmed = draft.trim();
      if (trimmed.isEmpty &&
          _commandTokens.isEmpty &&
          !_filterState.hasTagOrAgeFilter) {
        return;
      }
      search(_keyword, draft: draft);
    });
  }

  Future<void> loadTagCatalog() async {
    try {
      final tags = await _apiService.getTags();
      _tagNames = tags
          .map((t) => t.name)
          .whereType<String>()
          .where((n) => n.isNotEmpty)
          .toList();
      _tagCatalog = {
        for (final t in tags)
          if (t.name != null && t.name!.isNotEmpty && t.i18n != null)
            t.name!: t.i18n!,
      };
      _tagsLoaded = true;
      notifyListeners();
    } catch (e) {
      AppLogger.error(LogStrings.logLoadTagsFailed, e);
    }
  }

  Future<void> _loadKeyword() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _keyword = prefs.getString(_keywordKey) ?? '';
    } catch (e) {
      AppLogger.error(LogStrings.logLoadFilterStateFailed, e);
    }
  }

  Future<void> _saveKeyword() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_keyword.isEmpty) {
        await prefs.remove(_keywordKey);
      } else {
        await prefs.setString(_keywordKey, _keyword);
      }
    } catch (e) {
      AppLogger.error(LogStrings.logSaveFilterStateFailed, e);
    }
  }

  Future<void> _loadFilterState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_filterStateKey);
      if (jsonStr != null) {
        _filterState = FilterState.fromJson(jsonDecode(jsonStr));
        _commandTokens = TagFilterHelper.tokensFromFilterState(_filterState);
        notifyListeners();
      }
    } catch (e) {
      AppLogger.error(LogStrings.logLoadFilterStateFailed, e);
    }
  }

  Future<void> _saveFilterState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _filterStateKey,
        jsonEncode(_filterState.toJson()),
      );
    } catch (e) {
      AppLogger.error(LogStrings.logSaveFilterStateFailed, e);
    }
  }

  void setCommandTokens(List<String> tokens) {
    _commandTokens = List<String>.from(tokens);
    _syncFilterFromTokens();
    notifyListeners();
  }

  void _syncFilterFromTokens() {
    final tagParts = SearchCommandParser.parseTagNames(_commandTokens);
    var age = AgeRatingFilter.all;
    for (final raw in _commandTokens) {
      if (raw == r'$age:general$') age = AgeRatingFilter.general;
      if (raw == r'$age:adult$') age = AgeRatingFilter.adult;
    }
    _filterState = _filterState.copyWith(
      includeTags: tagParts.include,
      excludeTags: tagParts.exclude,
      ageRating: age,
    );
    _saveFilterState();
  }

  String _composedKeyword({String draft = ''}) =>
      WorkListQueryBuilder.buildSearchKeyword(
        textKeyword: draft,
        includeTags: _filterState.includeTags,
        excludeTags: _filterState.excludeTags,
        ageRating: _filterState.ageRating,
        extraTokens: _commandTokens.where((t) {
          final tags = SearchCommandParser.parseTagNames([t]);
          return tags.include.isEmpty && tags.exclude.isEmpty;
        }).toList(),
      );

  bool get _canSearch =>
      _keyword.isNotEmpty ||
      _commandTokens.isNotEmpty ||
      _filterState.hasTagOrAgeFilter;

  void toggleSubtitle() {
    _settings.setHasSubtitleFilter(!_settings.hasSubtitleFilter);
    notifyListeners();
    if (_canSearch) search(_keyword);
  }

  void updatePreset(WorkListFilterPreset preset) {
    _filterState = _filterState.copyWithPreset(preset);
    _saveFilterState();
    notifyListeners();
    if (_canSearch) search(_keyword);
  }

  void updateSortDirection(bool isDescending) {
    if (_filterState.orderField == 'random') return;
    _filterState = _filterState.copyWith(isDescending: isDescending);
    _saveFilterState();
    notifyListeners();
    if (_canSearch) search(_keyword);
  }

  void updateIncludeTags(List<String> tags) {
    _filterState = _filterState.copyWith(includeTags: tags);
    _rebuildTokensFromFilter();
    _saveFilterState();
    notifyListeners();
    search(_keyword);
  }

  void updateExcludeTags(List<String> tags) {
    _filterState = _filterState.copyWith(excludeTags: tags);
    _rebuildTokensFromFilter();
    _saveFilterState();
    notifyListeners();
    search(_keyword);
  }

  void updateAgeRating(AgeRatingFilter rating) {
    _filterState = _filterState.copyWith(ageRating: rating);
    _rebuildTokensFromFilter();
    _saveFilterState();
    notifyListeners();
    search(_keyword);
  }

  void addIncludeTag(String apiName) {
    _filterState = TagFilterHelper.addInclude(_filterState, apiName);
    _rebuildTokensFromFilter();
    _saveFilterState();
    notifyListeners();
    search(_keyword);
  }

  void addExcludeTag(String apiName) {
    _filterState = TagFilterHelper.addExclude(_filterState, apiName);
    _rebuildTokensFromFilter();
    _saveFilterState();
    notifyListeners();
    search(_keyword);
  }

  void _rebuildTokensFromFilter() {
    final other = _commandTokens.where((t) {
      final tags = SearchCommandParser.parseTagNames([t]);
      if (tags.include.isNotEmpty || tags.exclude.isNotEmpty) return false;
      if (t.startsWith(r'$age:') || t.startsWith(r'$-age:')) return false;
      return true;
    });
    _commandTokens = [
      ...TagFilterHelper.tokensFromFilterState(_filterState),
      ...other,
    ];
  }

  Future<void> search(String keyword, {int page = 1, String draft = ''}) async {
    _debounceTimer?.cancel();
    final extracted = SearchCommandSuggestor.extractCompleteTokens(
      tokens: _commandTokens,
      draft: draft.isNotEmpty ? draft : keyword,
    );
    _commandTokens = extracted.tokens;
    _keyword = extracted.draft.trim();
    _syncFilterFromTokens();

    final composed = _composedKeyword(draft: _keyword);
    if (composed.isEmpty) return;
    if (page == 1) clearTranslatedWorkTitles();
    final generation = ++_searchGeneration;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      AppLogger.info(
        LogStrings.logSearchKeywordKeywordPage420d8(composed, page),
      );
      final response = await _apiService.searchWorks(
        keyword: composed,
        page: page,
        order: _filterState.orderField,
        sort: _filterState.sortValue,
        hasSubtitle: hasSubtitle,
      );
      if (generation != _searchGeneration) return;

      _works = response.works;
      _pagination = response.pagination;
      _currentPage = page;
      await _saveKeyword();
      AppLogger.info(
        LogStrings.logSearchSucceededResponseWorks55719(response.works.length),
      );
      await maybeAutoTranslateWorks(_works);
    } catch (e) {
      if (generation != _searchGeneration) return;
      AppLogger.error(LogStrings.logSearchFailed, e);
      _error = userFacingError(e);
    } finally {
      if (generation == _searchGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadPage(int page) async {
    if (!_canSearch) return;
    await search(_keyword, page: page);
  }

  void clear() {
    _debounceTimer?.cancel();
    _works = [];
    _keyword = '';
    _commandTokens = [];
    _filterState = _filterState.copyWith(
      includeTags: const [],
      excludeTags: const [],
      ageRating: AgeRatingFilter.all,
    );
    _error = null;
    _pagination = null;
    _currentPage = 1;
    clearTranslatedWorkTitles();
    _saveFilterState();
    _saveKeyword();
    notifyListeners();
  }

  void loadInitialKeyword(String? raw) {
    if (raw == null || raw.isEmpty) return;
    final parsed = SearchCommandParser.parse(raw);
    _commandTokens = parsed.tokens;
    _keyword = parsed.remainder;
    _syncFilterFromTokens();
  }
}
