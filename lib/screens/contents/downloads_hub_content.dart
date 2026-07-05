import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xuro/common/constants/strings.dart';
import 'package:xuro/core/download/utils/download_grouping.dart';
import 'package:xuro/core/theme/app_radius.dart';
import 'package:xuro/core/theme/app_spacing.dart';
import 'package:xuro/core/theme/app_text_styles.dart';
import 'package:xuro/presentation/viewmodels/downloads_viewmodel.dart';
import 'package:xuro/screens/detail_screen.dart';
import 'package:xuro/utils/file_size_formatter.dart';
import 'package:xuro/utils/user_facing_error.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:xuro/core/image/cache/image_cache_manager.dart';
import 'package:xuro/widgets/common/skeleton_pulse.dart';

/// Downloads list grouped by work — Eara [DownloadsScreen] hub pattern.
class DownloadsHubContent extends StatefulWidget {
  const DownloadsHubContent({super.key});

  @override
  State<DownloadsHubContent> createState() => _DownloadsHubContentState();
}

class _DownloadsHubContentState extends State<DownloadsHubContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DownloadsViewModel>().load();
    });
  }

  Future<void> _playGroup(DownloadWorkGroup group) async {
    final vm = context.read<DownloadsViewModel>();
    try {
      await vm.playGroup(group);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Strings.playFailed(userFacingError(e)))),
      );
    }
  }

  void _openDetail(DownloadWorkGroup group) {
    final work = context.read<DownloadsViewModel>().workFor(group);
    Navigator.of(context, rootNavigator: true).push(
      CupertinoPageRoute(
        builder: (_) => DetailScreen(work: work),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DownloadsViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading && vm.groups.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (vm.error != null && vm.groups.isEmpty) {
          return _ErrorState(
            message: vm.error!,
            onRetry: vm.refresh,
          );
        }
        if (vm.isEmpty) {
          return _EmptyState();
        }
        return RefreshIndicator(
          onRefresh: vm.refresh,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageMobile,
              AppSpacing.space12,
              AppSpacing.pageMobile,
              AppSpacing.space64,
            ),
            itemCount: vm.groups.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpacing.space8),
            itemBuilder: (context, index) {
              final group = vm.groups[index];
              return _DownloadWorkTile(
                group: group,
                title: vm.displayTitleFor(group),
                subtitleId: vm.subtitleIdFor(group),
                coverUrl: vm.metaFor(group.workId)?.coverUrl,
                sourceId: vm.metaFor(group.workId)?.sourceId ?? group.workId,
                onTap: () => _openDetail(group),
                onPlay: group.hasPlayableAudio
                    ? () => _playGroup(group)
                    : null,
              );
            },
          ),
        );
      },
    );
  }
}

class _DownloadWorkTile extends StatelessWidget {
  const _DownloadWorkTile({
    required this.group,
    required this.title,
    required this.subtitleId,
    required this.coverUrl,
    required this.sourceId,
    required this.onTap,
    required this.onPlay,
  });

  final DownloadWorkGroup group;
  final String title;
  final String? subtitleId;
  final String? coverUrl;
  final String sourceId;
  final VoidCallback onTap;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final summary = Strings.downloadsFileCountSummary(
      group.fileCount,
      FileSizeFormatter.format(group.totalSizeBytes),
    );

    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: AppRadius.mdAll,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: AppRadius.smAll,
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: coverUrl != null && coverUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: coverUrl!,
                          cacheManager: ImageCacheManager.instance,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => SkeletonPulse(
                            child: ColoredBox(
                              color: cs.surfaceContainerHighest,
                            ),
                          ),
                          errorWidget: (_, __, ___) => _CoverPlaceholder(
                            colorScheme: cs,
                          ),
                        )
                      : _CoverPlaceholder(colorScheme: cs),
                ),
              ),
              const SizedBox(width: AppSpacing.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: cs.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitleId != null) ...[
                      const SizedBox(height: AppSpacing.space4),
                      Text(
                        subtitleId!,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.space4),
                    Text(
                      summary,
                      style: AppTextStyles.caption.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (onPlay != null)
                IconButton(
                  tooltip: Strings.downloadsPlayA11y,
                  icon: Icon(
                    CupertinoIcons.play_circle_fill,
                    color: cs.primary,
                    size: 32,
                  ),
                  onPressed: onPlay,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: colorScheme.surfaceContainerHighest,
      child: Icon(
        CupertinoIcons.arrow_down_circle,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.arrow_down_circle,
              size: 48,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.space16),
            Text(
              Strings.downloadsEmpty,
              style: AppTextStyles.bodyLarge.copyWith(
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.space12),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(Strings.retry),
            ),
          ],
        ),
      ),
    );
  }
}
