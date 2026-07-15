import 'package:lizunemu/core/audio/models/playback_context.dart';
import 'package:lizunemu/core/audio/models/subtitle.dart';
import 'package:lizunemu/core/llm/subtitle_translation_service.dart';
import 'package:lizunemu/core/settings/app_settings_service.dart';
import 'package:lizunemu/core/subtitle/subtitle_loader.dart';
import 'package:lizunemu/data/models/files/child.dart';
import 'package:lizunemu/data/models/files/files.dart';
import 'package:lizunemu/data/models/works/work.dart';
import 'package:lizunemu/utils/logger.dart';

/// Ensures lore subtitle payloads are in [AppSettingsService.resolvedLoreLanguageCode].
class LoreSubtitleLanguagePipeline {
  final SubtitleLoader _loader;
  final SubtitleTranslationService _translation;
  final AppSettingsService _settings;

  LoreSubtitleLanguagePipeline({
    required SubtitleLoader loader,
    required SubtitleTranslationService translation,
    required AppSettingsService settings,
  })  : _loader = loader,
        _translation = translation,
        _settings = settings;

  /// Map lore language code → translation target code.
  static String loreLanguageToTargetCode(String loreLang) {
    final code = loreLang.trim().toLowerCase();
    if (code.startsWith('zh')) return 'zh';
    if (code.startsWith('th')) return 'th';
    if (code.startsWith('ja')) return 'ja';
    if (code.startsWith('ko')) return 'ko';
    if (code.startsWith('en')) return 'en';
    return 'en';
  }

  /// Cheap heuristic: already mostly the target script.
  static bool looksLikeTargetLanguage(String text, String targetCode) {
    final sample = text.length > 800 ? text.substring(0, 800) : text;
    if (sample.trim().isEmpty) return false;

    bool isHan(int r) => r >= 0x4E00 && r <= 0x9FFF;
    bool isThai(int r) => r >= 0x0E00 && r <= 0x0E7F;
    bool isHangul(int r) =>
        (r >= 0xAC00 && r <= 0xD7AF) || (r >= 0x1100 && r <= 0x11FF);
    bool isKana(int r) =>
        (r >= 0x3040 && r <= 0x30FF) || (r >= 0x31F0 && r <= 0x31FF);
    bool isLatin(int r) =>
        (r >= 0x41 && r <= 0x5A) ||
        (r >= 0x61 && r <= 0x7A) ||
        (r >= 0xC0 && r <= 0x024F);
    bool isLetter(int r) =>
        isHan(r) || isThai(r) || isHangul(r) || isKana(r) || isLatin(r);

    var letters = 0;
    var hit = 0;
    for (final r in sample.runes) {
      if (!isLetter(r)) continue;
      letters++;
      final match = switch (targetCode) {
        'zh' => isHan(r),
        'th' => isThai(r),
        'ko' => isHangul(r),
        'ja' => isHan(r) || isKana(r),
        'en' => isLatin(r),
        _ => isLatin(r),
      };
      if (match) hit++;
    }
    if (letters < 20) return false;
    return hit / letters >= 0.55;
  }

  static String formatSubtitleListForLore(SubtitleList list) {
    final buf = StringBuffer();
    for (final s in list.subtitles) {
      final start = _fmt(s.start);
      final end = _fmt(s.end);
      buf.writeln('$start --> $end');
      buf.writeln(s.text.trim());
      buf.writeln();
    }
    return buf.toString().trim();
  }

  static String _fmt(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final sec = (d.inSeconds % 60).toString().padLeft(2, '0');
    final ms = (d.inMilliseconds % 1000).toString().padLeft(3, '0');
    return '$h:$m:$sec.$ms';
  }

  /// Parse [raw], translate to lore language when needed, return lore-facing text.
  Future<String?> ensureForLore({
    required String? raw,
    required Work work,
    required Child audio,
    Files? files,
  }) async {
    if (raw == null || raw.trim().isEmpty) return null;

    final loreLang = _settings.resolvedLoreLanguageCode;
    final target = loreLanguageToTargetCode(loreLang);

    if (looksLikeTargetLanguage(raw, target)) {
      return raw;
    }

    final parsed = _loader.parseOrNull(raw);
    if (parsed == null || parsed.subtitles.isEmpty) {
      return raw;
    }

    final ctx = PlaybackContext(
      work: work,
      files: files ?? Files(type: 'folder', children: [audio]),
      currentFile: audio,
    );

    try {
      final result = await _translation.translateNow(
        source: parsed,
        context: ctx,
        targetLanguageCode: target,
      );
      if (result.isFailure || result.skipped) {
        AppLogger.warning(
          'Lore subtitle translate soft-fail for ${audio.title}: '
          '${result.error?.userMessage ?? 'skipped'}',
        );
        return raw;
      }
      return formatSubtitleListForLore(result.list);
    } catch (e, st) {
      AppLogger.error('Lore subtitle translate failed', e, st);
      return raw;
    }
  }
}
