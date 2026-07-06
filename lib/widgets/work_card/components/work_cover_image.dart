import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lizunemu/widgets/common/skeleton_pulse.dart';
import 'package:lizunemu/core/image/cache/image_cache_manager.dart';

class WorkCoverImage extends StatelessWidget {
  final String imageUrl;
  final int workId;
  final String sourceId;

  /// Work duration in seconds; shows bottom-left badge on cover when set.
  final int? durationSeconds;

  // 195/146 ≈ 1.336
  static const double _aspectRatio = 195 / 146;

  const WorkCoverImage({
    super.key,
    required this.imageUrl,
    required this.workId,
    required this.sourceId,
    this.durationSeconds,
  });

  static String _fmtDuration(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = sec.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$m:$ss';
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _aspectRatio,
      child: Stack(
        children: [
          Hero(
            tag: 'work-cover-$workId',
            child: LayoutBuilder(
              builder: (context, constraints) {
                final dpr = MediaQuery.of(context).devicePixelRatio;
                final w = constraints.maxWidth;
                int? cacheWidth;
                if (w.isFinite && w > 0) {
                  final p = (w * dpr).round();
                  cacheWidth = p < 1 ? 1 : p;
                }
                return CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  memCacheWidth: cacheWidth,
                  fadeInDuration: const Duration(milliseconds: 150),
                  cacheManager: ImageCacheManager.instance,
                  placeholder: (context, url) => SkeletonPulse(
                    child: Container(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Center(
                      child: Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            left: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                sourceId,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontSize: 12,
                    ),
              ),
            ),
          ),
          if (durationSeconds != null && durationSeconds! > 0)
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _fmtDuration(durationSeconds!),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
