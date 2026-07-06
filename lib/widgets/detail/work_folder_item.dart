import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/data/models/files/child.dart';
import 'package:lizunemu/utils/logger.dart';
import 'package:lizunemu/common/constants/log_strings.dart';
import 'package:lizunemu/widgets/detail/work_file_item.dart';
import 'package:lizunemu/core/audio/models/file_path.dart';
import 'package:lizunemu/core/settings/app_settings_service.dart';
import 'package:lizunemu/utils/platform_capabilities.dart';

class WorkFolderItem extends StatelessWidget {
  final Child folder;
  final double indentation;
  final Function(Child file)? onFileTap;
  final Function(Child file)? onFileDownload;
  final void Function(Child? folderNode)? onFolderDownload;
  final void Function(Child? folderNode)? onFolderTranslate;
  final String Function(Child file)? trackTitleFor;

  // Supported audio formats by priority
  static List<String> get _audioFormats {
    try {
      return GetIt.I<AppSettingsService>().audioExtensions;
    } catch (_) {
      return ['.mp3', '.flac', '.wav', '.opus', '.m4a', '.aac'];
    }
  }

  // Static: path of first folder containing audio
  static List<String>? _audioFolderPath;

  // Static: reset expand state
  static void resetExpandState() {
    _audioFolderPath = null;
  }

  const WorkFolderItem({
    super.key,
    required this.folder,
    required this.indentation,
    this.onFileTap,
    this.onFileDownload,
    this.onFolderDownload,
    this.onFolderTranslate,
    this.trackTitleFor,
  });

  bool _shouldExpandFolder(Child folder) {
    try {
      final settings = GetIt.I<AppSettingsService>();
      if (!settings.smartPathEnabled) return false;
    } catch (_) {
      // If settings not available, default to enabled
    }

    // Search and record first audio folder if not found yet
    _audioFolderPath ??= FilePath.findFirstAudioFolderPath(
        [folder],
        formats: _audioFormats,
      );

    // Whether this folder is on the path to the audio folder
    return FilePath.isInPath(_audioFolderPath, folder.title);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final shouldExpand = _shouldExpandFolder(folder);

    return Padding(
      padding: EdgeInsets.only(left: indentation),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          // Ensure children inherit correct text color
          textTheme: Theme.of(context).textTheme.apply(
            bodyColor: colorScheme.onSurface,
            displayColor: colorScheme.onSurface,
          ),
        ),
        child: ExpansionTile(
          title: Row(
            children: [
              Expanded(
                child: Text(
                  folder.title ?? '',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              if (onFolderDownload != null &&
                  PlatformCapabilities.supportsLocalDownloads)
                IconButton(
                  icon: const Icon(Icons.download_for_offline_outlined,
                      size: 20),
                  tooltip: Strings.downloadAllTooltip,
                  onPressed: () => onFolderDownload!.call(folder),
                ),
              if (onFolderTranslate != null)
                IconButton(
                  icon: const Icon(Icons.translate, size: 20),
                  tooltip: Strings.batchTranslateTooltip,
                  onPressed: () => onFolderTranslate!.call(folder),
                ),
            ],
          ),
          leading: Icon(
            Icons.folder,
            color: colorScheme.primary,
          ),
          initiallyExpanded: shouldExpand,
          children: folder.children
                  ?.map((child) => child.type == 'folder'
                      ? WorkFolderItem(
                          folder: child,
                          indentation: indentation + 16.0,
                          onFileTap: onFileTap,
                          onFileDownload: onFileDownload,
                          onFolderDownload: onFolderDownload,
                          onFolderTranslate: onFolderTranslate,
                          trackTitleFor: trackTitleFor,
                        )
                      : WorkFileItem(
                          file: child,
                          indentation: indentation + 16.0,
                          onFileTap: onFileTap,
                          onFileDownload: onFileDownload,
                          displayTitle: trackTitleFor?.call(child),
                        ))
                  .toList() ??
              [],
          onExpansionChanged: (expanded) {
            AppLogger.debug(
              LogStrings.logFolderToggled(
                expanded ? LogStrings.logExpand : LogStrings.logCollapse,
                folder.title ?? '',
              ),
            );
          },
        ),
      ),
    );
  }
}
