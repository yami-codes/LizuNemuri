import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:xuro/common/constants/strings.dart';
import 'package:xuro/core/llm/subtitle_translation_progress.dart';
import 'package:xuro/presentation/viewmodels/detail_viewmodel.dart';

/// Progress dialog for bulk LLM subtitle pre-translation.
class BatchTranslateDialog extends StatefulWidget {
  final int trackCount;
  final bool skipConfirm;
  final Future<BatchTranslateOutcome> Function(
    CancelToken cancelToken,
    BatchTranslateProgressCallback onProgress,
  ) translate;

  const BatchTranslateDialog({
    super.key,
    required this.trackCount,
    required this.translate,
    this.skipConfirm = false,
  });

  @override
  State<BatchTranslateDialog> createState() => _BatchTranslateDialogState();
}

class _BatchTranslateDialogState extends State<BatchTranslateDialog> {
  late bool _running = widget.skipConfirm;
  int _index = 0;
  int _total = 0;
  String _name = '';
  BatchTranslatePhase _phase = BatchTranslatePhase.loadingSubtitle;
  int? _llmBatch;
  int? _llmBatchTotal;
  CancelToken? _cancelToken;

  @override
  void initState() {
    super.initState();
    if (widget.skipConfirm) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _start());
    }
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }

  String _phaseLabel() {
    return switch (_phase) {
      BatchTranslatePhase.loadingSubtitle =>
        Strings.batchTranslatePhaseLoading,
      BatchTranslatePhase.checkingCache =>
        Strings.batchTranslatePhaseCheckingCache,
      BatchTranslatePhase.translating => _llmBatch != null && _llmBatchTotal != null
          ? Strings.batchTranslatePhaseTranslating(
              _llmBatch!,
              _llmBatchTotal!,
            )
          : Strings.batchTranslatePhaseTranslatingSimple,
      BatchTranslatePhase.cached => Strings.batchTranslatePhaseCached,
      BatchTranslatePhase.failed => Strings.batchTranslatePhaseFailed,
    };
  }

  Future<void> _start() async {
    final cancelToken = CancelToken();
    setState(() {
      _running = true;
      _total = widget.trackCount;
      _cancelToken = cancelToken;
    });

    BatchTranslateOutcome outcome;
    try {
      outcome = await widget.translate(cancelToken, (p) {
        if (mounted) {
          setState(() {
            _index = p.index;
            _total = p.total;
            _name = p.trackName;
            _phase = p.phase;
            _llmBatch = p.llmBatchIndex;
            _llmBatchTotal = p.llmBatchTotal;
          });
        }
      });
    } catch (_) {
      outcome = BatchTranslateOutcome(
        translated: 0,
        cached: 0,
        failed: widget.trackCount,
        cancelled: false,
      );
    }

    if (mounted) Navigator.of(context).pop(outcome);
  }

  @override
  Widget build(BuildContext context) {
    if (!_running) {
      return AlertDialog(
        title: Text(Strings.batchTranslateTitle),
        content: Text(Strings.batchTranslateConfirm(widget.trackCount)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(Strings.downloadCancel),
          ),
          TextButton(
            onPressed: _start,
            child: Text(Strings.downloadConfirm),
          ),
        ],
      );
    }

    final progress = _total > 0 ? _index / _total : null;
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(Strings.batchTranslateTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Strings.batchTranslateProgress(_index, _total, _name),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              _phaseLabel(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _cancelToken?.cancel(),
            child: Text(Strings.downloadCancel),
          ),
        ],
      ),
    );
  }
}
