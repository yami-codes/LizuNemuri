/// One completed local download record.
///
/// Plain class + toMap/fromMap, no codegen. Dedup key is [fileKey], matching
/// `UNIQUE(work_id, file_key)` — **not** display [fileName].
class DownloadEntry {
  final int? id;
  final String workId;

  /// Stable identity digest (md5(hash|url|title)) for dedup/query/delete.
  final String fileKey;

  /// Original display filename (`Child.title`) for UI only.
  final String fileName;
  final String filePath;

  /// 'audio' | 'video' from `Child.type` — audio pipeline vs external viewer offline.
  final String mediaType;
  final String sourceUrl;
  final int size;
  final int createdAt;

  const DownloadEntry({
    this.id,
    required this.workId,
    required this.fileKey,
    required this.fileName,
    required this.filePath,
    required this.mediaType,
    required this.sourceUrl,
    required this.size,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'work_id': workId,
      'file_key': fileKey,
      'file_name': fileName,
      'file_path': filePath,
      'media_type': mediaType,
      'source_url': sourceUrl,
      'size': size,
      'created_at': createdAt,
    };
  }

  factory DownloadEntry.fromMap(Map<String, dynamic> map) {
    return DownloadEntry(
      id: map['id'] as int?,
      workId: map['work_id'] as String,
      fileKey: map['file_key'] as String,
      fileName: map['file_name'] as String,
      filePath: map['file_path'] as String,
      mediaType: map['media_type'] as String,
      sourceUrl: map['source_url'] as String,
      size: map['size'] as int,
      createdAt: map['created_at'] as int,
    );
  }
}
