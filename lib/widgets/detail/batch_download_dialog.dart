import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/presentation/viewmodels/detail_viewmodel.dart';

/// Batch "download all" dialog for folder or whole work.
/// Phase 1 = confirm; phase 2 = aggregate progress + cancel.
/// Pops [BatchDownloadOutcome] on done/cancel; null on confirm dismiss.
class BatchDownloadDialog extends StatefulWidget {
  final int audioCount;
  final Future<BatchDownloadOutcome> Function(
    CancelToken cancelToken,
    void Function(int index, int total, String name, double progress)
        onProgress,
  ) download;

  const BatchDownloadDialog({
    super.key,
    required this.audioCount,
    required this.download,
  });

  @override
  State<BatchDownloadDialog> createState() => _BatchDownloadDialogState();
}

class _BatchDownloadDialogState extends State<BatchDownloadDialog> {
  bool _downloading = false;
  int _index = 0;
  int _total = 0;
  String _name = '';
  double _progress = 0;
  CancelToken? _cancelToken;

  @override
  void dispose() {
    // Cancel token when dialog/page dismissed programmatically — stops background writes.
    _cancelToken?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    final cancelToken = CancelToken();
    setState(() {
      _downloading = true;
      _total = widget.audioCount;
      _cancelToken = cancelToken;
    });

    BatchDownloadOutcome outcome;
    try {
      outcome = await widget.download(cancelToken, (i, n, name, p) {
        if (mounted) {
          setState(() {
            _index = i;
            _total = n;
            _name = name;
            _progress = p;
          });
        }
      });
    } catch (_) {
      // Last resort: pop failure on uncaught error so progress sheet cannot stick.
      outcome = BatchDownloadOutcome(
        ok: 0,
        skipped: 0,
        failed: widget.audioCount,
        cancelled: false,
      );
    }

    if (mounted) Navigator.of(context).pop(outcome);
  }

  @override
  Widget build(BuildContext context) {
    if (!_downloading) {
      if (widget.audioCount == 0) {
        return AlertDialog(
          title: Text(Strings.batchDownloadTitle),
          content: Text(Strings.batchDownloadEmpty),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(Strings.confirm),
            ),
          ],
        );
      }
      return AlertDialog(
        title: Text(Strings.batchDownloadTitle),
        content: Text(Strings.batchDownloadConfirm(widget.audioCount)),
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

    final pct = (_progress * 100).clamp(0, 100).toStringAsFixed(0);
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(Strings.batchDownloadTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Strings.batchDownloadProgress(_index, _total, _name),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _progress > 0 ? _progress : null,
            ),
            const SizedBox(height: 8),
            Text('$pct%'),
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
