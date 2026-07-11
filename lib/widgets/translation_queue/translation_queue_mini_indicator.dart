import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/core/llm/translation_queue_service.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';
import 'package:lizunemu/screens/translation_queue_screen.dart';

/// Compact bar above the mini player while the translation queue is active.
class TranslationQueueMiniIndicator extends StatelessWidget {
  static const height = 36.0;

  const TranslationQueueMiniIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final queue = GetIt.I<TranslationQueueService>();
    return ListenableBuilder(
      listenable: queue,
      builder: (context, _) {
        final snap = queue.snapshot;
        if (!snap.isActive) return const SizedBox.shrink();

        final scheme = Theme.of(context).colorScheme;
        final label = snap.currentTrackName != null
            ? Strings.translationQueueMiniProgress(
                snap.completedTracks,
                snap.totalTracks,
                snap.currentTrackName!,
              )
            : Strings.translationQueueMiniIdle(
                snap.completedTracks,
                snap.totalTracks,
              );

        return Material(
          color: scheme.surfaceContainerHighest,
          child: InkWell(
            onTap: () => openTranslationQueueScreen(context),
            child: SizedBox(
              height: height,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.translate,
                      size: 18,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.space8),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                    if (snap.progress != null)
                      SizedBox(
                        width: 72,
                        child: LinearProgressIndicator(
                          value: snap.progress,
                          minHeight: 4,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
