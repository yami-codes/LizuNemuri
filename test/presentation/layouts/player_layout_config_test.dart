import 'package:flutter_test/flutter_test.dart';
import 'package:lizunemu/presentation/layouts/player_layout_config.dart';

void main() {
  group('PlayerLayoutConfig', () {
    test('wide layout at desktop widths', () {
      expect(PlayerLayoutConfig.isWideLayout(900), isTrue);
      expect(PlayerLayoutConfig.isWideLayout(1920), isTrue);
      expect(PlayerLayoutConfig.isWideLayout(899), isFalse);
    });

    test('cover size capped on wide screens', () {
      expect(PlayerLayoutConfig.coverSizeForWidth(1920), 240);
      expect(PlayerLayoutConfig.coverSizeForWidth(900), 240);
    });

    test('cover size scales on narrow screens', () {
      final phone = PlayerLayoutConfig.coverSizeForWidth(400);
      expect(phone, greaterThanOrEqualTo(180));
      expect(phone, lessThanOrEqualTo(280));
    });
  });
}
