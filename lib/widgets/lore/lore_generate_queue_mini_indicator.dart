import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/core/lore/lore_generate_queue_service.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';
import 'package:lizunemu/screens/lore_generate_queue_screen.dart';
import 'package:lizunemu/widgets/lore/lore_progress_labels.dart';

/// Compact bar above the mini player while lore generation queue is active.
class LoreGenerateQueueMiniIndicator extends StatelessWidget {
  static const height = 36.0;

  const LoreGenerateQueueMiniIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final queue = GetIt.I<LoreGenerateQueueService>();
    return ListenableBuilder(
      listenable: queue,
      builder: (context, _) {
        final snap = queue.snapshot;
        if (!snap.isActive) return const SizedBox.shrink();

        final scheme = Theme.of(context).colorScheme;
        final stage = snap.progressStage;
        final stageBit = stage == null || stage.isEmpty
            ? null
            : LoreProgressLabels.forStage(stage);
        final elapsed = snap.stageStartedAt == null
            ? null
            : DateTime.now().difference(snap.stageStartedAt!).inSeconds;
        final waitBit = snap.waitingOnLlm
            ? [
                Strings.loreProgressWaitingLlm,
                if (elapsed != null) Strings.loreProgressElapsed(elapsed),
              ].join(' ')
            : null;

        final label = snap.currentWorkTitle != null
            ? [
                Strings.loreQueueMiniProgress(
                  snap.completedJobs,
                  snap.totalJobs,
                  snap.currentWorkTitle!,
                ),
                if (waitBit != null) waitBit else if (stageBit != null) stageBit,
              ].join(' · ')
            : Strings.loreQueueMiniIdle(
                snap.completedJobs,
                snap.totalJobs,
              );

        return Material(
          color: scheme.surfaceContainerHighest,
          child: InkWell(
            onTap: () => openLoreGenerateQueueScreen(context),
            child: SizedBox(
              height: height,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
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
                          value: snap.waitingOnLlm ? null : snap.progress,
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
