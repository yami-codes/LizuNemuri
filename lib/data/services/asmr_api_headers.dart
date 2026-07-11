import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:lizunemu/core/settings/app_language.dart';
import 'package:lizunemu/core/settings/app_settings_service.dart';

/// Browser-like HTTP headers for asmr.one API and CDN fetches.
///
/// Mirrors gate on `Accept-Language` only. **English is banned** — never emit
/// `en` in the chain. English UI (or English system locale) uses Thai.
abstract final class AsmrApiHeaders {
  /// Chinese-primary; no `en` (banned).
  static const zhAcceptLanguage = 'zh-CN,zh;q=0.9,ja;q=0.7';

  /// Thai-primary for English UI / EN system locale; no `en`.
  static const thAcceptLanguage = 'th-TH,th;q=0.9,zh-CN;q=0.8,ja;q=0.7';

  /// Resolve header from persisted UI language (+ system locale when needed).
  static String acceptLanguageFor({
    required AppLanguage appLanguage,
    required Locale stringsLocale,
  }) {
    switch (appLanguage) {
      case AppLanguage.en:
        // English UI → Thai header (English Accept-Language is blocked).
        return thAcceptLanguage;
      case AppLanguage.th:
        return thAcceptLanguage;
      case AppLanguage.zh:
        return zhAcceptLanguage;
      case AppLanguage.system:
        final code = stringsLocale.languageCode;
        if (code == 'en' || code == 'th') return thAcceptLanguage;
        return zhAcceptLanguage;
    }
  }

  static String currentAcceptLanguage() {
    if (GetIt.I.isRegistered<AppSettingsService>()) {
      final settings = GetIt.I<AppSettingsService>();
      return acceptLanguageFor(
        appLanguage: settings.appLanguage,
        stringsLocale: settings.stringsLocale,
      );
    }
    return zhAcceptLanguage;
  }
}
