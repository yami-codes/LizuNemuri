import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/core/download/download_service.dart';

/// Media download-to-disk dialog: confirm then progress + cancel; pops [DownloadResult].
///
/// Dismiss at confirm → pop(null); caller treats as no-op.
class MediaDownloadDialog extends StatefulWidget {
  final String fileName;
  final String titleText;
  final String promptText;
  final Future<DownloadResult> Function(
    CancelToken cancelToken,
    void Function(double progress) onProgress,
  ) download;

  MediaDownloadDialog({
    super.key,
    required this.fileName,
    required this.download,
    String? titleText,
    String? promptText,
  })  : titleText = titleText ?? Strings.videoNeedsDownloadTitle,
        promptText = promptText ?? Strings.videoNeedsDownloadPrompt;

  @override
  State<MediaDownloadDialog> createState() => _MediaDownloadDialogState();
}

class _MediaDownloadDialogState extends State<MediaDownloadDialog> {
  bool _downloading = false;
  double _progress = 0;
  CancelToken? _cancelToken;

  Future<void> _start() async {
    final cancelToken = CancelToken();
    setState(() {
      _downloading = true;
      _progress = 0;
      _cancelToken = cancelToken;
    });

    DownloadResult result;
    try {
      result = await widget.download(cancelToken, (p) {
        if (mounted) setState(() => _progress = p);
      });
    } catch (_) {
      // Last resort for uncaught errors so PopScope progress sheet cannot stick.
      result = const DownloadResult(DownloadStatus.ioError);
    }

    if (mounted) Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    if (!_downloading) {
      return AlertDialog(
        title: Text(widget.titleText),
        content: Text(widget.promptText),
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
        title: Text(Strings.downloading),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.fileName,
              maxLines: 1,
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
