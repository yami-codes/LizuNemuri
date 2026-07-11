import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/core/llm/subtitle_translation_progress.dart';
import 'package:lizunemu/core/llm/translation_queue_models.dart';
import 'package:lizunemu/core/llm/translation_queue_service.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';
import 'package:lizunemu/widgets/common/back_leading.dart';

/// Full-page translation queue (sidebar + mini-indicator entry).
class TranslationQueueScreen extends StatelessWidget {
  const TranslationQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final queue = GetIt.I<TranslationQueueService>();
    return ListenableBuilder(
      listenable: queue,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            leading: const BackLeading(),
            automaticallyImplyLeading: false,
            title: Text(Strings.translationQueueTitle),
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
              ? Center(child: Text(Strings.translationQueueEmpty))
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
  final TranslationQueueJob job;
  final TranslationQueueService queue;

  const _JobSection({required this.job, required this.queue});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
          child: Text(
            job.workTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: scheme.primary,
                ),
          ),
        ),
        ...job.tracks.map((track) => _TrackTile(track: track, queue: queue)),
      ],
    );
  }
}

class _TrackTile extends StatelessWidget {
  final TranslationQueueTrack track;
  final TranslationQueueService queue;

  const _TrackTile({required this.track, required this.queue});

  String _statusLabel() {
    return switch (track.status) {
      TranslationQueueTrackStatus.pending => Strings.translationQueueStatusPending,
      TranslationQueueTrackStatus.running => _runningLabel(),
      TranslationQueueTrackStatus.done => Strings.translationQueueStatusDone,
      TranslationQueueTrackStatus.cached => Strings.batchTranslatePhaseCached,
      TranslationQueueTrackStatus.failed => Strings.translationQueueStatusFailed,
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
    final scheme = Theme.of(context).colorScheme;
    final isFailed = track.status == TranslationQueueTrackStatus.failed;
    final canCancel = track.status == TranslationQueueTrackStatus.pending ||
        track.status == TranslationQueueTrackStatus.running;

    return ListTile(
      title: Text(
        track.trackName,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        [
          _statusLabel(),
          if (track.attempts > 1)
            Strings.translationQueueAttempts(track.attempts),
          if (track.lastError != null && isFailed) track.lastError!,
        ].join(' · '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isFailed ? scheme.error : scheme.onSurfaceVariant,
            ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isFailed)
            IconButton(
              tooltip: Strings.translationQueueRetry,
              onPressed: () => queue.retryTrack(track.id),
              icon: Icon(Icons.refresh, color: scheme.primary),
            ),
          if (canCancel)
            IconButton(
              tooltip: Strings.downloadCancel,
              onPressed: () => queue.cancelTrack(track.id),
              icon: Icon(Icons.close, color: scheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}

/// Opens [TranslationQueueScreen] on the root navigator.
void openTranslationQueueScreen(BuildContext context) {
  Navigator.of(context, rootNavigator: true).push(
    CupertinoPageRoute(builder: (_) => const TranslationQueueScreen()),
  );
}
