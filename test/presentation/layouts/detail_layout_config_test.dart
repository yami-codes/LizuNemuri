import 'package:flutter_test/flutter_test.dart';
import 'package:lizunemu/presentation/layouts/detail_layout_config.dart';

void main() {
  group('DetailLayoutConfig', () {
    test('wide layout at tablet breakpoint and above', () {
      expect(DetailLayoutConfig.isWideLayout(799), isFalse);
      expect(DetailLayoutConfig.isWideLayout(800), isTrue);
      expect(DetailLayoutConfig.isWideLayout(1920), isTrue);
    });
  });
}
