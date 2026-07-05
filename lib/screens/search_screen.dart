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
    
    // 如果有初始关键词，自动执行搜索
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

  void _onPageChanged(int page) async {
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

  String _getOrderText(String order, String sort) {
    switch (order) {
      case 'create_date':
        return sort == 'desc' ? Strings.sortLatest : Strings.sortOldest;
      case 'release':
        return sort == 'desc'
            ? Strings.sortReleaseDesc
            : Strings.sortReleaseAsc;
      case 'dl_count':
        return sort == 'desc' ? Strings.sortSalesDesc : Strings.sortSalesAsc;
      case 'price':
        return sort == 'desc' ? Strings.sortPriceDesc : Strings.sortPriceAsc;
      case 'rate_average_2dp':
        return Strings.sortRatingDesc;
      case 'review_count':
        return Strings.sortReviewDesc;
      case 'id':
        return sort == 'desc' ? Strings.sortRjDesc : Strings.sortRjAsc;
      case 'random':
        return Strings.sortRandom;
      default:
        return Strings.sortLabel;
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
          const SizedBox(height: AppSpacing.space8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMobile),
            child: Wrap(
              spacing: AppSpacing.space8,
              runSpacing: AppSpacing.space4,
              children: [
                Consumer<SearchViewModel>(
                  builder: (context, viewModel, _) => FilterChip(
                    label: Text(Strings.subtitleChip),
                    selected: viewModel.hasSubtitle,
                    onSelected: (_) => viewModel.toggleSubtitle(),
                    showCheckmark: true,
                  ),
                ),
                Consumer<SearchViewModel>(
                  builder: (context, viewModel, _) =>
                      PopupMenuButton<(String, String)>(
                    child: Chip(
                      label: Text(
                        _getOrderText(viewModel.order, viewModel.sort),
                      ),
                      avatar: const Icon(Icons.arrow_drop_down, size: 18),
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: ('create_date', 'desc'),
                        child: Text(Strings.sortLatest),
                      ),
                      PopupMenuItem(
                        value: ('release', 'desc'),
                        child: Text(Strings.sortReleaseDesc),
                      ),
                      PopupMenuItem(
                        value: ('release', 'asc'),
                        child: Text(Strings.sortReleaseAsc),
                      ),
                      PopupMenuItem(
                        value: ('dl_count', 'desc'),
                        child: Text(Strings.sortSalesDesc),
                      ),
                      PopupMenuItem(
                        value: ('price', 'asc'),
                        child: Text(Strings.sortPriceAsc),
                      ),
                      PopupMenuItem(
                        value: ('price', 'desc'),
                        child: Text(Strings.sortPriceDesc),
                      ),
                      PopupMenuItem(
                        value: ('rate_average_2dp', 'desc'),
                        child: Text(Strings.sortRatingDesc),
                      ),
                      PopupMenuItem(
                        value: ('review_count', 'desc'),
                        child: Text(Strings.sortReviewDesc),
                      ),
                      PopupMenuItem(
                        value: ('id', 'desc'),
                        child: Text(Strings.sortRjDesc),
                      ),
                      PopupMenuItem(
                        value: ('id', 'asc'),
                        child: Text(Strings.sortRjAsc),
                      ),
                      PopupMenuItem(
                        value: ('random', 'desc'),
                        child: Text(Strings.sortRandom),
                      ),
                    ],
                    onSelected: (value) =>
                        viewModel.setOrder(value.$1, value.$2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
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
