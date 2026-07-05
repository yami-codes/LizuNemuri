import 'package:flutter/material.dart';
import 'package:xuro/common/constants/strings.dart';
import 'package:xuro/data/models/files/files.dart';
import 'package:xuro/data/models/files/child.dart';
import 'package:xuro/widgets/detail/work_folder_item.dart';
import 'package:xuro/widgets/detail/work_file_item.dart';
import 'package:xuro/utils/platform_capabilities.dart';

class WorkFilesList extends StatelessWidget {
  final Files files;
  final Function(Child file)? onFileTap;
  final Function(Child file)? onFileDownload;

  /// 下载整部作品 / 某文件夹子树全部音频（含匹配字幕）。
  /// 参数为 null 代表整部作品，否则为该文件夹节点。
  final void Function(Child? folderNode)? onFolderDownload;

  /// 批量 LLM 预翻译整部作品 / 文件夹子树（含匹配字幕）。
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
