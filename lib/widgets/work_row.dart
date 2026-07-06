import 'package:flutter/material.dart';
import 'package:lizunemu/data/models/works/work.dart';
import 'package:lizunemu/widgets/work_card/work_card.dart';

class WorkRow extends StatelessWidget {
  final List<Work> works;
  final int columnCount;
  final void Function(Work work)? onWorkTap;
  final Map<String, String>? translatedTitles;
  final void Function(String apiTagName)? onTagInclude;
  final void Function(String apiTagName)? onTagExclude;
  final double spacing;

  const WorkRow({
    super.key,
    required this.works,
    required this.columnCount,
    this.onWorkTap,
    this.translatedTitles,
    this.onTagInclude,
    this.onTagExclude,
    this.spacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final slots = columnCount < 1 ? 1 : columnCount;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < slots; i++) ...[
          if (i > 0) SizedBox(width: spacing),
          Expanded(
            child: i < works.length
                ? WorkCard(
                    work: works[i],
                    onTap:
                        onWorkTap != null ? () => onWorkTap!(works[i]) : null,
                    translatedTitles: translatedTitles,
                    onTagInclude: onTagInclude,
                    onTagExclude: onTagExclude,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ],
    );
  }
}
