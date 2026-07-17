import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/core/llm/subtitle_translation_progress.dart';
import 'package:lizunemu/core/llm/translation_queue_models.dart';
import 'package:lizunemu/core/llm/translation_queue_service.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';
import 'package:lizunemu/widgets/common/back_leading.dart';
import 'package:lizunemu/widgets/queue/queue_empty_state.dart';
import 'package:lizunemu/widgets/queue/queue_item_row.dart';
import 'package:lizunemu/widgets/queue/queue_work_header.dart';

/// Full-page translation queue (sidebar + mini-indicator entry).
class TranslationQueueScreen extends StatelessWidget {
  const TranslationQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final queue = GetIt.I<TranslationQueueService>();
    return ListenableBuilder(
      listenable: queue,
      builder: (context, _) {
        final activeCount =
            queue.snapshot.runningTracks +
            (queue.jobs.fold<int>(
              0,
              (n, j) =>
                  n +
                  j.tracks
                      .where(
                        (t) => t.status == TranslationQueueTrackStatus.pending,
                      )
                      .length,
            ));

        return Scaffold(
          appBar: AppBar(
            leading: const BackLeading(),
            automaticallyImplyLeading: false,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(Strings.translationQueueTitle),
                if (activeCount > 0)
                  Text(
                    Strings.loreQueueActiveCount(activeCount),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
              ],
            ),
            actions: [
              if (queue.jobs.any((j) => j.failedCount > 0))
                TextButton(
                  onPressed: () => queue.retryFailed(),
                  child: Text(Strings.translationQueueRetryFailed),
                ),
              if (queue.hasWork)
                TextButton(
                  onPressed: () => queue.cancelAll(),
                  child: Text(Strings.translationQueueCancelAll),
                ),
              if (queue.jobs.any((j) => j.isFinished))
                IconButton(
                  tooltip: Strings.translationQueueClearFinished,
                  onPressed: () => queue.clearFinished(),
                  icon: const Icon(Icons.cleaning_services_outlined),
                ),
            ],
          ),
          body: queue.jobs.isEmpty
              ? QueueEmptyState(message: Strings.translationQueueEmpty)
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: AppSpacing.space64),
                  itemCount: queue.jobs.length,
                  itemBuilder: (context, index) {
                    return _JobBlock(job: queue.jobs[index], queue: queue);
                  },
                ),
        );
      },
    );
  }
}

class _JobBlock extends StatelessWidget {
  final TranslationQueueJob job;
  final TranslationQueueService queue;

  const _JobBlock({required this.job, required this.queue});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QueueWorkHeader(
          work: job.work,
          title: job.workTitle,
        ),
        ...job.tracks.map(
          (track) => _TrackRow(track: track, queue: queue),
        ),
        Divider(
          height: 1,
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ],
    );
  }
}

class _TrackRow extends StatelessWidget {
  final TranslationQueueTrack track;
  final TranslationQueueService queue;

  const _TrackRow({required this.track, required this.queue});

  String _statusLabel() {
    return switch (track.status) {
      TranslationQueueTrackStatus.pending =>
        Strings.translationQueueStatusPending,
      TranslationQueueTrackStatus.running => _runningLabel(),
      TranslationQueueTrackStatus.done => Strings.translationQueueStatusDone,
      TranslationQueueTrackStatus.cached => Strings.batchTranslatePhaseCached,
      TranslationQueueTrackStatus.failed =>
        track.lastError ?? Strings.translationQueueStatusFailed,
      TranslationQueueTrackStatus.cancelled =>
        Strings.translationQueueStatusCancelled,
    };
  }

  String _runningLabel() {
    if (track.phase == BatchTranslatePhase.translating &&
        track.llmBatchIndex != null &&
        track.llmBatchTotal != null) {
      return Strings.batchTranslatePhaseTranslating(
        track.llmBatchIndex!,
        track.llmBatchTotal!,
      );
    }
    return switch (track.phase) {
      BatchTranslatePhase.loadingSubtitle =>
        Strings.batchTranslatePhaseLoading,
      BatchTranslatePhase.checkingCache =>
        Strings.batchTranslatePhaseCheckingCache,
      BatchTranslatePhase.failed => Strings.batchTranslatePhaseFailed,
      BatchTranslatePhase.cached => Strings.batchTranslatePhaseCached,
      _ => Strings.batchTranslatePhaseTranslatingSimple,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isFailed = track.status == TranslationQueueTrackStatus.failed;
    final isRunning = track.status == TranslationQueueTrackStatus.running;
    final canCancel = track.status == TranslationQueueTrackStatus.pending ||
        track.status == TranslationQueueTrackStatus.running;

    final batchTotal = track.llmBatchTotal;
    final batchIndex = track.llmBatchIndex;
    final hasBatch = isRunning &&
        batchTotal != null &&
        batchTotal > 0 &&
        batchIndex != null;

    return QueueItemRow(
      title: track.trackName,
      statusLabel: _statusLabel(),
      statusIsError: isFailed,
      showProgress: isRunning,
      progressIndeterminate: !hasBatch,
      progressValue: hasBatch ? batchIndex / batchTotal : null,
      progressTrailing: hasBatch ? '$batchIndex/$batchTotal' : null,
      onRetry: isFailed ? () => queue.retryTrack(track.id) : null,
      retryTooltip: Strings.translationQueueRetry,
      onCancel: canCancel ? () => queue.cancelTrack(track.id) : null,
      cancelTooltip: Strings.downloadCancel,
    );
  }
}

/// Opens [TranslationQueueScreen] on the root navigator.
void openTranslationQueueScreen(BuildContext context) {
  Navigator.of(context, rootNavigator: true).push(
    CupertinoPageRoute(builder: (_) => const TranslationQueueScreen()),
  );
}
