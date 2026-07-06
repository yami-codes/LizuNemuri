import 'package:lizunemu/core/media/work_media_utils.dart';
import 'package:lizunemu/data/models/files/child.dart';
import 'package:lizunemu/data/models/files/files.dart';
import 'package:lizunemu/data/services/api_service.dart';
import 'package:lizunemu/utils/logger.dart';

/// Re-fetches `/tracks/{id}` to renew expired presigned `mediaDownloadUrl`s.
class WorkMediaUrlRefresher {
  final ApiService _api;

  WorkMediaUrlRefresher(this._api);

  /// Returns [file] with a fresh URL when the API still lists the same leaf.
  ///
  /// When [patchInto] is set, a patched copy of the tree is delivered via
  /// [onTreePatched] (Freezed trees use immutable copy — never in-place write).
  Future<Child> refreshFile({
    required String workId,
    required Child file,
    Files? patchInto,
    void Function(Files patched)? onTreePatched,
  }) async {
    try {
      final freshTree = await _api.getWorkFiles(workId);
      final updated = WorkMediaUtils.findMatchingFile(freshTree.children, file);
      if (updated == null) return file;

      if (patchInto != null) {
        final patched = WorkMediaUtils.patchInFiles(patchInto, file, updated);
        if (patched != null) {
          onTreePatched?.call(patched);
        } else {
          AppLogger.warning(
            'WorkMediaUrlRefresher patch missed for ${file.title}',
          );
        }
      }

      if (updated.mediaDownloadUrl != null &&
          updated.mediaDownloadUrl!.isNotEmpty) {
        return updated;
      }
    } catch (e) {
      AppLogger.warning('WorkMediaUrlRefresher failed for ${file.title}: $e');
    }
    return file;
  }
}
