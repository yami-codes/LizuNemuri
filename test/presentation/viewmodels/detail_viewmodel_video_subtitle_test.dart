import 'package:flutter_test/flutter_test.dart';
import 'package:lizunemu/data/models/files/child.dart';
import 'package:lizunemu/data/models/files/files.dart';
import 'package:lizunemu/presentation/viewmodels/detail_viewmodel.dart';

void main() {
  group('DetailViewModel.matchingSubtitleFor', () {
    test('pairs video with sibling vtt in same folder', () {
      final files = Files(
        children: [
          Child(type: 'video', title: 'intro.mp4'),
          Child(type: 'text', title: 'intro.vtt'),
        ],
      );
      final video = files.children!.first;
      final match = DetailViewModel.matchingSubtitleFor(video, files);
      expect(match?.title, 'intro.vtt');
    });

    test('returns null when no sibling subtitle', () {
      final files = Files(
        children: [
          Child(type: 'video', title: 'intro.mp4'),
        ],
      );
      expect(
        DetailViewModel.matchingSubtitleFor(files.children!.first, files),
        isNull,
      );
    });
  });
}
