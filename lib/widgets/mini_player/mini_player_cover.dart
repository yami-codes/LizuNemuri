import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lizunemu/widgets/common/skeleton_pulse.dart';
import 'package:lizunemu/core/image/cache/image_cache_manager.dart';

/// Mini player artwork — circular to match full-screen [CircularCover] Hero flight.
class MiniPlayerCover extends StatelessWidget {
  final String? coverUrl;
  final double size;

  const MiniPlayerCover({
    super.key,
    this.coverUrl,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    if (coverUrl == null) {
      return _buildEmptyPlaceholder(context);
    }

    final dpr = MediaQuery.of(context).devicePixelRatio;
    int? cacheWidth;
    if (size.isFinite && size > 0) {
      final p = (size * dpr).round();
      cacheWidth = p < 1 ? 1 : p;
    }
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: coverUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        memCacheWidth: cacheWidth,
        fadeInDuration: const Duration(milliseconds: 150),
        cacheManager: ImageCacheManager.instance,
        placeholder: (context, url) => _buildPlaceholder(context),
        errorWidget: (context, url, error) => _buildErrorWidget(context),
      ),
    );
  }

  Widget _buildEmptyPlaceholder(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cs.surfaceContainerHighest,
      ),
      child: Icon(Icons.music_note, size: size * 0.45, color: cs.onSurfaceVariant),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return SkeletonPulse(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cs.errorContainer,
      ),
      child: Icon(Icons.broken_image, size: size * 0.4, color: cs.error),
    );
  }
}
