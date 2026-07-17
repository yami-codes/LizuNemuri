import 'package:flutter_test/flutter_test.dart';
import 'package:lizunemu/core/lore/streaming_lore_track_parser.dart';

void main() {
  group('StreamingLoreTrackParser', () {
    test('parses NDJSON across chunk boundaries', () {
      final parser = StreamingLoreTrackParser();
      final a = parser.feed(
        '{"type":"summary","trackKey":"t1","summary":"hello"}\n{"type":"eve',
      );
      expect(a, hasLength(1));
      expect(a.first, isA<LoreTrackStreamSummary>());

      final b = parser.feed(
        'nt","id":"e1","trackKey":"t1","title":"Beat","kind":"beat","detail":""}\n',
      );
      expect(b, hasLength(1));
      expect(b.first, isA<LoreTrackStreamEvent>());

      final c = parser.feed(
        '{"type":"carry","carryUpdates":{"c1":{"arousal":10}}}\n',
      );
      expect(c, hasLength(1));
      expect(c.first, isA<LoreTrackStreamCarry>());
      final carry = c.first as LoreTrackStreamCarry;
      expect(carry.carryUpdates['c1'], isA<Map>());
    });

    test('flush parses trailing line without newline', () {
      final parser = StreamingLoreTrackParser();
      parser.feed('{"type":"summary","trackKey":"t","summary":"x"}');
      final items = parser.flush();
      expect(items, hasLength(1));
      expect(items.first, isA<LoreTrackStreamSummary>());
    });

    test('ignores markdown fences', () {
      final parser = StreamingLoreTrackParser();
      final items = parser.feed('```json\n{"type":"summary","summary":"a"}\n```\n');
      expect(items.whereType<LoreTrackStreamSummary>(), hasLength(1));
    });

    test('legacy single-object blob expands on flush', () {
      final parser = StreamingLoreTrackParser();
      parser.feed(
        '{"summary":{"trackKey":"t","summary":"s"},'
        '"events":[{"id":"e1","title":"A","kind":"beat","detail":""}],'
        '"carryUpdates":{"c1":{"x":1}}}',
      );
      final items = parser.flush();
      expect(items.whereType<LoreTrackStreamSummary>(), hasLength(1));
      expect(items.whereType<LoreTrackStreamEvent>(), hasLength(1));
      expect(items.whereType<LoreTrackStreamCarry>(), hasLength(1));
    });

    test('event with map-shaped deltas survives loreEventFromStreamMap', () {
      final e = loreEventFromStreamMap(
        {
          'type': 'event',
          'title': 'Ramp',
          'kind': 'paramChange',
          'detail': '',
          'deltas': {
            'arousal': {'from': 0, 'to': 40},
          },
        },
        trackKey: 'tk',
        newId: () => 'nid',
      );
      expect(e.trackKey, 'tk');
      expect(e.deltas, isNotEmpty);
      expect(e.deltas.first.key, 'arousal');
    });
  });
}
