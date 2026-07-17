import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/core/lore/lore_generate_queue_models.dart';
import 'package:lizunemu/core/lore/lore_generate_queue_service.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';
import 'package:lizunemu/widgets/common/back_leading.dart';
import 'package:lizunemu/widgets/lore/lore_progress_labels.dart';
import 'package:lizunemu/widgets/queue/queue_empty_state.dart';
import 'package:lizunemu/widgets/queue/queue_item_row.dart';
import 'package:lizunemu/widgets/queue/queue_work_header.dart';

void openLoreGenerateQueueScreen(BuildContext context) {
  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute(builder: (_) => const LoreGenerateQueueScreen()),
  );
}

class LoreGenerateQueueScreen extends StatelessWidget {
  const LoreGenerateQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final queue = GetIt.I<LoreGenerateQueueService>();
    return ListenableBuilder(
      listenable: queue,
      builder: (context, _) {
        final hasFailures = queue.jobs.any(
          (j) =>
              j.status == LoreGenerateQueueJobStatus.failed ||
              j.tracksFailed > 0,
        );
        final activeCount = queue.jobs.where((j) => j.isActive).length;

        return Scaffold(
          appBar: AppBar(
            leading: const BackLeading(),
            automaticallyImplyLeading: false,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(Strings.loreQueueTitle),
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
              if (hasFailures)
                TextButton(
                  onPressed: () => queue.retryFailed(),
                  child: Text(Strings.loreQueueRetryFailed),
                ),
              if (queue.hasWork)
                TextButton(
                  onPressed: () => queue.cancelAll(),
                  child: Text(Strings.loreQueueCancelAll),
                ),
              if (queue.jobs.any((j) => j.isFinished))
                IconButton(
                  tooltip: Strings.loreQueueClearFinished,
                  onPressed: () => queue.clearFinished(),
                  icon: const Icon(Icons.cleaning_services_outlined),
                ),
            ],
          ),
          body: queue.jobs.isEmpty
              ? QueueEmptyState(
                  message: Strings.loreQueueEmpty,
                  icon: Icons.auto_awesome_outlined,
                )
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
  final LoreGenerateQueueJob job;
  final LoreGenerateQueueService queue;

  const _JobBlock({required this.job, required this.queue});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final kindLabel = LoreProgressLabels.forKind(job.kind);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QueueWorkHeader(
          work: job.work,
          title: job.workTitle,
          kindLabel: kindLabel,
          onCancel: job.isActive ? () => queue.cancelJob(job.id) : null,
          cancelTooltip: Strings.downloadCancel,
        ),
        if (job.tracks.isEmpty)
          _PrepOrJobRow(job: job)
        else
          ...job.tracks.map(
            (track) => _EpisodeRow(job: job, track: track, queue: queue),
          ),
        Divider(
          height: 1,
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ],
    );
  }
}

class _PrepOrJobRow extends StatelessWidget {
  final LoreGenerateQueueJob job;

  const _PrepOrJobRow({required this.job});

  @override
  Widget build(BuildContext context) {
    final isRunning = job.status == LoreGenerateQueueJobStatus.running;
    final isFailed = job.status == LoreGenerateQueueJobStatus.failed;
    final stage = job.progressStage.isEmpty
        ? null
        : LoreProgressLabels.forStage(job.progressStage);

    final String statusLabel;
    if (isFailed && job.lastError != null) {
      statusLabel = job.lastError!;
    } else if (isRunning && stage != null) {
      statusLabel = stage;
    } else {
      statusLabel = switch (job.status) {
        LoreGenerateQueueJobStatus.pending => Strings.loreQueueStatusPending,
        LoreGenerateQueueJobStatus.running => Strings.loreQueueStatusRunning,
        LoreGenerateQueueJobStatus.done => Strings.loreQueueStatusDone,
        LoreGenerateQueueJobStatus.failed => Strings.loreQueueStatusFailed,
        LoreGenerateQueueJobStatus.cancelled =>
          Strings.loreQueueStatusCancelled,
      };
    }

    final elapsed = job.stageStartedAt == null || !isRunning
        ? null
        : DateTime.now().difference(job.stageStartedAt!).inSeconds;

    return QueueItemRow(
      title: LoreProgressLabels.forKind(job.kind),
      statusLabel: statusLabel,
      statusIsError: isFailed,
      showProgress: isRunning,
      progressIndeterminate: true,
      progressTrailing:
          elapsed == null ? null : Strings.loreProgressElapsed(elapsed),
    );
  }
}

class _EpisodeRow extends StatelessWidget {
  final LoreGenerateQueueJob job;
  final LoreGenerateTrackProgress track;
  final LoreGenerateQueueService queue;

  const _EpisodeRow({
    required this.job,
    required this.track,
    required this.queue,
  });

  @override
  Widget build(BuildContext context) {
    final isRunning = track.status == LoreGenerateTrackStatus.running;
    final isFailed = track.status == LoreGenerateTrackStatus.failed;
    final isPending = track.status == LoreGenerateTrackStatus.pending;

    final statusLabel = switch (track.status) {
      LoreGenerateTrackStatus.pending => Strings.loreQueueStatusPending,
      LoreGenerateTrackStatus.running => _runningStatus(job, track),
      LoreGenerateTrackStatus.done => Strings.loreQueueStatusDone,
      LoreGenerateTrackStatus.failed =>
        track.error ?? Strings.loreQueueStatusFailed,
      LoreGenerateTrackStatus.skipped ||
      LoreGenerateTrackStatus.cancelled =>
        Strings.loreQueueStatusCancelled,
    };

    final total = job.tracks.length;
    final indexOneBased = track.index + 1;
    final elapsed = job.stageStartedAt == null || !isRunning
        ? null
        : DateTime.now().difference(job.stageStartedAt!).inSeconds;

    String? trailing;
    if (isRunning || isPending && job.status == LoreGenerateQueueJobStatus.running) {
      final parts = <String>[
        if (total > 0) '$indexOneBased/$total',
        if (track.streamEventsSeen > 0)
          Strings.loreProgressStreamEvents(track.streamEventsSeen),
        if (elapsed != null) Strings.loreProgressElapsed(elapsed),
      ];
      if (parts.isNotEmpty) trailing = parts.join(' · ');
    } else if (total > 0 && track.status == LoreGenerateTrackStatus.done) {
      trailing = '$indexOneBased/$total';
    }

    final doneRatio = total <= 0
        ? 0.0
        : (job.tracksDone + (isRunning ? 0.5 : 0)) / total;

    return QueueItemRow(
      title: track.title,
      statusLabel: statusLabel,
      statusIsError: isFailed,
      showProgress: isRunning,
      progressIndeterminate: job.waitingOnLlm,
      progressValue: doneRatio,
      progressTrailing: trailing,
      onRetry: isFailed
          ? () => queue.retryTrack(job.id, track.trackKey)
          : null,
      retryTooltip: Strings.translationQueueRetry,
    );
  }

  static String _runningStatus(
    LoreGenerateQueueJob job,
    LoreGenerateTrackProgress track,
  ) {
    if (track.streamEventsSeen > 0) {
      final title = track.streamLastEventTitle?.trim();
      if (title != null && title.isNotEmpty) {
        return Strings.loreProgressStreamEvent(track.streamEventsSeen, title);
      }
      return Strings.loreProgressStreamEvents(track.streamEventsSeen);
    }
    if (track.streamGotSummary) {
      return Strings.loreProgressStreamSummary;
    }
    if (job.waitingOnLlm) {
      return Strings.loreProgressWaitingLlm;
    }
    return Strings.loreQueueStatusRunning;
  }
}
