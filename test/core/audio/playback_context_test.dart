import 'package:flutter_test/flutter_test.dart';
import 'package:lizunemu/core/audio/models/playback_context.dart';
import 'package:lizunemu/data/models/files/child.dart';
import 'package:lizunemu/data/models/files/files.dart';
import 'package:lizunemu/data/models/works/work.dart';

void main() {
  group('PlaybackContext playlist', () {
    final work = Work(id: 1, sourceId: 'RJ123');

    Child audio(String title, {String? url}) => Child(
          type: 'audio',
          title: title,
          mediaDownloadUrl: url ?? 'https://example.com/$title',
          size: 100,
        );

    test('builds playlist for m4a siblings in same folder', () {
      final track1 = audio('01.m4a');
      final track2 = audio('02.m4a');
      final other = audio('readme.txt', url: 'https://example.com/readme.txt');
      final files = Files(
        children: [
          Child(
            type: 'folder',
            title: 'tracks',
            children: [track1, track2, other],
          ),
        ],
      );

      final context = PlaybackContext(
        work: work,
        files: files,
        currentFile: track1,
      );

      expect(context.playlist, hasLength(2));
      expect(context.currentIndex, 0);
      expect(context.currentFile, track1);
    });

    test('falls back to single track when siblings cannot be resolved', () {
      final lone = audio('bonus.flac');
      final files = Files(children: [lone]);

      final context = PlaybackContext(
        work: work,
        files: files,
        currentFile: lone,
      );

      expect(context.playlist, [lone]);
      expect(context.currentIndex, 0);
    });

    test('mp3 playlist still works', () {
      final a = audio('a.mp3');
      final b = audio('b.mp3');
      final files = Files(children: [a, b]);

      final context = PlaybackContext(
        work: work,
        files: files,
        currentFile: b,
      );

      expect(context.playlist, [a, b]);
      expect(context.currentIndex, 1);
    });
  });
}
