import 'package:flutter/material.dart';
import 'package:lizunemu/core/audio/models/subtitle.dart';
import 'package:lizunemu/core/theme/app_animations.dart';
import 'package:lizunemu/widgets/player/player_immersive_scope.dart';

class LyricLine extends StatelessWidget {
  final Subtitle subtitle;
  final String? secondaryText;
  /// 0–1 kinetic emphasis (viewport proximity + active line boost).
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

    final t = emphasis.clamp(0.0, 1.0);
    final scale = 0.88 + 0.12 * t;
    final opacity = 0.28 + 0.72 * t;
    final primarySize = 15.0 + 11.0 * t;
    final secondarySize = 13.0 + 5.0 * t;
    final fontWeight = FontWeight.lerp(FontWeight.w400, FontWeight.w700, t)!;
    final letterSpacing = 0.1 + 0.35 * t;

    final primaryStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontSize: primarySize,
          height: 1.35,
          letterSpacing: letterSpacing,
          color: Color.lerp(inactiveColor, activeColor, t),
          fontWeight: fontWeight,
          shadows: t > 0.85
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
          fontSize: secondarySize,
          height: 1.25,
          color: Color.lerp(
            inactiveColor.withValues(alpha: 0.45),
            activeColor.withValues(alpha: 0.75),
            t,
          ),
          fontWeight: FontWeight.lerp(FontWeight.w400, FontWeight.w500, t),
          shadows: shadow,
        );

    return RepaintBoundary(
      child: Center(
        child: AnimatedScale(
          scale: scale,
          duration: AppAnimations.medium,
          curve: AppAnimations.standard,
          alignment: Alignment.center,
          child: AnimatedOpacity(
            duration: AppAnimations.medium,
            opacity: opacity,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: secondaryText == null
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
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
