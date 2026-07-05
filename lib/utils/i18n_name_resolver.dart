import 'package:flutter/widgets.dart';
import 'package:lizunemu/data/models/works/i18n.dart';

/// Resolves API-provided [I18n] display names by device [Locale].
///
/// Search / navigation keys must still use the API's canonical [name] field;
/// this helper is display-only.
class I18nNameResolver {
  I18nNameResolver._();

  static String resolve(
    I18n? i18n, {
    Locale? locale,
    String fallback = '',
  }) {
    if (i18n == null) return fallback;
    for (final pick in _pickOrder(locale ?? const Locale('zh'))) {
      final name = _nameFor(i18n, pick);
      if (name != null && name.isNotEmpty) return name;
    }
    return fallback;
  }

  /// All non-empty localized names — useful for browse search filters.
  static Iterable<String> searchableNames(I18n? i18n) sync* {
    if (i18n == null) return;
    for (final name in [
      i18n.enUs?.name,
      i18n.zhCn?.name,
      i18n.jaJp?.name,
      i18n.thTh?.name,
    ]) {
      if (name != null && name.isNotEmpty) yield name;
    }
  }

  static List<_LocalePick> _pickOrder(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return const [
          _LocalePick.en,
          _LocalePick.zh,
          _LocalePick.ja,
          _LocalePick.th,
        ];
      case 'th':
        return const [
          _LocalePick.th,
          _LocalePick.en,
          _LocalePick.zh,
          _LocalePick.ja,
        ];
      case 'ja':
        return const [
          _LocalePick.ja,
          _LocalePick.en,
          _LocalePick.zh,
          _LocalePick.th,
        ];
      case 'zh':
        return const [
          _LocalePick.zh,
          _LocalePick.en,
          _LocalePick.ja,
          _LocalePick.th,
        ];
      default:
        return const [
          _LocalePick.en,
          _LocalePick.zh,
          _LocalePick.ja,
          _LocalePick.th,
        ];
    }
  }

  static String? _nameFor(I18n i18n, _LocalePick pick) {
    switch (pick) {
      case _LocalePick.en:
        return i18n.enUs?.name;
      case _LocalePick.zh:
        return i18n.zhCn?.name;
      case _LocalePick.ja:
        return i18n.jaJp?.name;
      case _LocalePick.th:
        return i18n.thTh?.name;
    }
  }
}

enum _LocalePick { en, zh, ja, th }
