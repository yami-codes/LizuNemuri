/// Local album grouped by containing folder (Eara library model v1).
class LocalAlbum {
  const LocalAlbum({
    required this.id,
    required this.albumKey,
    required this.title,
    required this.artist,
    required this.folderPath,
    required this.trackCount,
    required this.scannedAtMs,
  });

  final int id;
  final String albumKey;
  final String title;
  final String? artist;
  final String folderPath;
  final int trackCount;
  final int scannedAtMs;

  factory LocalAlbum.fromMap(Map<String, Object?> row) => LocalAlbum(
        id: row['id']! as int,
        albumKey: row['album_key']! as String,
        title: row['title']! as String,
        artist: row['artist'] as String?,
        folderPath: row['folder_path']! as String,
        trackCount: row['track_count']! as int,
        scannedAtMs: row['scanned_at']! as int,
      );
}

/// One scanned audio file under a [LocalAlbum].
class LocalTrack {
  const LocalTrack({
    required this.id,
    required this.albumId,
    required this.title,
    required this.filePath,
    required this.trackOrder,
    required this.scannedAtMs,
  });

  final int id;
  final int albumId;
  final String title;
  final String filePath;
  final int trackOrder;
  final int scannedAtMs;

  factory LocalTrack.fromMap(Map<String, Object?> row) => LocalTrack(
        id: row['id']! as int,
        albumId: row['album_id']! as int,
        title: row['title']! as String,
        filePath: row['file_path']! as String,
        trackOrder: row['track_order']! as int,
        scannedAtMs: row['scanned_at']! as int,
      );
}
