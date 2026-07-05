import 'dart:ui' show Locale;

/// Target language for LLM subtitle translation (independent of UI locale).
enum LlmSubtitleTargetLanguage {
  system,
  en,
  zh,
  ja,
  th,
  ko,
}

extension LlmSubtitleTargetLanguageX on LlmSubtitleTargetLanguage {
  /// BCP-47-ish code sent to the LLM. `system` resolves via [resolveCode].
  String resolveCode(Locale stringsLocale) {
    switch (this) {
      case LlmSubtitleTargetLanguage.system:
        final code = stringsLocale.languageCode;
        if (code == 'en' || code == 'th' || code.startsWith('zh')) {
          return code.startsWith('zh') ? 'zh' : code;
        }
        return 'en';
      case LlmSubtitleTargetLanguage.en:
        return 'en';
      case LlmSubtitleTargetLanguage.zh:
        return 'zh';
      case LlmSubtitleTargetLanguage.ja:
        return 'ja';
      case LlmSubtitleTargetLanguage.th:
        return 'th';
      case LlmSubtitleTargetLanguage.ko:
        return 'ko';
    }
  }
}
