import 'package:flutter_test/flutter_test.dart';
import 'package:lizunemu/core/media/work_media_utils.dart';
import 'package:lizunemu/data/models/files/child.dart';
import 'package:lizunemu/data/models/files/files.dart';

void main() {
  group('WorkMediaUtils.findMatchingFile', () {
    test('matches by hash first', () {
      final target = Child(type: 'audio', title: '01.wav', hash: 'abc');
      final tree = <Child>[
        Child(type: 'audio', title: 'other.wav', hash: 'xyz'),
        Child(type: 'audio', title: '01.wav', hash: 'abc', mediaDownloadUrl: 'https://fresh'),
      ];
      final found = WorkMediaUtils.findMatchingFile(tree, target);
      expect(found?.mediaDownloadUrl, 'https://fresh');
    });

    test('falls back to title match', () {
      final target = Child(type: 'audio', title: 'track.wav');
      final tree = <Child>[
        Child(type: 'audio', title: 'track.wav', mediaDownloadUrl: 'https://fresh'),
      ];
      expect(
        WorkMediaUtils.findMatchingFile(tree, target)?.mediaDownloadUrl,
        'https://fresh',
      );
    });

    test('walks folders', () {
      final target = Child(type: 'audio', title: 'nested.vtt');
      final tree = <Child>[
        Child(
          type: 'folder',
          title: 'mp3',
          children: [
            Child(type: 'text', title: 'nested.vtt', mediaDownloadUrl: 'https://sub'),
          ],
        ),
      ];
      expect(
        WorkMediaUtils.findMatchingFile(tree, target)?.mediaDownloadUrl,
        'https://sub',
      );
    });
  });

  group('WorkMediaUtils.patchFileInTree', () {
    test('updates matching leaf url in place', () {
      final nodes = <Child>[
        Child(type: 'audio', title: 'a.wav', mediaDownloadUrl: 'old'),
      ];
      final fresh = Child(type: 'audio', title: 'a.wav', mediaDownloadUrl: 'new');
      final target = Child(type: 'audio', title: 'a.wav', mediaDownloadUrl: 'old');
      expect(WorkMediaUtils.patchFileInTree(nodes, target, fresh), isTrue);
      expect(nodes.first.mediaDownloadUrl, 'new');
    });
  });

  group('WorkMediaUtils.patchInFiles', () {
    test('patches unmodifiable Freezed tree without mutating original', () {
      final stale = Child(type: 'audio', title: 'a.wav', mediaDownloadUrl: 'old');
      final fresh = Child(type: 'audio', title: 'a.wav', mediaDownloadUrl: 'new');
      final target = stale;
      final tree = Files(type: 'folder', children: [stale]);

      final patched = WorkMediaUtils.patchInFiles(tree, target, fresh);

      expect(patched, isNotNull);
      expect(patched!.children!.first.mediaDownloadUrl, 'new');
      expect(tree.children!.first.mediaDownloadUrl, 'old');
    });

    test('patches nested folder leaf', () {
      final target = Child(type: 'audio', title: 'nested.wav');
      final tree = Files(
        type: 'folder',
        children: [
          Child(
            type: 'folder',
            title: 'mp3',
            children: [
              Child(type: 'audio', title: 'nested.wav', mediaDownloadUrl: 'old'),
            ],
          ),
        ],
      );
      final fresh = Child(type: 'audio', title: 'nested.wav', mediaDownloadUrl: 'new');

      final patched = WorkMediaUtils.patchInFiles(tree, target, fresh);

      expect(
        patched?.children?.first.children?.first.mediaDownloadUrl,
        'new',
      );
    });
  });
}
