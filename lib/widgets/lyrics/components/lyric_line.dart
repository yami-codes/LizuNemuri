import 'package:flutter/material.dart';
import 'package:lizunemu/core/audio/models/subtitle.dart';
import 'package:lizunemu/core/theme/app_animations.dart';
import 'package:lizunemu/core/theme/app_radius.dart';

/// Material 3 lyric row — one primary line; optional original only while active.
class LyricLine extends StatelessWidget {
  final Subtitle subtitle;
  final String? secondaryText;
  /// 0–1 emphasis (viewport proximity × playback active).
  final double emphasis;
  final VoidCallback? onTap;

  const LyricLine({
    super.key,
    required this.subtitle,
    this.secondaryText,
    this.emphasis = 0.35,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: emphasis.clamp(0.0, 1.0)),
      duration: AppAnimations.medium,
      curve: AppAnimations.standard,
      builder: (context, t, _) => _LyricLineBody(
        subtitle: subtitle,
        secondaryText: secondaryText,
        emphasis: t,
        onTap: onTap,
      ),
    );
  }
}

class _LyricLineBody extends StatelessWidget {
  const _LyricLineBody({
    required this.subtitle,
    required this.secondaryText,
    required this.emphasis,
    required this.onTap,
  });

  final Subtitle subtitle;
  final String? secondaryText;
  final double emphasis;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isActive = emphasis > 0.88;
    final opacity = 0.35 + 0.65 * emphasis;

    final primaryStyle = (isActive
            ? textTheme.titleLarge
            : textTheme.bodyLarge)
        ?.copyWith(
      height: 1.35,
      color: isActive ? cs.onSurface : cs.onSurfaceVariant,
      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
    );

    final secondaryStyle = textTheme.bodySmall?.copyWith(
      height: 1.25,
      color: cs.onSurfaceVariant.withValues(alpha: 0.85),
      fontWeight: FontWeight.w400,
    );

    Widget textContent = secondaryText == null
        ? Text(
            subtitle.text,
            style: primaryStyle,
            textAlign: TextAlign.center,
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                secondaryText!,
                style: secondaryStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle.text,
                style: primaryStyle,
                textAlign: TextAlign.center,
              ),
            ],
          );

    if (isActive) {
      textContent = DecoratedBox(
        decoration: BoxDecoration(
          color: cs.primaryContainer.withValues(alpha: 0.35),
          borderRadius: AppRadius.mdAll,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: textContent,
        ),
      );
    }

    return RepaintBoundary(
      child: Center(
        child: Opacity(
          opacity: opacity,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              child: textContent,
            ),
          ),
        ),
      ),
    );
  }
}
