import 'package:lizunemu/core/download/models/download_entry.dart';

abstract class IDownloadRepository {
  /// Lookup by stable identity key ([fileKey], **not** display name).
  Future<DownloadEntry?> find(String workId, String fileKey);
  Future<void> upsert(DownloadEntry entry);
  Future<void> remove(String workId, String fileKey);
  Future<List<DownloadEntry>> listByWork(String workId);

  /// All entries oldest-first by createdAt — for LRU capacity enforcement.
  Future<List<DownloadEntry>> listAllOldestFirst();
}
