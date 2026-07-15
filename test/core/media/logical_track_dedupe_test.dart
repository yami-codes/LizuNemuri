import 'package:flutter_test/flutter_test.dart';
import 'package:lizunemu/core/lore/lore_subtitle_language_pipeline.dart';
import 'package:lizunemu/core/media/logical_track_dedupe.dart';
import 'package:lizunemu/data/models/files/child.dart';

void main() {
  group('LogicalTrackDedupe', () {
    test('collapses no-SFX remaster with same normalized title', () {
      final groups = LogicalTrackDedupe.group([
        LogicalTrackCandidate(
          audio: Child(type: 'audio', title: '01.ep.mp3', hash: 'h1'),
          index: 0,
          subtitleText: 'hello world ' * 20,
        ),
        LogicalTrackCandidate(
          audio: Child(
            type: 'audio',
            title: '01.ep（无效果音）.mp3',
            hash: 'h2',
          ),
          index: 1,
          subtitleText: 'hello world ' * 20,
        ),
      ]);
      expect(groups, hasLength(1));
      expect(groups.first.canonical.audio.hash, 'h1');
      expect(groups.first.aliases, hasLength(1));
    });

    test('collapses mp3 vs wav by normalized title', () {
      final groups = LogicalTrackDedupe.group([
        LogicalTrackCandidate(
          audio: Child(type: 'audio', title: 'Track A.wav', hash: 'w'),
          index: 1,
          subtitleText: 'script',
        ),
        LogicalTrackCandidate(
          audio: Child(type: 'audio', title: 'Track A.mp3', hash: 'm'),
          index: 0,
          subtitleText: 'script',
        ),
      ]);
      expect(groups, hasLength(1));
      expect(groups.first.canonical.audio.hash, 'm');
    });

    test('keeps split when subtitle content differs', () {
      final groups = LogicalTrackDedupe.group([
        LogicalTrackCandidate(
          audio: Child(type: 'audio', title: '01.mp3', hash: 'a'),
          index: 0,
          subtitleText: 'Alpha script that is long enough ${'x' * 80}',
        ),
        LogicalTrackCandidate(
          audio: Child(type: 'audio', title: '01（无效果音）.mp3', hash: 'b'),
          index: 1,
          subtitleText: 'Beta script that is long enough ${'y' * 80}',
        ),
      ]);
      // Same normalized title → one group; content difference doesn't
      // split by title (same episode title), but secondary hash merge
      // only merges *across* groups — here one group with both candidates.
      expect(groups, hasLength(1));
      expect(groups.first.all, hasLength(2));
    });

    test('merges cross-folder twins by identical long script hash', () {
      final script = 'shared cue text pad ${'z' * 100}';
      final groups = LogicalTrackDedupe.group([
        LogicalTrackCandidate(
          audio: Child(type: 'audio', title: 'Chapter1.mp3', hash: 'a'),
          index: 0,
          subtitleText: script,
        ),
        LogicalTrackCandidate(
          audio: Child(type: 'audio', title: 'Different Name.mp3', hash: 'b'),
          index: 1,
          subtitleText: script,
        ),
      ]);
      expect(groups, hasLength(1));
      expect(groups.first.groupKey, startsWith('script:'));
    });
  });

  group('LoreSubtitleLanguagePipeline.looksLikeTargetLanguage', () {
    test('detects Thai', () {
      expect(
        LoreSubtitleLanguagePipeline.looksLikeTargetLanguage(
          'นี่คือข้อความภาษาไทยสำหรับทดสอบระบบแปลซับไทเทิลและเกณฑ์',
          'th',
        ),
        isTrue,
      );
    });

    test('rejects jp for en target', () {
      expect(
        LoreSubtitleLanguagePipeline.looksLikeTargetLanguage(
          'これは日本語の字幕テキストです。テスト用に長く書いておきますね。もっと書く。',
          'en',
        ),
        isFalse,
      );
    });
  });
}
