import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lizunemu/core/audio/models/subtitle.dart';
import 'package:lizunemu/core/theme/app_animations.dart';
import 'package:lizunemu/widgets/player/player_immersive_scope.dart';

/// Apple Music kinetic lyric line — fixed typography; opacity/blur/scale only.
class LyricLine extends StatelessWidget {
  final Subtitle subtitle;
  final String? secondaryText;
  /// 0–1 kinetic emphasis (viewport proximity).
  final double emphasis;
  final VoidCallback? onTap;

  const LyricLine({
    super.key,
    required this.subtitle,
    this.secondaryText,
    this.emphasis = 0.35,
    this.onTap,
  });

  static const double primaryFontSize = 22;
  static const double secondaryFontSize = 17;

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
    final immersive = PlayerImmersiveScope.maybeOf(context);
    final cs = Theme.of(context).colorScheme;
    final activeColor = immersive?.enabled == true
        ? immersive!.activeLyric
        : cs.primary;
    final inactiveColor = immersive?.enabled == true
        ? immersive!.inactiveLyric
        : cs.onSurface.withValues(alpha: 0.7);

    final shadow = immersive?.enabled == true
        ? [
            Shadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 8,
            ),
          ]
        : null;

    final t = emphasis;
    final opacity = 0.28 + 0.72 * t;
    final scale = 0.92 + 0.10 * t;
    final blurSigma = (1.0 - t) * 2.0;
    final isActive = t > 0.82;

    final primaryStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontSize: LyricLine.primaryFontSize,
          height: 1.35,
          letterSpacing: isActive ? 0.35 : 0.15,
          color: Color.lerp(inactiveColor, activeColor, t),
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          shadows: isActive
              ? [
                  ...(shadow ?? []),
                  Shadow(
                    color: activeColor.withValues(alpha: 0.35),
                    blurRadius: 12,
                  ),
                ]
              : shadow,
        );

    final secondaryStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: LyricLine.secondaryFontSize,
          height: 1.25,
          letterSpacing: 0.1,
          color: Color.lerp(
            inactiveColor.withValues(alpha: 0.45),
            activeColor.withValues(alpha: 0.75),
            t,
          ),
          fontWeight: FontWeight.w500,
          shadows: shadow,
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

    if (blurSigma > 0.25) {
      textContent = ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: blurSigma,
          sigmaY: blurSigma,
          tileMode: TileMode.clamp,
        ),
        child: textContent,
      );
    }

    return RepaintBoundary(
      child: Center(
        child: Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.center,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: textContent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
