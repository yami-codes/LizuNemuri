import 'package:flutter/material.dart';
import 'package:lizunemu/presentation/models/filter_state.dart';
import 'package:lizunemu/presentation/models/work_list_filter_preset.dart';
import 'package:lizunemu/widgets/filter/advanced_filter_bar.dart';

/// Slide-down filter panel for browse lists (wraps [AdvancedFilterBar]).
class FilterPanel extends StatelessWidget {
  final bool hasSubtitle;
  final FilterState filterState;
  final ValueChanged<bool> onSubtitleChanged;
  final ValueChanged<WorkListFilterPreset> onPresetSelected;
  final ValueChanged<bool> onSortDirectionChanged;

  const FilterPanel({
    super.key,
    required this.hasSubtitle,
    required this.filterState,
    required this.onSubtitleChanged,
    required this.onPresetSelected,
    required this.onSortDirectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AdvancedFilterBar(
      hasSubtitle: hasSubtitle,
      filterState: filterState,
      onSubtitleChanged: onSubtitleChanged,
      onPresetSelected: onPresetSelected,
      onSortDirectionChanged: onSortDirectionChanged,
    );
  }
}
