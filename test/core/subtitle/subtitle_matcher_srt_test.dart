import 'package:flutter_test/flutter_test.dart';
import 'package:lizunemu/core/subtitle/utils/subtitle_matcher.dart';
import 'package:lizunemu/data/models/files/child.dart';

void main() {
  test('SubtitleMatcher recognizes srt/txt siblings', () {
    final siblings = [
      Child(type: 'audio', title: '01.intro.mp3'),
      Child(type: 'text', title: '01.intro.srt'),
    ];
    final match = SubtitleMatcher.findMatchingSubtitle(
      '01.intro.mp3',
      siblings,
    );
    expect(match?.title, '01.intro.srt');
  });
}
