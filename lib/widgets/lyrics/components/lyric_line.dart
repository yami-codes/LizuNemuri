import 'package:flutter/material.dart';
import 'package:xuro/core/audio/models/subtitle.dart';
import 'package:xuro/core/theme/app_animations.dart';
import 'package:xuro/widgets/player/player_immersive_scope.dart';

class LyricLine extends StatelessWidget {
  final Subtitle subtitle;
  final bool isActive;
  final double opacity;
  final VoidCallback? onTap;

  const LyricLine({
    super.key,
    required this.subtitle,
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
              child: Text(
                subtitle.text,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 20,
                      height: 1.3,
                      color: isActive ? activeColor : inactiveColor,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                      shadows: immersive?.enabled == true
                          ? [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
