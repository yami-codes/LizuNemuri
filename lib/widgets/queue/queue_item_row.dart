import 'package:flutter/material.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';

/// Tachiyomi download_item–style row: title, one status line, optional bar.
class QueueItemRow extends StatelessWidget {
  final String title;
  final String statusLabel;
  final bool statusIsError;
  final bool showProgress;
  final bool progressIndeterminate;
  final double? progressValue;
  final String? progressTrailing;
  final VoidCallback? onRetry;
  final String? retryTooltip;
  final VoidCallback? onCancel;
  final String? cancelTooltip;

  const QueueItemRow({
    super.key,
    required this.title,
    required this.statusLabel,
    this.statusIsError = false,
    this.showProgress = false,
    this.progressIndeterminate = false,
    this.progressValue,
    this.progressTrailing,
    this.onRetry,
    this.retryTooltip,
    this.onCancel,
    this.cancelTooltip,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space16,
        AppSpacing.space4,
        AppSpacing.space8,
        AppSpacing.space8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    Text(
                      statusLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: statusIsError
                                ? scheme.error
                                : scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              if (onRetry != null)
                IconButton(
                  tooltip: retryTooltip,
                  onPressed: onRetry,
                  icon: Icon(Icons.refresh, color: scheme.primary),
                ),
              if (onCancel != null)
                IconButton(
                  tooltip: cancelTooltip,
                  onPressed: onCancel,
                  icon: Icon(Icons.close, color: scheme.onSurfaceVariant),
                ),
            ],
          ),
          if (showProgress) ...[
            const SizedBox(height: AppSpacing.space8),
            Row(
              children: [
                Expanded(
                  child: progressIndeterminate
                      ? const LinearProgressIndicator()
                      : LinearProgressIndicator(
                          value: (progressValue ?? 0).clamp(0.0, 1.0),
                        ),
                ),
                if (progressTrailing != null &&
                    progressTrailing!.isNotEmpty) ...[
                  const SizedBox(width: AppSpacing.space8),
                  Text(
                    progressTrailing!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
