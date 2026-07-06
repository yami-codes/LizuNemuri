import 'package:lizunemu/core/theme/app_spacing.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/data/models/works/work.dart';
import 'package:lizunemu/screens/search_screen.dart';
import 'package:lizunemu/widgets/common/app_search_field.dart';
import 'package:lizunemu/widgets/filter/advanced_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lizunemu/presentation/viewmodels/home_viewmodel.dart';
import 'package:lizunemu/presentation/layouts/work_layout_strategy.dart';
import 'package:lizunemu/widgets/translation/metadata_translate_page_bar.dart';
import 'package:lizunemu/widgets/work_grid/enhanced_work_grid_view.dart';
import 'package:lizunemu/widgets/work_grid/models/grid_config.dart';
import 'package:lizunemu/utils/tag_filter_snackbar.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent>
    with AutomaticKeepAliveClientMixin {
  final _layoutStrategy = const WorkLayoutStrategy();
  final _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space16,
            AppSpacing.space12,
            AppSpacing.space16,
            AppSpacing.space8,
          ),
          child: AppSearchField(
            hintText: Strings.homeSearchHint,
            readOnly: true,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
        ),
        Consumer<HomeViewModel>(
          builder: (context, vm, _) => AdvancedFilterBar(
            hasSubtitle: vm.hasSubtitle,
            filterState: vm.filterState,
            onSubtitleChanged: vm.updateSubtitle,
            onPresetSelected: vm.updatePreset,
            onSortDirectionChanged: vm.updateSortDirection,
            onIncludeTagsChanged: vm.updateIncludeTags,
            onExcludeTagsChanged: vm.updateExcludeTags,
            onAgeRatingChanged: vm.updateAgeRating,
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        Expanded(
          child: Selector<
              HomeViewModel,
              ({
                List<Work> works,
                bool isLoading,
                String? error,
                int currentPage,
                int? totalPages,
                Map<String, String> translatedTitles,
                bool isTranslatingTitles,
              })>(
            selector: (_, vm) => (
              works: vm.works,
              isLoading: vm.isLoading,
              error: vm.error,
              currentPage: vm.currentPage,
              totalPages: vm.totalPages,
              translatedTitles: vm.translatedWorkTitles,
              isTranslatingTitles: vm.isTranslatingWorkTitles,
            ),
            builder: (context, data, child) {
              return Column(
                children: [
                  MetadataTranslatePageBar(
                    isTranslating: data.isTranslatingTitles,
                    onTranslate: () => context
                        .read<HomeViewModel>()
                        .translateWorksManual(data.works),
                  ),
                  Expanded(
                    child: EnhancedWorkGridView(
                      works: data.works,
                      isLoading: data.isLoading,
                      error: data.error,
                      currentPage: data.currentPage,
                      totalPages: data.totalPages,
                      onPageChanged: (page) =>
                          context.read<HomeViewModel>().loadPage(page),
                      onRefresh: () => context.read<HomeViewModel>().refresh(),
                      onRetry: () => context.read<HomeViewModel>().refresh(),
                      layoutStrategy: _layoutStrategy,
                      scrollController: _scrollController,
                      translatedTitles: data.translatedTitles,
                      config: GridConfig(
                        onTagInclude: (name) {
                          context.read<HomeViewModel>().addIncludeTag(name);
                          showTagFilterSnackBar(
                            context,
                            tagLabel: name,
                            excluded: false,
                          );
                        },
                        onTagExclude: (name) {
                          context.read<HomeViewModel>().addExcludeTag(name);
                          showTagFilterSnackBar(
                            context,
                            tagLabel: name,
                            excluded: true,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
