import 'package:flutter/material.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';
import 'package:lizunemu/presentation/models/filter_state.dart';
import 'package:lizunemu/widgets/filter/advanced_filter_bar.dart';

/// Subtitle-only filter strip for recommend / similar (API has no sort).
class FilterWithKeyword extends StatelessWidget {
  final bool hasSubtitle;
  final ValueChanged<bool> onSubtitleChanged;

  const FilterWithKeyword({
    super.key,
    required this.hasSubtitle,
    required this.onSubtitleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pageMobile,
          vertical: AppSpacing.space8,
        ),
        child: AdvancedFilterBar(
          hasSubtitle: hasSubtitle,
          filterState: const FilterState(),
          onSubtitleChanged: onSubtitleChanged,
          onPresetSelected: (_) {},
          showSortOptions: false,
        ),
      ),
    );
  }
}
