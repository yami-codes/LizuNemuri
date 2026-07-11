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

  /// Accept-Language for asmr CDN (covers, presigned media). Mirrors gate on
  /// Chinese — always zh regardless of UI language.
  static const cdnAcceptLanguage = zhAcceptLanguage;

  static const _userAgent =
      'Mozilla/5.0 (compatible; Lizunemu/2.0; +https://github.com/yami-codes/LizuNemu)';

  /// Browser-like headers for presigned CDN URLs (no auth token).
  static Map<String, String> get cdnFetchHeaders => {
        'User-Agent': _userAgent,
        'Accept': '*/*',
        'Accept-Language': cdnAcceptLanguage,
      };
}
