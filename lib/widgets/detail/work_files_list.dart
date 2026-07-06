import 'package:flutter/material.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/data/models/files/files.dart';
import 'package:lizunemu/data/models/files/child.dart';
import 'package:lizunemu/widgets/detail/work_folder_item.dart';
import 'package:lizunemu/widgets/detail/work_file_item.dart';
import 'package:lizunemu/utils/platform_capabilities.dart';

class WorkFilesList extends StatelessWidget {
  final Files files;
  final Function(Child file)? onFileTap;
  final Function(Child file)? onFileDownload;

  /// Download all audio (+ matched subtitles) for whole work or folder subtree. null = whole work.
  final void Function(Child? folderNode)? onFolderDownload;

  /// Batch LLM pre-translate for whole work or folder subtree.
  final void Function(Child? folderNode)? onFolderTranslate;

  const WorkFilesList({
    super.key,
    required this.files,
    this.onFileTap,
    this.onFileDownload,
    this.onFolderDownload,
    this.onFolderTranslate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    Strings.fileList,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (onFolderDownload != null &&
                    PlatformCapabilities.supportsLocalDownloads)
                  TextButton.icon(
                    onPressed: () => onFolderDownload!.call(null),
                    icon: const Icon(Icons.download_for_offline_outlined,
                        size: 18),
                    label: Text(Strings.downloadAllTooltip),
                  ),
                if (onFolderTranslate != null)
                  TextButton.icon(
                    onPressed: () => onFolderTranslate!.call(null),
                    icon: const Icon(Icons.translate, size: 18),
                    label: Text(Strings.batchTranslateTooltip),
                  ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          ...files.children
                  ?.map((child) => child.type == 'folder'
                      ? WorkFolderItem(
                          folder: child,
                          indentation: 0,
                          onFileTap: onFileTap,
                          onFileDownload: onFileDownload,
                          onFolderDownload: onFolderDownload,
                          onFolderTranslate: onFolderTranslate,
                        )
                      : WorkFileItem(
                          file: child,
                          indentation: 0,
                          onFileTap: onFileTap,
                          onFileDownload: onFileDownload,
                        ))
                  .toList() ??
              [],
        ],
      ),
    );
  }
}
