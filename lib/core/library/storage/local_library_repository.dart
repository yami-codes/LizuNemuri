import 'package:xuro/core/database/database_service.dart';
import 'package:xuro/core/library/models/local_album.dart';

class LocalLibraryRepository {
  LocalLibraryRepository(this._db);

  final DatabaseService _db;

  Future<void> replaceLibrary(
    List<({LocalAlbum album, List<LocalTrack> tracks})> scanned,
  ) async {
    final database = await _db.database;
    await database.transaction((txn) async {
      await txn.delete('local_tracks');
      await txn.delete('local_albums');
      for (final group in scanned) {
        final albumId = await txn.insert('local_albums', {
          'album_key': group.album.albumKey,
          'title': group.album.title,
          'artist': group.album.artist,
          'folder_path': group.album.folderPath,
          'track_count': group.tracks.length,
          'scanned_at': group.album.scannedAtMs,
        });
        for (final track in group.tracks) {
          await txn.insert('local_tracks', {
            'album_id': albumId,
            'title': track.title,
            'file_path': track.filePath,
            'track_order': track.trackOrder,
            'scanned_at': track.scannedAtMs,
          });
        }
      }
    });
  }

  Future<List<LocalAlbum>> listAlbums({String? query}) async {
    final database = await _db.database;
    final rows = query == null || query.trim().isEmpty
        ? await database.query(
            'local_albums',
            orderBy: 'title COLLATE NOCASE ASC',
          )
        : await database.query(
            'local_albums',
            where: 'title LIKE ? OR artist LIKE ?',
            whereArgs: ['%$query%', '%$query%'],
            orderBy: 'title COLLATE NOCASE ASC',
          );
    return rows.map(LocalAlbum.fromMap).toList();
  }

  Future<List<LocalTrack>> tracksForAlbum(int albumId) async {
    final database = await _db.database;
    final rows = await database.query(
      'local_tracks',
      where: 'album_id = ?',
      whereArgs: [albumId],
      orderBy: 'track_order ASC',
    );
    return rows.map(LocalTrack.fromMap).toList();
  }
}
