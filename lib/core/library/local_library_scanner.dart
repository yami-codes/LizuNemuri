import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:xuro/core/library/models/local_album.dart';

/// Pure scan logic — groups audio files by parent folder name.
class LocalLibraryScanner {
  static const audioExtensions = {
    'mp3',
    'm4a',
    'flac',
    'ogg',
    'wav',
    'opus',
    'aac',
  };

  /// Scans [roots] recursively; returns albums with ordered tracks.
  static List<({LocalAlbum album, List<LocalTrack> tracks})> scanRoots(
    List<String> roots, {
    int scannedAtMs = 0,
  }) {
    final now = scannedAtMs == 0
        ? DateTime.now().millisecondsSinceEpoch
        : scannedAtMs;
    final byFolder = <String, List<_ScannedFile>>{};

    for (final root in roots) {
      final dir = Directory(root);
      if (!dir.existsSync()) continue;
      _walk(dir, byFolder);
    }

    final results = <({LocalAlbum album, List<LocalTrack> tracks})>[];
    var albumId = 1;
    for (final entry in byFolder.entries) {
      final folderPath = entry.key;
      final files = entry.value
        ..sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));
      if (files.isEmpty) continue;

      final folderName = p.basename(folderPath);
      final parentName = p.basename(p.dirname(folderPath));
      final artist =
          parentName.isNotEmpty && parentName != folderName ? parentName : null;
      final albumKey = md5.convert(folderPath.codeUnits).toString();

      final album = LocalAlbum(
        id: albumId,
        albumKey: albumKey,
        title: folderName,
        artist: artist,
        folderPath: folderPath,
        trackCount: files.length,
        scannedAtMs: now,
      );

      final tracks = <LocalTrack>[];
      for (var i = 0; i < files.length; i++) {
        final file = files[i];
        tracks.add(
          LocalTrack(
            id: albumId * 1000 + i,
            albumId: albumId,
            title: _titleFromPath(file.path),
            filePath: file.path,
            trackOrder: i,
            scannedAtMs: now,
          ),
        );
      }
      results.add((album: album, tracks: tracks));
      albumId++;
    }

    results.sort(
      (a, b) => a.album.title.toLowerCase().compareTo(b.album.title.toLowerCase()),
    );
    return results;
  }

  static void _walk(Directory dir, Map<String, List<_ScannedFile>> byFolder) {
    try {
      for (final entity in dir.listSync(followLinks: false)) {
        if (entity is File) {
          if (!_isAudio(entity.path)) continue;
          final folder = p.dirname(entity.path);
          byFolder.putIfAbsent(folder, () => []).add(_ScannedFile(entity.path));
        } else if (entity is Directory) {
          final name = p.basename(entity.path);
          if (name.startsWith('.')) continue;
          _walk(entity, byFolder);
        }
      }
    } catch (_) {
      // Permission or IO errors on a subtree — skip branch.
    }
  }

  static bool _isAudio(String path) {
    final ext = p.extension(path).replaceFirst('.', '').toLowerCase();
    return audioExtensions.contains(ext);
  }

  static String _titleFromPath(String path) {
    final base = p.basenameWithoutExtension(path);
    return base.isEmpty ? p.basename(path) : base;
  }
}

class _ScannedFile {
  const _ScannedFile(this.path);
  final String path;
}
