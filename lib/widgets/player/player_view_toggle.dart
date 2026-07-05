import 'package:flutter/material.dart';
import 'package:xuro/core/theme/app_animations.dart';
import 'package:xuro/core/theme/app_radius.dart';
import 'package:xuro/core/theme/app_spacing.dart';

/// Mobile player cover / subtitle mode switcher.
class PlayerViewToggle extends StatelessWidget {
  final bool showSubtitles;
  final ValueChanged<bool> onChanged;
  final String coverLabel;
  final String subtitlesLabel;

  const PlayerViewToggle({
    super.key,
    required this.showSubtitles,
    required this.onChanged,
    required this.coverLabel,
    required this.subtitlesLabel,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space16,
        AppSpacing.space8,
        AppSpacing.space16,
        AppSpacing.space4,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.65),
          borderRadius: AppRadius.fullAll,
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final half = constraints.maxWidth / 2;
            return SizedBox(
              height: 40,
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: AppAnimations.medium,
                    curve: AppAnimations.smoothScroll,
                    left: showSubtitles ? half : 0,
                    top: 3,
                    bottom: 3,
                    width: half,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: AppRadius.fullAll,
                        boxShadow: [
                          BoxShadow(
                            color: cs.primary.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      _Segment(
                        label: coverLabel,
                        icon: Icons.album_outlined,
                        selected: !showSubtitles,
                        onTap: () => onChanged(false),
                        selectedColor: cs.onPrimary,
                        unselectedColor: cs.onSurfaceVariant,
                      ),
                      _Segment(
                        label: subtitlesLabel,
                        icon: Icons.subtitles_outlined,
                        selected: showSubtitles,
                        onTap: () => onChanged(true),
                        selectedColor: cs.onPrimary,
                        unselectedColor: cs.onSurfaceVariant,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedColor;
  final Color unselectedColor;

  const _Segment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.selectedColor,
    required this.unselectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? selectedColor : unselectedColor;
    return Expanded(
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.fullAll,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: AppSpacing.space4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: color,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
