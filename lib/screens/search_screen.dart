import 'package:lizunemu/core/theme/app_animations.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lizunemu/presentation/viewmodels/search_viewmodel.dart';
import 'package:lizunemu/widgets/translation/metadata_translate_page_bar.dart';
import 'package:lizunemu/widgets/work_grid_view.dart';
import 'package:lizunemu/presentation/layouts/work_layout_strategy.dart';
import 'package:lizunemu/utils/logger.dart';
import 'package:lizunemu/widgets/pagination_controls.dart';
import 'package:lizunemu/widgets/common/back_leading.dart';
import 'package:lizunemu/widgets/filter/advanced_filter_bar.dart';
import 'package:lizunemu/widgets/search/search_command_field.dart';
import 'package:lizunemu/widgets/work_grid/models/grid_config.dart';
import 'package:lizunemu/utils/tag_filter_snackbar.dart';
import 'package:lizunemu/common/constants/log_strings.dart';

class SearchScreen extends StatelessWidget {
  final String? initialKeyword;

  const SearchScreen({
    super.key,
    this.initialKeyword,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SearchViewModel(),
      child: SearchScreenContent(initialKeyword: initialKeyword),
    );
  }
}

class SearchScreenContent extends StatefulWidget {
  final String? initialKeyword;

  const SearchScreenContent({
    super.key,
    this.initialKeyword,
  });

  @override
  State<SearchScreenContent> createState() => _SearchScreenContentState();
}

class _SearchScreenContentState extends State<SearchScreenContent> {
  late final TextEditingController _draftController;
  final _layoutStrategy = const WorkLayoutStrategy();
  final _scrollController = ScrollController();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _draftController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final vm = context.read<SearchViewModel>();
    vm.loadInitialKeyword(widget.initialKeyword);
    _draftController.text = vm.keyword;
    if (widget.initialKeyword?.isNotEmpty == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onSearch());
    }
  }

  @override
  void dispose() {
    _draftController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final vm = context.read<SearchViewModel>();
    final draft = _draftController.text.trim();
    if (draft.isEmpty &&
        vm.commandTokens.isEmpty &&
        !vm.filterState.hasTagOrAgeFilter) {
      return;
    }

    AppLogger.debug(LogStrings.logRunSearchKeyword2ee4b(draft));
    vm.search(vm.keyword, draft: draft);
  }

  Future<void> _onPageChanged(int page) async {
    final viewModel = context.read<SearchViewModel>();
    await viewModel.loadPage(page);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: AppAnimations.medium,
        curve: AppAnimations.enter,
      );
    }
  }

  void _onTagInclude(BuildContext context, String apiName) {
    final vm = context.read<SearchViewModel>();
    vm.addIncludeTag(apiName);
    showTagFilterSnackBar(context, tagLabel: apiName, excluded: false);
  }

  void _onTagExclude(BuildContext context, String apiName) {
    final vm = context.read<SearchViewModel>();
    vm.addExcludeTag(apiName);
    showTagFilterSnackBar(context, tagLabel: apiName, excluded: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PoppableAppBar(
        title: Strings.search,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageMobile,
              AppSpacing.space8,
              AppSpacing.pageMobile,
              0,
            ),
            child: Consumer<SearchViewModel>(
              builder: (context, vm, _) => SearchCommandField(
                tokens: vm.commandTokens,
                onTokensChanged: vm.setCommandTokens,
                draftController: _draftController,
                hintText: Strings.searchCommandHint,
                tagNames: vm.tagNames,
                tagCatalog: vm.tagCatalog,
                onSubmitted: (_) => _onSearch(),
                suffixIcon: vm.commandTokens.isNotEmpty ||
                        _draftController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _draftController.clear();
                          vm.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
            ),
          ),
          Consumer<SearchViewModel>(
            builder: (context, vm, _) => AdvancedFilterBar(
              hasSubtitle: vm.hasSubtitle,
              filterState: vm.filterState,
              onSubtitleChanged: (_) => vm.toggleSubtitle(),
              onPresetSelected: vm.updatePreset,
              onSortDirectionChanged: vm.updateSortDirection,
              onIncludeTagsChanged: vm.updateIncludeTags,
              onExcludeTagsChanged: vm.updateExcludeTags,
              onAgeRatingChanged: vm.updateAgeRating,
            ),
          ),
          const SizedBox(height: AppSpacing.space8),
          Expanded(
            child: Consumer<SearchViewModel>(
              builder: (context, viewModel, child) {
                Widget? emptyWidget;
                if (viewModel.works.isEmpty &&
                    viewModel.keyword.isEmpty &&
                    viewModel.commandTokens.isEmpty &&
                    !viewModel.filterState.hasTagOrAgeFilter) {
                  emptyWidget = Center(
                    child: Text(Strings.searchEmptyPrompt),
                  );
                } else if (viewModel.works.isEmpty && !viewModel.isLoading) {
                  emptyWidget = Center(
                    child: Text(Strings.searchNoResults),
                  );
                }

                return Column(
                  children: [
                    MetadataTranslatePageBar(
                      isTranslating: viewModel.isTranslatingWorkTitles,
                      onTranslate: () =>
                          viewModel.translateWorksManual(viewModel.works),
                    ),
                    Expanded(
                      child: WorkGridView(
                        works: viewModel.works,
                        isLoading: viewModel.isLoading,
                        error: viewModel.error,
                        onRetry: _onSearch,
                        customEmptyWidget: emptyWidget,
                        layoutStrategy: _layoutStrategy,
                        scrollController: _scrollController,
                        translatedTitles: viewModel.translatedWorkTitles,
                        config: GridConfig(
                          onTagInclude: (name) =>
                              _onTagInclude(context, name),
                          onTagExclude: (name) =>
                              _onTagExclude(context, name),
                        ),
                        bottomWidget: viewModel.works.isNotEmpty
                            ? PaginationControls(
                                currentPage: viewModel.currentPage,
                                totalPages: viewModel.totalPages,
                                isLoading: viewModel.isLoading,
                                onPageChanged: _onPageChanged,
                              )
                            : null,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
