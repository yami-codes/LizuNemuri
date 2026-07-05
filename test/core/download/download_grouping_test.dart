import 'package:flutter_test/flutter_test.dart';
import 'package:xuro/core/download/models/download_entry.dart';
import 'package:xuro/core/download/utils/download_grouping.dart';

DownloadEntry _entry({
  required String workId,
  required String fileKey,
  required String fileName,
  String mediaType = 'audio',
  int createdAt = 0,
  int size = 100,
}) {
  return DownloadEntry(
    workId: workId,
    fileKey: fileKey,
    fileName: fileName,
    filePath: '/tmp/$fileKey/$fileName',
    mediaType: mediaType,
    sourceUrl: 'https://example.com/$fileKey',
    size: size,
    createdAt: createdAt,
  );
}

void main() {
  group('groupDownloadsByWork', () {
    test('groups by workId and sorts works newest-first', () {
      final groups = groupDownloadsByWork([
        _entry(workId: '1', fileKey: 'a', fileName: 'a.mp3', createdAt: 100),
        _entry(workId: '2', fileKey: 'b', fileName: 'b.mp3', createdAt: 300),
        _entry(workId: '1', fileKey: 'c', fileName: 'c.mp3', createdAt: 200),
      ]);

      expect(groups.length, 2);
      expect(groups[0].workId, '2');
      expect(groups[1].workId, '1');
      expect(groups[1].entries.map((e) => e.fileKey), ['c', 'a']);
    });

    test('empty input returns empty list', () {
      expect(groupDownloadsByWork([]), isEmpty);
    });
  });

  group('isPlayableAudioEntry', () {
    test('video extension wins over audio mediaType', () {
      expect(
        isPlayableAudioEntry(
          _entry(
            workId: '1',
            fileKey: 'v',
            fileName: 'intro.mp4',
            mediaType: 'audio',
          ),
        ),
        isFalse,
      );
    });

    test('audio entry is playable', () {
      expect(
        isPlayableAudioEntry(
          _entry(
            workId: '1',
            fileKey: 'a',
            fileName: 'track.mp3',
            mediaType: 'audio',
          ),
        ),
        isTrue,
      );
    });
  });

  group('DownloadWorkGroup', () {
    test('aggregates file count and total size', () {
      final group = DownloadWorkGroup(
        workId: '42',
        entries: [
          _entry(workId: '42', fileKey: 'a', fileName: 'a.mp3', size: 100),
          _entry(workId: '42', fileKey: 'b', fileName: 'b.mp3', size: 250),
        ],
      );

      expect(group.fileCount, 2);
      expect(group.totalSizeBytes, 350);
      expect(group.hasPlayableAudio, isTrue);
      expect(group.audioEntries.length, 2);
    });
  });
}
