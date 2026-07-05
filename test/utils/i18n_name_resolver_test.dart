import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xuro/data/models/works/en_us.dart';
import 'package:xuro/data/models/works/i18n.dart';
import 'package:xuro/data/models/works/ja_jp.dart';
import 'package:xuro/data/models/works/th_th.dart';
import 'package:xuro/data/models/works/zh_cn.dart';
import 'package:xuro/utils/i18n_name_resolver.dart';

void main() {
  final sample = I18n(
    enUs: EnUs(name: 'English'),
    zhCn: ZhCn(name: '中文'),
    jaJp: JaJp(name: '日本語'),
    thTh: ThTh(name: 'ไทย'),
  );

  group('I18nNameResolver.resolve', () {
    test('prefers English on en locale', () {
      expect(
        I18nNameResolver.resolve(sample, locale: const Locale('en')),
        'English',
      );
    });

    test('prefers Thai on th locale', () {
      expect(
        I18nNameResolver.resolve(sample, locale: const Locale('th')),
        'ไทย',
      );
    });

    test('falls back when preferred locale missing', () {
      final partial = I18n(enUs: EnUs(name: 'Only EN'), zhCn: ZhCn(name: '仅中文'));
      expect(
        I18nNameResolver.resolve(partial, locale: const Locale('th')),
        'Only EN',
      );
    });

    test('uses fallback string when i18n is null', () {
      expect(
        I18nNameResolver.resolve(null, fallback: 'raw'),
        'raw',
      );
    });
  });

  group('I18nNameResolver.searchableNames', () {
    test('yields all non-empty localized names', () {
      expect(I18nNameResolver.searchableNames(sample).toList(), [
        'English',
        '中文',
        '日本語',
        'ไทย',
      ]);
    });
  });
}
