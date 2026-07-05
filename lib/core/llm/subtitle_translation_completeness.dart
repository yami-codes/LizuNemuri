import 'package:lizunemu/core/audio/models/subtitle.dart';

/// Helpers for deciding which subtitle lines still need LLM translation.
class SubtitleTranslationCompleteness {
  SubtitleTranslationCompleteness._();

  /// True when [text] is a finished translation (differs from source).
  static bool isLineTranslated(Subtitle source, String? text) =>
      text != null && text.trim().isNotEmpty && text.trim() != source.text.trim();

  /// Lines that still need an LLM pass.
  static List<Subtitle> pendingLines(
    SubtitleList source,
    Map<int, String> lines,
  ) =>
      source.subtitles
          .where((s) => !isLineTranslated(s, lines[s.index]))
          .toList();

  /// Count of lines with a distinct translation.
  static int translatedCount(SubtitleList source, Map<int, String> lines) =>
      source.subtitles
          .where((s) => isLineTranslated(s, lines[s.index]))
          .length;

  /// All cues have a translation that differs from the original.
  static bool isComplete(SubtitleList source, Map<int, String> lines) =>
      source.subtitles.isNotEmpty &&
      pendingLines(source, lines).isEmpty;
}
