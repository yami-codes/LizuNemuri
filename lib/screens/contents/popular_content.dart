import 'package:lizunemu/core/theme/app_animations.dart';
import 'package:lizunemu/data/models/works/work.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lizunemu/presentation/viewmodels/popular_viewmodel.dart';
import 'package:lizunemu/presentation/layouts/work_layout_strategy.dart';
import 'package:lizunemu/widgets/work_grid/enhanced_work_grid_view.dart';

class PopularContent extends StatefulWidget {
  const PopularContent({super.key});

  @override
  State<PopularContent> createState() => _PopularContentState();
}

class _PopularContentState extends State<PopularContent>
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
    return Selector<
        PopularViewModel,
        ({
          List<Work> works,
          bool isLoading,
          String? error,
          int currentPage,
          int? totalPages
        })>(
      selector: (_, vm) => (
        works: vm.works,
        isLoading: vm.isLoading,
        error: vm.error,
        currentPage: vm.currentPage,
        totalPages: vm.totalPages,
      ),
      builder: (context, data, child) {
        return EnhancedWorkGridView(
          works: data.works,
          isLoading: data.isLoading,
          error: data.error,
          currentPage: data.currentPage,
          totalPages: data.totalPages,
          onPageChanged: (page) =>
              context.read<PopularViewModel>().loadPage(page),
          onRefresh: () =>
              context.read<PopularViewModel>().loadPopular(refresh: true),
          onRetry: () =>
              context.read<PopularViewModel>().loadPopular(refresh: true),
          layoutStrategy: _layoutStrategy,
          scrollController: _scrollController,
        );
      },
    );
  }
}
