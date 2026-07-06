import 'package:flutter/widgets.dart';
import 'package:lizunemu/core/settings/app_language.dart';
import 'package:lizunemu/data/models/works/i18n.dart';
import 'package:lizunemu/utils/i18n_name_resolver.dart';

/// Display-only tag labels for filter chips and search tokens.
///
/// When app language is Chinese, prefer zh-CN. Otherwise prefer English
/// (en-us) so EN/TH/system users see readable Latin labels while the API
/// filter key remains the canonical [Tag.name].
class TagDisplayName {
  TagDisplayName._();

  static Locale _displayLocale(AppLanguage language) {
    if (language == AppLanguage.zh) return const Locale('zh');
    return const Locale('en');
  }

  static String forTag({
    required String apiName,
    I18n? i18n,
    required AppLanguage appLanguage,
  }) {
    return I18nNameResolver.resolve(
      i18n,
      locale: _displayLocale(appLanguage),
      fallback: apiName,
    );
  }

  static String forApiName({
    required String apiName,
    Map<String, I18n>? catalog,
    required AppLanguage appLanguage,
  }) {
    final i18n = catalog?[apiName];
    return forTag(apiName: apiName, i18n: i18n, appLanguage: appLanguage);
  }
}
