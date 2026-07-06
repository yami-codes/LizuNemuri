import 'package:flutter/material.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/core/theme/app_radius.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';
import 'package:lizunemu/presentation/models/filter_state.dart';
import 'package:lizunemu/presentation/models/work_list_filter_preset.dart';

/// Eara-style horizontal filter chips: subtitle toggle + sort presets + more.
class AdvancedFilterBar extends StatelessWidget {
  final bool hasSubtitle;
  final FilterState filterState;
  final ValueChanged<bool> onSubtitleChanged;
  final ValueChanged<WorkListFilterPreset> onPresetSelected;
  final ValueChanged<bool>? onSortDirectionChanged;
  final bool showSortOptions;

  const AdvancedFilterBar({
    super.key,
    required this.hasSubtitle,
    required this.filterState,
    required this.onSubtitleChanged,
    required this.onPresetSelected,
    this.onSortDirectionChanged,
    this.showSortOptions = true,
  });

  Future<void> _openMoreSheet(BuildContext context) async {
    final preset = await showModalBottomSheet<WorkListFilterPreset>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pageMobile,
                  AppSpacing.space8,
                  AppSpacing.pageMobile,
                  AppSpacing.space4,
                ),
                child: Text(
                  Strings.filterMoreOptions,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ...WorkListFilterPresetX.secondaryPresets.map((preset) {
                final selected = filterState.activePreset == preset;
                return ListTile(
                  leading: Icon(
                    preset.icon,
                    color: selected ? cs.primary : cs.onSurfaceVariant,
                  ),
                  title: Text(preset.label),
                  trailing: selected
                      ? Icon(Icons.check, color: cs.primary)
                      : null,
                  onTap: () => Navigator.pop(context, preset),
                );
              }),
              if (filterState.showSortDirection &&
                  onSortDirectionChanged != null) ...[
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    filterState.isDescending
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                    color: cs.onSurfaceVariant,
                  ),
                  title: Text(
                    filterState.isDescending
                        ? Strings.sortDescending
                        : Strings.sortAscending,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onSortDirectionChanged!.call(!filterState.isDescending);
                  },
                ),
              ],
              const SizedBox(height: AppSpacing.space8),
            ],
          ),
        );
      },
    );
    if (preset != null) onPresetSelected(preset);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pageMobile,
          vertical: AppSpacing.space8,
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                label: Text(Strings.subtitleChip),
                selected: hasSubtitle,
                onSelected: onSubtitleChanged,
                showCheckmark: true,
                avatar: Icon(
                  hasSubtitle ? Icons.subtitles : Icons.subtitles_outlined,
                  size: 18,
                  color: hasSubtitle ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                ),
              ),
              if (showSortOptions) ...[
                const SizedBox(width: AppSpacing.space8),
                ...WorkListFilterPresetX.primaryPresets.map((preset) {
                  final selected = filterState.activePreset == preset;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.space8),
                    child: FilterChip(
                      label: Text(preset.label),
                      selected: selected,
                      onSelected: (_) => onPresetSelected(preset),
                      showCheckmark: false,
                      avatar: Icon(
                        preset.icon,
                        size: 18,
                        color: selected
                            ? cs.onPrimaryContainer
                            : cs.onSurfaceVariant,
                      ),
                    ),
                  );
                }),
                ActionChip(
                  avatar: Icon(Icons.tune, size: 18, color: cs.primary),
                  label: Text(Strings.filterMoreOptions),
                  onPressed: () => _openMoreSheet(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.smAll,
                    side: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
