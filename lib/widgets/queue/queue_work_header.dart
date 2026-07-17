import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lizunemu/core/image/cache/image_cache_manager.dart';
import 'package:lizunemu/core/theme/app_radius.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';
import 'package:lizunemu/data/models/works/work.dart';

/// Tachiyomi-style work group header for queue screens.
class QueueWorkHeader extends StatelessWidget {
  static const double coverSize = 48;

  final Work work;
  final String title;
  final String? kindLabel;
  final VoidCallback? onCancel;
  final String? cancelTooltip;

  const QueueWorkHeader({
    super.key,
    required this.work,
    required this.title,
    this.kindLabel,
    this.onCancel,
    this.cancelTooltip,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final coverUrl = work.thumbnailCoverUrl ?? work.mainCoverUrl ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space16,
        AppSpacing.space16,
        AppSpacing.space8,
        AppSpacing.space8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: AppRadius.smAll,
            child: SizedBox(
              width: coverSize,
              height: coverSize,
              child: coverUrl.isEmpty
                  ? ColoredBox(
                      color: scheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.album_outlined,
                        color: scheme.onSurfaceVariant,
                        size: 24,
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: coverUrl,
                      fit: BoxFit.cover,
                      width: coverSize,
                      height: coverSize,
                      memCacheWidth: 96,
                      fadeInDuration: const Duration(milliseconds: 120),
                      cacheManager: ImageCacheManager.instance,
                      errorWidget: (_, __, ___) => ColoredBox(
                        color: scheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: scheme.onSurfaceVariant,
                          size: 22,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (kindLabel != null && kindLabel!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.space4),
                  Text(
                    kindLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (onCancel != null)
            IconButton(
              tooltip: cancelTooltip,
              onPressed: onCancel,
              icon: Icon(Icons.close, color: scheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}
