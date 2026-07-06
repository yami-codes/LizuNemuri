import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lizunemu/common/constants/log_strings.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/core/download/download_service.dart';
import 'package:lizunemu/core/image/cache/image_cache_manager.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';
import 'package:lizunemu/data/models/files/child.dart';
import 'package:lizunemu/utils/logger.dart';
import 'package:universal_io/io.dart';

/// Full-screen pinch/pan image preview — local download first, else presigned URL.
class ImagePreviewScreen extends StatefulWidget {
  const ImagePreviewScreen({
    super.key,
    required this.workId,
    required this.file,
  });

  final String? workId;
  final Child file;

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  final _downloadService = GetIt.I<DownloadService>();

  bool _loading = true;
  String? _error;
  String? _localPath;
  String? _networkUrl;

  @override
  void initState() {
    super.initState();
    _resolveSource();
  }

  Future<void> _resolveSource() async {
    setState(() {
      _loading = true;
      _error = null;
      _localPath = null;
      _networkUrl = null;
    });

    try {
      if (widget.workId != null) {
        final local = await _downloadService.localPathIfDownloaded(
          widget.workId!,
          widget.file,
        );
        if (local != null && await File(local).exists()) {
          if (!mounted) return;
          setState(() {
            _loading = false;
            _localPath = local;
          });
          return;
        }
      }

      final url = widget.file.mediaDownloadUrl;
      if (url == null || url.isEmpty) {
        throw StateError('empty url');
      }

      if (!mounted) return;
      setState(() {
        _loading = false;
        _networkUrl = url;
      });
    } catch (e, stack) {
      AppLogger.error(LogStrings.logImagePreviewLoadFailed, e, stack);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = Strings.imagePreviewError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(Strings.imagePreviewTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(
              bottom: AppSpacing.space8,
              left: AppSpacing.space16,
              right: AppSpacing.space16,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.file.title ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.space12),
            Text(Strings.imagePreviewLoading),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: AppSpacing.space12),
            TextButton(
              onPressed: _resolveSource,
              child: Text(Strings.retry),
            ),
          ],
        ),
      );
    }

    final image = _localPath != null
        ? Image.file(
            File(_localPath!),
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) => _errorFallback(context),
          )
        : CachedNetworkImage(
            imageUrl: _networkUrl!,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            cacheManager: ImageCacheManager.instance,
            progressIndicatorBuilder: (_, __, progress) => Center(
              child: CircularProgressIndicator(
                value: progress.progress,
              ),
            ),
            errorWidget: (_, __, ___) => _errorFallback(context),
          );

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 5.0,
      panEnabled: true,
      scaleEnabled: true,
      boundaryMargin: const EdgeInsets.all(AppSpacing.space64),
      child: Center(child: image),
    );
  }

  Widget _errorFallback(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.space8),
          Text(Strings.imagePreviewError),
          TextButton(
            onPressed: _resolveSource,
            child: Text(Strings.retry),
          ),
        ],
      ),
    );
  }
}
