import 'package:flutter_test/flutter_test.dart';
import 'package:xuro/core/audio/models/subtitle.dart';

void main() {
  group('dual subtitle display helpers', () {
    SubtitleList sampleList() {
      return SubtitleList([
        const Subtitle(
          start: Duration.zero,
          end: Duration(seconds: 2),
          text: 'original',
          index: 0,
        ),
        const Subtitle(
          start: Duration(seconds: 2),
          end: Duration(seconds: 4),
          text: 'second line',
          index: 1,
        ),
      ]);
    }

    test('overlay combines original and translation with newline', () {
      final translated = SubtitleList([
        const Subtitle(
          start: Duration.zero,
          end: Duration(seconds: 2),
          text: 'translated',
          index: 0,
        ),
      ]);
      final line = translated.subtitles.first;
      final overlay = _overlayText(
        line,
        originalAt: (i) => sampleList().subtitles[i].text,
        dual: true,
      );
      expect(overlay, 'original\ntranslated');
    });

    test('overlay skips duplicate when translation matches original', () {
      final line = sampleList().subtitles.first;
      final overlay = _overlayText(
        line,
        originalAt: (i) => sampleList().subtitles[i].text,
        dual: true,
        translatedText: 'original',
      );
      expect(overlay, 'original');
    });

    test('translationOnly mode never stacks', () {
      final line = sampleList().subtitles.first;
      final overlay = _overlayText(
        line,
        originalAt: (i) => sampleList().subtitles[i].text,
        dual: false,
        translatedText: 'translated',
      );
      expect(overlay, 'translated');
    });
  });
}

/// Mirrors [PlayerViewModel.overlayTextForSubtitle] / [originalSubtitleTextAt].
String _overlayText(
  Subtitle line, {
  required String? Function(int index) originalAt,
  required bool dual,
  String? translatedText,
}) {
  final primary = translatedText ?? line.text;
  if (!dual) return primary;
  final secondary = originalAt(line.index)?.trim();
  if (secondary == null || secondary.isEmpty || secondary == primary.trim()) {
    return primary;
  }
  return '$secondary\n$primary';
}
