import 'package:lizunemu/data/models/files/child.dart';
import 'package:lizunemu/data/models/files/files.dart';
import 'package:lizunemu/data/services/asmr_api_headers.dart';

/// Shared helpers for work file trees and CDN media fetches.
class WorkMediaUtils {
  WorkMediaUtils._();

  /// Browser-like headers for presigned CDN URLs (no auth token).
  static const Map<String, String> mediaFetchHeaders = {
    'User-Agent':
        'Mozilla/5.0 (compatible; Lizunemu/2.0; +https://github.com/yami-codes/LizuNemu)',
    'Accept': '*/*',
    'Accept-Language': AsmrApiHeaders.acceptLanguage,
  };

  /// Finds the same leaf in a fresh `/tracks/{id}` tree (hash preferred, then title).
  static Child? findMatchingFile(List<Child>? nodes, Child target) {
    if (nodes == null) return null;
    for (final node in nodes) {
      if (node.type == 'folder') {
        final found = findMatchingFile(node.children, target);
        if (found != null) return found;
        continue;
      }
      if (_sameFile(node, target)) return node;
    }
    return null;
  }

  static bool _sameFile(Child a, Child b) {
    final aHash = a.hash?.trim();
    final bHash = b.hash?.trim();
    if (aHash != null && aHash.isNotEmpty && aHash == bHash) return true;
    final aTitle = a.title?.trim();
    final bTitle = b.title?.trim();
    return aTitle != null && aTitle.isNotEmpty && aTitle == bTitle;
  }

  /// Patches [fresh] URL/hash into the in-memory tree node matching [target].
  ///
  /// Mutates [nodes] in place — only safe on growable lists. Prefer
  /// [patchInFiles] for Freezed / JSON-backed trees.
  static bool patchFileInTree(List<Child>? nodes, Child target, Child fresh) {
    if (nodes == null) return false;
    for (var i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      if (node.type == 'folder') {
        if (patchFileInTree(node.children, target, fresh)) return true;
        continue;
      }
      if (_sameFile(node, target)) {
        nodes[i] = node.copyWith(
          mediaDownloadUrl: fresh.mediaDownloadUrl ?? node.mediaDownloadUrl,
          hash: fresh.hash ?? node.hash,
        );
        return true;
      }
    }
    return false;
  }

  /// Immutable patch for Freezed file trees (unmodifiable `children` lists).
  static Files? patchInFiles(Files root, Child target, Child fresh) {
    final children = root.children;
    if (children == null) return null;
    final patched = _patchChildrenCopy(children, target, fresh);
    if (patched == null) return null;
    return root.copyWith(children: patched);
  }

  static List<Child>? _patchChildrenCopy(
    List<Child> nodes,
    Child target,
    Child fresh,
  ) {
    for (var i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      if (node.type == 'folder') {
        final kids = node.children;
        if (kids == null) continue;
        final patchedKids = _patchChildrenCopy(kids, target, fresh);
        if (patchedKids != null) {
          final copy = List<Child>.from(nodes);
          copy[i] = node.copyWith(children: patchedKids);
          return copy;
        }
        continue;
      }
      if (_sameFile(node, target)) {
        final copy = List<Child>.from(nodes);
        copy[i] = node.copyWith(
          mediaDownloadUrl: fresh.mediaDownloadUrl ?? node.mediaDownloadUrl,
          hash: fresh.hash ?? node.hash,
        );
        return copy;
      }
    }
    return null;
  }
}
