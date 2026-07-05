import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';
import 'package:lizunemu/presentation/viewmodels/popular_viewmodel.dart';
import 'package:lizunemu/screens/contents/popular_content.dart';

/// Eara-style "Hot" tab — popular grid + quick filter chips (Milestone E).
class HotTabContent extends StatelessWidget {
  const HotTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageMobile,
            AppSpacing.space8,
            AppSpacing.pageMobile,
            AppSpacing.space4,
          ),
          child: Consumer<PopularViewModel>(
            builder: (context, vm, _) => Wrap(
              spacing: AppSpacing.space8,
              runSpacing: AppSpacing.space4,
              children: [
                FilterChip(
                  label: Text(Strings.subtitleChip),
                  selected: vm.hasSubtitle,
                  onSelected: (_) => vm.toggleSubtitleFilter(),
                  showCheckmark: true,
                ),
                ActionChip(
                  avatar: const Icon(Icons.filter_list, size: 18),
                  label: Text(Strings.filterOrderDefault),
                  onPressed: () => vm.toggleFilterPanel(),
                ),
              ],
            ),
          ),
        ),
        const Expanded(child: PopularContent()),
      ],
    );
  }
}
