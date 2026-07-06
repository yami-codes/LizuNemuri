import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';
import 'package:lizunemu/presentation/viewmodels/popular_viewmodel.dart';
import 'package:lizunemu/screens/contents/popular_content.dart';
import 'package:lizunemu/widgets/filter/advanced_filter_bar.dart';

/// Eara-style "Hot" tab — popular grid + quick filter chips (Milestone E).
class HotTabContent extends StatelessWidget {
  const HotTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Consumer<PopularViewModel>(
          builder: (context, vm, _) => AdvancedFilterBar(
            hasSubtitle: vm.hasSubtitle,
            filterState: vm.filterState,
            onSubtitleChanged: (_) => vm.toggleSubtitleFilter(),
            onPresetSelected: vm.updatePreset,
            onSortDirectionChanged: vm.updateSortDirection,
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        const Expanded(child: PopularContent()),
      ],
    );
  }
}
