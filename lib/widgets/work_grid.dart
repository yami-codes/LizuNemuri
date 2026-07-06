import 'package:flutter/material.dart';
import 'package:lizunemu/data/models/works/work.dart';
import 'package:lizunemu/widgets/work_row.dart';
import 'package:lizunemu/presentation/layouts/work_layout_strategy.dart';

class WorkGrid extends StatelessWidget {
  final List<Work> works;
  final void Function(Work work)? onWorkTap;
  final void Function(String apiTagName)? onTagInclude;
  final void Function(String apiTagName)? onTagExclude;
  final WorkLayoutStrategy layoutStrategy;

  const WorkGrid({
    super.key,
    required this.works,
    this.onWorkTap,
    this.onTagInclude,
    this.onTagExclude,
    this.layoutStrategy = const WorkLayoutStrategy(),
  });

  @override
  Widget build(BuildContext context) {
    final columnsCount = layoutStrategy.getColumnsCount(context);
    final rows = layoutStrategy.groupWorksIntoRows(works, columnsCount);
    final rowSpacing = layoutStrategy.getRowSpacing(context);
    final columnSpacing = layoutStrategy.getColumnSpacing(context);

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index >= rows.length) return null;
          return Padding(
            padding: EdgeInsets.only(
                bottom: index < rows.length - 1 ? rowSpacing : 0),
            child: WorkRow(
              works: rows[index],
              columnCount: columnsCount,
              onWorkTap: onWorkTap,
              onTagInclude: onTagInclude,
              onTagExclude: onTagExclude,
              spacing: columnSpacing,
            ),
          );
        },
        childCount: rows.length,
      ),
    );
  }
}
