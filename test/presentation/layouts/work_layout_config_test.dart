import 'package:flutter_test/flutter_test.dart';
import 'package:xuro/presentation/layouts/work_layout_config.dart';

void main() {
  group('WorkLayoutConfig.columnsForWidth', () {
    test('mobile width yields 2 columns', () {
      expect(WorkLayoutConfig.columnsForWidth(400), 2);
    });

    test('tablet width yields more than 2 columns', () {
      final cols = WorkLayoutConfig.columnsForWidth(900);
      expect(cols, greaterThanOrEqualTo(3));
      expect(cols, lessThanOrEqualTo(WorkLayoutConfig.maxColumns));
    });

    test('desktop width yields dense grid (not 2 giant cards)', () {
      final cols = WorkLayoutConfig.columnsForWidth(1400);
      expect(cols, greaterThanOrEqualTo(6));
    });

    test('ultra-wide caps at maxColumns', () {
      expect(
        WorkLayoutConfig.columnsForWidth(4000),
        WorkLayoutConfig.maxColumns,
      );
    });
  });
}
