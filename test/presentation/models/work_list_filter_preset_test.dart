import 'package:flutter_test/flutter_test.dart';
import 'package:lizunemu/presentation/models/filter_state.dart';
import 'package:lizunemu/presentation/models/work_list_filter_preset.dart';

void main() {
  group('WorkListFilterPreset', () {
    test('maps preset to API order and sort', () {
      expect(
        const FilterState().copyWithPreset(WorkListFilterPreset.sales).orderField,
        'dl_count',
      );
      expect(
        const FilterState()
            .copyWithPreset(WorkListFilterPreset.priceLow)
            .sortValue,
        'asc',
      );
      expect(WorkListFilterPreset.random.showSortDirection, isFalse);
    });

    test('round-trips through FilterState.activePreset', () {
      for (final preset in WorkListFilterPreset.values) {
        final state = FilterState(
          orderField: preset.orderField,
          isDescending: preset.isDescending,
        );
        expect(state.activePreset, preset);
      }
    });
  });
}
