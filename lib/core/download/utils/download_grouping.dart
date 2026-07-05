import 'package:lizunemu/core/download/models/download_entry.dart';

/// One work's completed downloads (grouped by [workId]).
class DownloadWorkGroup {
  final String workId;
  final List<DownloadEntry> entries;

  const DownloadWorkGroup({
    required this.workId,
    required this.entries,
  });

  int get fileCount => entries.length;

  int get totalSizeBytes =>
      entries.fold<int>(0, (sum, e) => sum + e.size);

  int get latestCreatedAtMs => entries
      .map((e) => e.createdAt)
      .reduce((a, b) => a > b ? a : b);

  List<DownloadEntry> get audioEntries =>
      entries.where(isPlayableAudioEntry).toList(growable: false);

  bool get hasPlayableAudio => audioEntries.isNotEmpty;
}

const _videoExtensions = {'mp4', 'mkv', 'mov', 'avi', 'webm', 'm4v'};

/// Extension wins over API [DownloadEntry.mediaType] (mirrors detail VM).
bool isVideoDownloadEntry(DownloadEntry entry) {
  if (entry.mediaType.toLowerCase() == 'video') return true;
  final parts = entry.fileName.split('.');
  if (parts.length < 2) return false;
  return _videoExtensions.contains(parts.last.toLowerCase());
}

bool isPlayableAudioEntry(DownloadEntry entry) {
  if (isVideoDownloadEntry(entry)) return false;
  return entry.mediaType.toLowerCase() == 'audio';
}

/// Groups [entries] by [DownloadEntry.workId], newest work first; files within
/// a work sorted newest-first by [DownloadEntry.createdAt].
List<DownloadWorkGroup> groupDownloadsByWork(List<DownloadEntry> entries) {
  if (entries.isEmpty) return const [];

  final byWork = <String, List<DownloadEntry>>{};
  for (final entry in entries) {
    byWork.putIfAbsent(entry.workId, () => []).add(entry);
  }

  final groups = byWork.entries.map((e) {
    final sorted = List<DownloadEntry>.from(e.value)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return DownloadWorkGroup(workId: e.key, entries: sorted);
  }).toList();

  groups.sort(
    (a, b) => b.latestCreatedAtMs.compareTo(a.latestCreatedAtMs),
  );
  return groups;
}
