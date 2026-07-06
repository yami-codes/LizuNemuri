import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:lizunemu/core/translation/metadata_translation_service.dart';
import 'package:lizunemu/data/services/google_translate_client.dart';

void main() {
  group('GoogleTranslateClient.parseBatchResponse', () {
    test('parses single-string response', () {
      const data = [
        [
          ['こんにちは', 'hello', null, null, 10],
        ],
        null,
        'ja',
      ];
      expect(
        GoogleTranslateClient.parseBatchResponse(data, expectedCount: 1),
        ['こんにちは'],
      );
    });

    test('joins multi-chunk single input', () {
      const data = [
        [
          ['Hello', 'Hi', null, null, 3],
          [' world', ' world', null, null, 3],
        ],
      ];
      expect(
        GoogleTranslateClient.parseBatchResponse(data, expectedCount: 1),
        ['Hello world'],
      );
    });
  });

  group('MetadataTranslationService.parseLlmBatchResponse', () {
    test('maps id/text pairs from JSON array', () {
      const raw = '''
[
  {"id":"1","text":"Title A"},
  {"id":"2","text":"Title B"}
]
''';
      final map = MetadataTranslationService.parseLlmBatchResponse(
        raw,
        [
          (id: '1', source: 'A'),
          (id: '2', source: 'B'),
        ],
      );
      expect(map, {'1': 'Title A', '2': 'Title B'});
    });
  });
}
