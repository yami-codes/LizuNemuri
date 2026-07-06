import 'package:flutter_test/flutter_test.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:lizunemu/widgets/lyrics/components/player_lyric_view.dart';

void main() {
  group('lyricKineticEmphasis', () {
    test('returns 1.0 when item center matches viewport center', () {
      const position = ItemPosition(
        index: 0,
        itemLeadingEdge: 0.45,
        itemTrailingEdge: 0.55,
      );
      expect(lyricKineticEmphasis(position), closeTo(1.0, 0.01));
    });

    test('falls off toward min emphasis as item moves away from center', () {
      const near = ItemPosition(
        index: 0,
        itemLeadingEdge: 0.4,
        itemTrailingEdge: 0.5,
      );
      const far = ItemPosition(
        index: 1,
        itemLeadingEdge: 0.0,
        itemTrailingEdge: 0.1,
      );
      expect(lyricKineticEmphasis(near), greaterThan(lyricKineticEmphasis(far)));
      expect(lyricKineticEmphasis(far), closeTo(0.22, 0.05));
    });
  });

  group('lyricEmphasisForIndex', () {
    test('active line always returns 1.0', () {
      expect(
        lyricEmphasisForIndex(
          index: 2,
          isActive: true,
          positions: const [],
        ),
        1.0,
      );
    });

    test('uses position proximity for inactive visible lines', () {
      const positions = [
        ItemPosition(
          index: 1,
          itemLeadingEdge: 0.48,
          itemTrailingEdge: 0.52,
        ),
      ];
      final emphasis = lyricEmphasisForIndex(
        index: 1,
        isActive: false,
        positions: positions,
      );
      expect(emphasis, greaterThan(0.9));
    });

    test('off-screen inactive lines use baseline emphasis', () {
      expect(
        lyricEmphasisForIndex(
          index: 0,
          isActive: false,
          positions: const [],
        ),
        0.22,
      );
    });
  });
}
