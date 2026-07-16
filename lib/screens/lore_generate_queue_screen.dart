import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/core/lore/lore_generate_queue_models.dart';
import 'package:lizunemu/core/lore/lore_generate_queue_service.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';
import 'package:lizunemu/widgets/common/back_leading.dart';
import 'package:lizunemu/widgets/lore/lore_progress_labels.dart';

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
        final hasTrackFailures = queue.jobs.any(
          (j) =>
              j.status == LoreGenerateQueueJobStatus.failed ||
              j.tracksFailed > 0,
        );
        return Scaffold(
          appBar: AppBar(
            leading: const BackLeading(),
            automaticallyImplyLeading: false,
            title: Text(Strings.loreQueueTitle),
            actions: [
              if (hasTrackFailures)
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
              ? Center(child: Text(Strings.loreQueueEmpty))
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: AppSpacing.space64),
                  itemCount: queue.jobs.length,
                  itemBuilder: (context, index) {
                    final job = queue.jobs[index];
                    return _JobSection(job: job, queue: queue);
                  },
                ),
        );
      },
    );
  }
}

class _JobSection extends StatelessWidget {
  final LoreGenerateQueueJob job;
  final LoreGenerateQueueService queue;

  const _JobSection({required this.job, required this.queue});

  String _jobStatusLabel() {
    if (job.hasPartialFailures) {
      return Strings.loreQueuePartialSummary(job.tracksDone, job.tracksFailed);
    }
    return switch (job.status) {
      LoreGenerateQueueJobStatus.pending => Strings.loreQueueStatusPending,
      LoreGenerateQueueJobStatus.running => Strings.loreQueueStatusRunning,
      LoreGenerateQueueJobStatus.done => Strings.loreQueueStatusDone,
      LoreGenerateQueueJobStatus.failed => Strings.loreQueueStatusFailed,
      LoreGenerateQueueJobStatus.cancelled => Strings.loreQueueStatusCancelled,
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stage = job.progressStage.isEmpty
        ? null
        : LoreProgressLabels.forStage(job.progressStage);
    final elapsed = job.stageStartedAt == null
        ? null
        : DateTime.now().difference(job.stageStartedAt!).inSeconds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space16,
            AppSpacing.space16,
            AppSpacing.space16,
            AppSpacing.space8,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.workTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: scheme.primary,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    Text(
                      [
                        _jobStatusLabel(),
                        if (job.waitingOnLlm) Strings.loreProgressWaitingLlm,
                        if (stage != null &&
                            job.status == LoreGenerateQueueJobStatus.running)
                          stage,
                        if (elapsed != null &&
                            job.status == LoreGenerateQueueJobStatus.running)
                          Strings.loreProgressElapsed(elapsed),
                        if (job.lastError != null &&
                            job.status == LoreGenerateQueueJobStatus.failed)
                          job.lastError!,
                      ].join(' · '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              if (job.isActive)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => queue.cancelJob(job.id),
                ),
            ],
          ),
        ),
        if (job.tracks.isEmpty)
          ListTile(
            dense: true,
            title: Text(
              job.kind.name,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            subtitle: Text(_jobStatusLabel()),
          )
        else
          ...job.tracks.map(
            (track) => _TrackTile(job: job, track: track, queue: queue),
          ),
      ],
    );
  }
}

class _TrackTile extends StatelessWidget {
  final LoreGenerateQueueJob job;
  final LoreGenerateTrackProgress track;
  final LoreGenerateQueueService queue;

  const _TrackTile({
    required this.job,
    required this.track,
    required this.queue,
  });

  String _statusLabel() {
    return switch (track.status) {
      LoreGenerateTrackStatus.pending => Strings.loreQueueStatusPending,
      LoreGenerateTrackStatus.running => Strings.loreQueueStatusRunning,
      LoreGenerateTrackStatus.done => Strings.loreQueueStatusDone,
      LoreGenerateTrackStatus.failed => Strings.loreQueueStatusFailed,
      LoreGenerateTrackStatus.skipped => Strings.loreQueueStatusCancelled,
      LoreGenerateTrackStatus.cancelled => Strings.loreQueueStatusCancelled,
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isFailed = track.status == LoreGenerateTrackStatus.failed;

    return ListTile(
      title: Text(
        track.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        [
          _statusLabel(),
          if (track.attempts > 1)
            Strings.translationQueueAttempts(track.attempts),
          if (track.error != null && isFailed) track.error!,
        ].join(' · '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isFailed ? scheme.error : scheme.onSurfaceVariant,
            ),
      ),
      trailing: isFailed
          ? IconButton(
              tooltip: Strings.translationQueueRetry,
              onPressed: () => queue.retryTrack(job.id, track.trackKey),
              icon: Icon(Icons.refresh, color: scheme.primary),
            )
          : null,
    );
  }
}
