import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/core/lore/lore_generate_queue_models.dart';
import 'package:lizunemu/core/lore/lore_generate_queue_service.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';
import 'package:lizunemu/widgets/common/back_leading.dart';

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
        return Scaffold(
          appBar: AppBar(
            leading: const BackLeading(),
            automaticallyImplyLeading: false,
            title: Text(Strings.loreQueueTitle),
            actions: [
              if (queue.jobs.any(
                (j) => j.status == LoreGenerateQueueJobStatus.failed,
              ))
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
                    return _JobTile(job: job, queue: queue);
                  },
                ),
        );
      },
    );
  }
}

class _JobTile extends StatelessWidget {
  final LoreGenerateQueueJob job;
  final LoreGenerateQueueService queue;

  const _JobTile({required this.job, required this.queue});

  String _statusLabel() {
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
    return ListTile(
      title: Text(job.workTitle),
      subtitle: Text(
        [
          _statusLabel(),
          if (job.progressStage.isNotEmpty) job.progressStage,
          if (job.lastError != null) job.lastError!,
        ].join(' · '),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: job.isActive
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => queue.cancelJob(job.id),
            )
          : Text('${(job.progress * 100).round()}%'),
      leading: Icon(
        Icons.auto_awesome,
        color: job.status == LoreGenerateQueueJobStatus.failed
            ? scheme.error
            : scheme.primary,
      ),
    );
  }
}
