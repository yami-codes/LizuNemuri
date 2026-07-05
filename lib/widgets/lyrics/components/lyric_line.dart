import 'package:flutter/material.dart';
import 'package:xuro/core/audio/models/subtitle.dart';
import 'package:xuro/core/theme/app_animations.dart';
import 'package:xuro/widgets/player/player_immersive_scope.dart';

class LyricLine extends StatelessWidget {
  final Subtitle subtitle;
  final String? secondaryText;
  final bool isActive;
  final double opacity;
  final VoidCallback? onTap;

  const LyricLine({
    super.key,
    required this.subtitle,
    this.secondaryText,
    this.isActive = false,
    this.opacity = 1.0,
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

    final primaryStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontSize: 20,
          height: 1.3,
          color: isActive ? activeColor : inactiveColor,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          shadows: shadow,
        );

    final secondaryStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: 15,
          height: 1.25,
          color: (isActive ? activeColor : inactiveColor)
              .withValues(alpha: isActive ? 0.75 : 0.45),
          fontWeight: FontWeight.normal,
          shadows: shadow,
        );

    return RepaintBoundary(
      child: Center(
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
    );
  }
}
