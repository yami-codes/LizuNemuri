import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
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

    test('single-text blob with expectedCount>1 keeps first join (no empty footgun)',
        () {
      // Real gtx multi-q response is still a single-text blob. Old parser
      // looped flat rows through _joinSegment → ['','']. Now we join once.
      const data = [
        [
          ['สวัสดี', 'こんにちは', null, null, 10],
        ],
        null,
        'ja',
      ];
      expect(
        GoogleTranslateClient.parseBatchResponse(data, expectedCount: 2),
        ['สวัสดี', ''],
      );
    });
  });

  group('GoogleTranslateClient.translateBatch', () {
    test('issues one GET per text and returns each translation', () async {
      final requests = <RequestOptions>[];
      final dio = Dio(BaseOptions(baseUrl: 'https://translate.googleapis.com'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            final q = options.queryParameters['q'] as String;
            final translated = switch (q) {
              'こんにちは' => 'สวัสดี',
              '第1章' => 'บทที่ 1',
              _ => '???',
            };
            handler.resolve(
              Response(
                requestOptions: options,
                data: [
                  [
                    [translated, q, null, null, 10],
                  ],
                  null,
                  'ja',
                ],
                statusCode: 200,
              ),
            );
          },
        ),
      );

      final client = GoogleTranslateClient(dio: dio);
      final out = await client.translateBatch(
        texts: ['こんにちは', '第1章'],
        targetLang: 'th',
      );

      expect(out, ['สวัสดี', 'บทที่ 1']);
      expect(requests, hasLength(2));
      expect(requests[0].queryParameters['q'], 'こんにちは');
      expect(requests[1].queryParameters['q'], '第1章');
      // Must not send a List q (legacy multi-q).
      expect(requests[0].queryParameters['q'], isA<String>());
      expect(requests[1].queryParameters['q'], isA<String>());
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
