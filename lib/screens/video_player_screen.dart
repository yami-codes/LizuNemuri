import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lizunemu/common/constants/log_strings.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/core/audio/models/subtitle.dart';
import 'package:lizunemu/core/download/download_service.dart';
import 'package:lizunemu/core/subtitle/subtitle_loader.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';
import 'package:lizunemu/data/models/files/child.dart';
import 'package:lizunemu/utils/logger.dart';
import 'package:lizunemu/widgets/video/video_subtitle_overlay.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:universal_io/io.dart';

/// In-app video player with optional matched sibling subtitle overlay.
class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({
    super.key,
    required this.workId,
    required this.file,
    this.subtitleFile,
  });

  final String? workId;
  final Child file;
  final Child? subtitleFile;

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  final _downloadService = GetIt.I<DownloadService>();
  final _subtitleLoader = GetIt.I<SubtitleLoader>();

  late final Player _player;
  late final VideoController _videoController;
  final _subscriptions = <StreamSubscription<dynamic>>[];

  bool _loading = true;
  String? _error;
  SubtitleList? _subtitleList;
  String? _subtitleText;
  bool _subtitlesVisible = true;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _videoController = VideoController(_player);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _openVideo();
      await _loadSubtitle();
      _listenForSubtitleSync();
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e, stack) {
      AppLogger.error(LogStrings.logVideoPlayerLoadFailed, e, stack);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = Strings.videoPlayerError;
      });
    }
  }

  Future<void> _openVideo() async {
    String? localPath;
    if (widget.workId != null) {
      localPath = await _downloadService.localPathIfDownloaded(
        widget.workId!,
        widget.file,
      );
    }
    if (localPath != null && await File(localPath).exists()) {
      await _player.open(Media(localPath));
      return;
    }

    final url = widget.file.mediaDownloadUrl;
    if (url == null || url.isEmpty) {
      throw StateError('missing video url');
    }
    await _player.open(Media(url));
  }

  Future<void> _loadSubtitle() async {
    final subtitleFile = widget.subtitleFile;
    if (subtitleFile == null) return;

    try {
      String? localPath;
      if (widget.workId != null) {
        localPath = await _downloadService.localPathIfDownloaded(
          widget.workId!,
          subtitleFile,
        );
      }
      final content = await _subtitleLoader.loadRawContent(
        localPath: localPath,
        url: subtitleFile.mediaDownloadUrl,
      );
      _subtitleList = _subtitleLoader.parseOrNull(content);
    } catch (e) {
      AppLogger.debug(LogStrings.logVideoSubtitleLoadFailed(e));
    }
  }

  void _listenForSubtitleSync() {
    _subscriptions.add(
      _player.stream.position.listen((position) {
        final list = _subtitleList;
        if (list == null || !_subtitlesVisible) return;
        final current = list.getCurrentSubtitle(position);
        final text = current?.state == SubtitleState.current
            ? current!.subtitle.text
            : null;
        if (text != _subtitleText && mounted) {
          setState(() => _subtitleText = text);
        }
      }),
    );
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(Strings.videoPlayerTitle),
        actions: [
          if (_subtitleList != null)
            IconButton(
              tooltip: Strings.videoSubtitlesToggle,
              icon: Icon(
                _subtitlesVisible
                    ? Icons.subtitles
                    : Icons.subtitles_off_outlined,
              ),
              onPressed: () {
                setState(() {
                  _subtitlesVisible = !_subtitlesVisible;
                  if (!_subtitlesVisible) _subtitleText = null;
                });
              },
            ),
        ],
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
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.space12),
            Text(
              Strings.videoPlayerLoading,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space12),
            TextButton(
              onPressed: _bootstrap,
              child: Text(Strings.retry),
            ),
          ],
        ),
      );
    }

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Center(
          child: Video(
            controller: _videoController,
            controls: AdaptiveVideoControls,
          ),
        ),
        VideoSubtitleOverlay(
          text: _subtitleText,
          visible: _subtitlesVisible,
        ),
      ],
    );
  }
}
