import 'package:flutter/material.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/data/models/files/child.dart';
import 'package:lizunemu/utils/logger.dart';
import 'package:lizunemu/utils/file_size_formatter.dart';
import 'package:lizunemu/utils/platform_capabilities.dart';
import 'package:lizunemu/common/constants/log_strings.dart';

class WorkFileItem extends StatelessWidget {
  final Child file;
  final double indentation;
  final Function(Child file)? onFileTap;
  final Function(Child file)? onFileDownload;
  final String? displayTitle;

  const WorkFileItem({
    super.key,
    required this.file,
    required this.indentation,
    this.onFileTap,
    this.onFileDownload,
    this.displayTitle,
  });

  static const _videoExtensions = {
    'mp4', 'mkv', 'mov', 'avi', 'webm', 'm4v'
  };

  static const _subtitleExtensions = {'vtt', 'lrc', 'srt', 'txt'};

  bool get _isAudio => file.type?.toLowerCase() == 'audio';

  bool get _isVideo {
    if ((file.type ?? '').toLowerCase() == 'video') return true;
    final ext = file.title?.split('.').last.toLowerCase();
    return ext != null && _videoExtensions.contains(ext);
  }

  bool get _isSubtitle {
    final ext = file.title?.split('.').last.toLowerCase();
    return ext != null && _subtitleExtensions.contains(ext);
  }

  @override
  Widget build(BuildContext context) {
    // Video extension over API `type` — mislabeled videos route to download + external player.
    final bool isVideo = _isVideo;
    final bool isAudio = _isAudio && !isVideo;
    final bool isSubtitle = !isAudio && !isVideo && _isSubtitle;
    final bool tappable = isAudio || isVideo || isSubtitle;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: EdgeInsets.only(left: indentation),
      child: ListTile(
        title: Text(
          displayTitle ?? file.title ?? '',
          style: TextStyle(
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          FileSizeFormatter.format(file.size),
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        leading: Icon(
          isAudio
              ? Icons.audio_file
              : isVideo
                  ? Icons.movie_outlined
                  : isSubtitle
                      ? Icons.subtitles_outlined
                      : Icons.insert_drive_file,
          color: isAudio
              ? Colors.green
              : isVideo
                  ? Colors.deepPurple
                  : isSubtitle
                      ? Colors.orange
                      : Colors.blue,
        ),
        trailing: PlatformCapabilities.supportsLocalDownloads && isAudio && onFileDownload != null
            ? IconButton(
                icon: const Icon(Icons.download_outlined, size: 20),
                tooltip: Strings.downloadToLocalTooltip,
                onPressed: () => onFileDownload!.call(file),
              )
            : PlatformCapabilities.supportsLocalDownloads && isVideo
                ? const Icon(Icons.download_outlined, size: 20)
                : null,
        dense: true,
        onTap: tappable
            ? () {
                AppLogger.debug(LogStrings.logFileTappedFileTitleFileTe6c23(file.title, file.type));
                onFileTap?.call(file);
              }
            : null,
      ),
    );
  }
}
