import 'package:flutter_test/flutter_test.dart';
import 'package:lizunemu/core/llm/streaming_metadata_parser.dart';

void main() {
  test('parses NDJSON id/text lines incrementally', () {
    final parser = StreamingMetadataParser();
    expect(parser.feed('{"id":"a","text":"Al'), isEmpty);
    final batch = parser.feed('pha"}\n{"id":"b","text":"Beta"}\n');
    expect(batch.length, 2);
    expect(batch[0].key, 'a');
    expect(batch[0].value, 'Alpha');
    expect(batch[1].key, 'b');
    expect(batch[1].value, 'Beta');
  });

  test('parses JSON array fallback in one chunk', () {
    final parser = StreamingMetadataParser();
    final batch = parser.feed(
      '[{"id":"1","text":"One"},{"id":"2","text":"Two"}]\n',
    );
    expect(batch.length, 2);
    expect(batch.map((e) => e.key).toList(), ['1', '2']);
    expect(batch.map((e) => e.value).toList(), ['One', 'Two']);
  });
}
