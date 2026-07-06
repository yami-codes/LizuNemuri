import 'package:lizunemu/data/models/files/files.dart';
import 'package:lizunemu/data/models/files/child.dart';
import 'package:lizunemu/utils/logger.dart';
import 'package:lizunemu/common/constants/log_strings.dart';

/// File path utilities for locating files in the tree and listing siblings.
class FilePath {
  static const separator = '/';

  /// Returns the full file path, e.g. /folder1/folder2/file.mp3.
  static String? getPath(Child targetFile, Files root) {
    AppLogger.debug(LogStrings.logStartResolvingFilePathTargetb9a7f(targetFile.title));
    final segments = _findPathSegments(root.children, targetFile);
    
    if (segments == null) {
      AppLogger.debug(LogStrings.logFilePathNotFound6f266);
      return null;
    }

    final path = separator + segments.join(separator);
    AppLogger.debug(LogStrings.logFoundFilePathPath57008(path));
    return path;
  }

  /// Recursively finds path segments for a file.
  static List<String>? _findPathSegments(List<Child>? children, Child targetFile, [List<String> currentPath = const []]) {
    if (children == null) return null;

    for (final child in children) {
      if (child.title == targetFile.title && 
          child.mediaDownloadUrl == targetFile.mediaDownloadUrl && 
          child.type == targetFile.type &&
          child.size == targetFile.size) {  // size as an extra identity check
        return [...currentPath, child.title!];
      }

      if (child.type == 'folder' && child.children != null) {
        final result = _findPathSegments(
          child.children, 
          targetFile, 
          [...currentPath, child.title!]
        );
        if (result != null) return result;
      }
    }

    return null;
  }

  /// Returns all files in the same directory as [targetFile].
  static List<Child> getSiblings(Child targetFile, Files root) {
    AppLogger.debug(LogStrings.logGetSiblingFilesTargetfileTit6cf37(targetFile.title));
    
    // Resolve the target file path
    final path = getPath(targetFile, root);
    if (path == null) {
      AppLogger.debug(LogStrings.logCannotResolveFilePathReturnEff0fd);
      return [];
    }

    // Resolve the parent directory path
    final lastSeparator = path.lastIndexOf(separator);
    final parentPath = lastSeparator > 0 ? path.substring(0, lastSeparator) : separator;
    AppLogger.debug(LogStrings.logParentDirPathParentpathd3aa7(parentPath));

    // Look up parent directory contents
    List<Child>? siblings;
    if (parentPath == separator) {
      // At root, use root.children directly
      AppLogger.debug(LogStrings.logFileAtRootUseRootFileList8c225);
      siblings = root.children;
    } else {
      // Otherwise walk to the parent directory
      siblings = _findDirectoryByPath(root.children, parentPath);
    }

    if (siblings == null) {
      AppLogger.debug(LogStrings.logParentDirEmptyReturnEmpty7c668);
      return [];
    }

    AppLogger.debug(LogStrings.logSiblingFileCountSiblingsLeng9ed81(siblings.length));
    return siblings;
  }

  /// Finds directory contents by path.
  static List<Child>? _findDirectoryByPath(List<Child>? children, String path) {
    if (children == null || path.isEmpty) return null;

    // Root path: return directly
    if (path == separator) return children;

    // Split path segments
    final segments = path.split(separator)
      ..removeWhere((s) => s.isEmpty);
    
    List<Child>? current = children;
    
    // Walk directories segment by segment
    for (final segment in segments) {
      final nextDir = current?.firstWhere(
        (child) => child.title == segment && child.type == 'folder',
        orElse: () => Child(),
      );
      
      if (nextDir?.title == null) return null;
      current = nextDir?.children;
    }

    return current;
  }

  /// Finds the first directory containing audio files.
  /// Returns the full path array from root to that directory.
  static List<String>? findFirstAudioFolderPath(
    List<Child>? children, {
    List<String> formats = const ['.mp3', '.wav'],
  }) {
    if (children == null) return null;

    List<String>? audioFolderPath;
    
    void findPath(Child folder, List<String> currentPath) {
      if (audioFolderPath != null) return;

      if (folder.children != null) {
        // First check whether this directory directly contains audio files
        bool hasDirectAudio = folder.children!.any((child) {
          if (child.type != 'folder') {
            final fileName = child.title?.toLowerCase() ?? '';
            return formats.any((format) => fileName.endsWith(format));
          }
          return false;
        });

        // If audio files are present, record the full path
        if (hasDirectAudio) {
          audioFolderPath = currentPath;
          return;
        }

        // Otherwise recurse into subdirectories
        for (final child in folder.children!) {
          if (child.type == 'folder') {
            List<String> newPath = List.from(currentPath)..add(child.title ?? '');
            findPath(child, newPath);
          }
        }
      }
    }

    // Walk top-level folders under root
    for (final child in children) {
      if (child.type == 'folder') {
        findPath(child, [child.title ?? '']);
        if (audioFolderPath != null) break;
      }
    }

    return audioFolderPath;
  }

  /// Whether [path] contains [folderName] (e.g. on the path to an audio folder).
  static bool isInPath(List<String>? path, String? folderName) {
    if (path == null || folderName == null) return false;
    return path.contains(folderName);
  }
} 