import 'package:flutter/material.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/data/models/works/work.dart';
import 'package:lizunemu/screens/detail_screen.dart';
import 'package:lizunemu/widgets/work_grid.dart';
import 'package:lizunemu/presentation/layouts/work_layout_strategy.dart';
import 'package:lizunemu/widgets/work_grid/models/grid_config.dart';

class WorkGridView extends StatelessWidget {
  final List<Work> works;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;
  final bool isLoginError;
  final VoidCallback? onLogin;
  final String? emptyMessage;
  final Widget? customEmptyWidget;
  final WorkLayoutStrategy layoutStrategy;
  final ScrollController? scrollController;
  final Widget? bottomWidget;
  final Map<String, String>? translatedTitles;
  final GridConfig? config;

  const WorkGridView({
    super.key,
    required this.works,
    required this.isLoading,
    this.error,
    this.onRetry,
    this.isLoginError = false,
    this.onLogin,
    this.emptyMessage,
    this.customEmptyWidget,
    this.layoutStrategy = const WorkLayoutStrategy(),
    this.scrollController,
    this.bottomWidget,
    this.translatedTitles,
    this.config,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (error != null) {
      final showLogin = isLoginError && onLogin != null;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(error!),
            if (showLogin) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onLogin,
                child: Text(Strings.goLogin),
              ),
            ] else if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: Text(Strings.retry),
              ),
            ],
          ],
        ),
      );
    }

    if (works.isEmpty) {
      if (customEmptyWidget != null) {
        return customEmptyWidget!;
      }
      if (emptyMessage != null) {
        return Center(
          child: Text(
            emptyMessage!,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        );
      }
      return const SizedBox.shrink();
    }

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverPadding(
          padding: layoutStrategy.getPadding(context),
          sliver: WorkGrid(
            works: works,
            layoutStrategy: layoutStrategy,
            translatedTitles: translatedTitles,
            onWorkTap: (work) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailScreen(work: work),
                ),
              );
            },
            onTagInclude: config?.onTagInclude,
            onTagExclude: config?.onTagExclude,
          ),
        ),
        if (bottomWidget != null)
          SliverToBoxAdapter(
            child: bottomWidget!,
          ),
      ],
    );
  }
}
