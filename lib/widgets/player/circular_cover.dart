import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lizunemu/core/theme/app_animations.dart';
import 'package:lizunemu/core/theme/app_radius.dart';
import 'package:lizunemu/core/image/cache/image_cache_manager.dart';
import 'package:lizunemu/widgets/common/skeleton_pulse.dart';

/// Player cover: rounded-square album art with track crossfade + play breathe.
class CircularCover extends StatefulWidget {
  const CircularCover({
    super.key,
    this.coverUrl,
    this.maxSize = 320,
    this.ringColor,
    this.albumArtStyle = false,
    this.isPlaying = true,
  });

  final String? coverUrl;
  final double maxSize;
  final Color? ringColor;
  final bool albumArtStyle;
  final bool isPlaying;

  @override
  State<CircularCover> createState() => _CircularCoverState();
}

class _CircularCoverState extends State<CircularCover> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = widget.albumArtStyle ? AppRadius.lgAll : null;
    final playScale = widget.isPlaying ? 1.0 : 0.92;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: playScale),
      duration: AppAnimations.medium,
      curve: AppAnimations.standard,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: widget.maxSize,
            maxHeight: widget.maxSize,
          ),
          decoration: BoxDecoration(
            shape: widget.albumArtStyle ? BoxShape.rectangle : BoxShape.circle,
            borderRadius: radius,
            color: cs.surfaceContainerHighest,
            border: widget.albumArtStyle
                ? null
                : Border.all(
                    color: widget.ringColor ??
                        cs.primary.withValues(alpha: 0.25),
                    width: 2,
                  ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: widget.albumArtStyle ? 0.28 : 0.12,
                ),
                blurRadius: widget.albumArtStyle ? 40 : 24,
                offset: Offset(0, widget.albumArtStyle ? 16 : 10),
              ),
            ],
          ),
          child: widget.albumArtStyle
              ? ClipRRect(
                  borderRadius: radius!,
                  child: _buildAnimatedImage(context, cs),
                )
              : ClipOval(
                  child: _buildAnimatedImage(context, cs),
                ),
        ),
      ),
    );
  }

  Widget _buildAnimatedImage(BuildContext context, ColorScheme cs) {
    return AnimatedSwitcher(
      duration: AppAnimations.long,
      switchInCurve: AppAnimations.enter,
      switchOutCurve: AppAnimations.exit,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
      child: widget.coverUrl != null
          ? LayoutBuilder(
              key: ValueKey(widget.coverUrl),
              builder: (context, constraints) {
                final dpr = MediaQuery.of(context).devicePixelRatio;
                final w = constraints.maxWidth;
                int? cacheWidth;
                if (w.isFinite && w > 0) {
                  final p = (w * dpr).round();
                  cacheWidth = p < 1 ? 1 : p;
                }
                return CachedNetworkImage(
                  imageUrl: widget.coverUrl!,
                  fit: BoxFit.cover,
                  memCacheWidth: cacheWidth,
                  fadeInDuration: AppAnimations.short,
                  cacheManager: ImageCacheManager.instance,
                  placeholder: (context, url) => SkeletonPulse(
                    child: Container(color: cs.surfaceContainerHighest),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: cs.errorContainer,
                    child: Center(
                      child: Icon(
                        Icons.error_outline,
                        size: 48,
                        color: cs.error,
                      ),
                    ),
                  ),
                );
              },
            )
          : Icon(
              key: const ValueKey('no-cover'),
              Icons.music_note,
              size: 96,
              color: cs.onSurfaceVariant,
            ),
    );
  }
}
