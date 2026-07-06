import 'package:lizunemu/core/theme/app_animations.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lizunemu/presentation/viewmodels/search_viewmodel.dart';
import 'package:lizunemu/widgets/work_grid_view.dart';
import 'package:lizunemu/presentation/layouts/work_layout_strategy.dart';
import 'package:lizunemu/utils/logger.dart';
import 'package:lizunemu/widgets/pagination_controls.dart';
import 'package:lizunemu/widgets/common/app_search_field.dart';
import 'package:lizunemu/widgets/common/back_leading.dart';
import 'package:lizunemu/widgets/filter/advanced_filter_bar.dart';
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
  late final TextEditingController _searchController;
  final _layoutStrategy = const WorkLayoutStrategy();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialKeyword);

    if (widget.initialKeyword?.isNotEmpty == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onSearch();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) return;

    AppLogger.debug(LogStrings.logRunSearchKeyword2ee4b(keyword));
    context.read<SearchViewModel>().search(keyword);
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
            child: AppSearchField(
              controller: _searchController,
              hintText: Strings.searchInputHint,
              onSubmitted: (_) => _onSearch(),
              onChanged: (_) => setState(() {}),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        context.read<SearchViewModel>().clear();
                        setState(() {});
                      },
                    )
                  : null,
            ),
          ),
          Consumer<SearchViewModel>(
            builder: (context, vm, _) => AdvancedFilterBar(
              hasSubtitle: vm.hasSubtitle,
              filterState: vm.filterState,
              onSubtitleChanged: (_) => vm.toggleSubtitle(),
              onPresetSelected: vm.updatePreset,
              onSortDirectionChanged: vm.updateSortDirection,
            ),
          ),
          const SizedBox(height: AppSpacing.space8),
          Expanded(
            child: Consumer<SearchViewModel>(
              builder: (context, viewModel, child) {
                Widget? emptyWidget;
                if (viewModel.works.isEmpty && viewModel.keyword.isEmpty) {
                  emptyWidget = Center(
                    child: Text(Strings.searchEmptyPrompt),
                  );
                } else if (viewModel.works.isEmpty) {
                  emptyWidget = Center(
                    child: Text(Strings.searchNoResults),
                  );
                }

                return WorkGridView(
                  works: viewModel.works,
                  isLoading: viewModel.isLoading,
                  error: viewModel.error,
                  onRetry: _onSearch,
                  customEmptyWidget: emptyWidget,
                  layoutStrategy: _layoutStrategy,
                  scrollController: _scrollController,
                  bottomWidget: viewModel.works.isNotEmpty
                      ? PaginationControls(
                          currentPage: viewModel.currentPage,
                          totalPages: viewModel.totalPages,
                          isLoading: viewModel.isLoading,
                          onPageChanged: _onPageChanged,
                        )
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
