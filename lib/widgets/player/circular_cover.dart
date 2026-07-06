import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lizunemu/core/theme/app_radius.dart';
import 'package:lizunemu/core/image/cache/image_cache_manager.dart';
import 'package:lizunemu/widgets/common/skeleton_pulse.dart';

/// Player cover: circular or Apple Music-style rounded-square album art.
class CircularCover extends StatelessWidget {
  const CircularCover({
    super.key,
    this.coverUrl,
    this.maxSize = 320,
    this.ringColor,
    this.albumArtStyle = false,
  });

  final String? coverUrl;
  final double maxSize;
  final Color? ringColor;
  /// When true, uses rounded-square album art (Apple Music Now Playing).
  final bool albumArtStyle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = albumArtStyle ? AppRadius.lgAll : null;
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxSize, maxHeight: maxSize),
        decoration: BoxDecoration(
          shape: albumArtStyle ? BoxShape.rectangle : BoxShape.circle,
          borderRadius: radius,
          color: cs.surfaceContainerHighest,
          border: albumArtStyle
              ? null
              : Border.all(
                  color: ringColor ?? cs.primary.withValues(alpha: 0.25),
                  width: 2,
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: albumArtStyle ? 0.28 : 0.12),
              blurRadius: albumArtStyle ? 40 : 24,
              offset: Offset(0, albumArtStyle ? 16 : 10),
            ),
          ],
        ),
        child: albumArtStyle
            ? ClipRRect(
                borderRadius: radius!,
                child: _buildImage(context, cs, coverUrl),
              )
            : ClipOval(
                child: _buildImage(context, cs, coverUrl),
              ),
      ),
    );
  }

  Widget _buildImage(BuildContext context, ColorScheme cs, String? coverUrl) {
    return coverUrl != null
        ? LayoutBuilder(
            builder: (context, constraints) {
              final dpr = MediaQuery.of(context).devicePixelRatio;
              final w = constraints.maxWidth;
              int? cacheWidth;
              if (w.isFinite && w > 0) {
                final p = (w * dpr).round();
                cacheWidth = p < 1 ? 1 : p;
              }
              return CachedNetworkImage(
                imageUrl: coverUrl,
                fit: BoxFit.cover,
                memCacheWidth: cacheWidth,
                fadeInDuration: const Duration(milliseconds: 150),
                cacheManager: ImageCacheManager.instance,
                placeholder: (context, url) => SkeletonPulse(
                  child: Container(color: cs.surfaceContainerHighest),
                ),
                errorWidget: (context, url, error) => Container(
                  color: cs.errorContainer,
                  child: Center(
                    child: Icon(Icons.error_outline,
                        size: 48, color: cs.error),
                  ),
                ),
              );
            },
          )
        : Icon(Icons.music_note, size: 96, color: cs.onSurfaceVariant);
  }
}
