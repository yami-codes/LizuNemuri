import 'package:flutter_test/flutter_test.dart';
import 'package:xuro/core/dlsite/dlsite_json_utils.dart';

void main() {
  group('dlsite_json_utils', () {
    test('extractRj finds RJ code', () {
      expect(dlsiteExtractRj('search RJ123456 please'), 'RJ123456');
    });

    test('pickLocalized prefers zh_CN', () {
      expect(
        dlsitePickLocalized({
          'en_US': 'English',
          'zh_CN': '中文',
        }),
        '中文',
      );
    });

    test('mergeCookies overwrites keys', () {
      final merged = dlsiteMergeCookies(
        'a=1; b=2',
        ['b=9; Path=/'],
      );
      expect(merged, contains('a=1'));
      expect(merged, contains('b=9'));
      expect(merged, isNot(contains('b=2')));
    });
  });
}
