import 'package:flutter_test/flutter_test.dart';
import 'package:lizunemu/core/audio/models/playback_context.dart';
import 'package:lizunemu/core/llm/llm_translation_context_builder.dart';
import 'package:lizunemu/data/models/files/child.dart';
import 'package:lizunemu/data/models/files/files.dart';
import 'package:lizunemu/data/models/works/circle.dart';
import 'package:lizunemu/data/models/works/work.dart';
import 'package:lizunemu/data/services/llm_client.dart';

void main() {
  group('LlmClient.parseJsonArrayResponse', () {
    test('parses raw JSON array', () {
      final list = LlmClient.parseJsonArrayResponse(
        '[{"index":0,"text":"hello"},{"index":1,"text":"world"}]',
      );
      expect(list, hasLength(2));
      expect(list[0]['index'], 0);
      expect(list[0]['text'], 'hello');
    });

    test('parses fenced JSON', () {
      final list = LlmClient.parseJsonArrayResponse('''
```json
[{"index":2,"text":"line"}]
```
''');
      expect(list.single['index'], 2);
      expect(list.single['text'], 'line');
    });
  });

  group('LlmTranslationContextBuilder', () {
    test('includes work and playlist context', () {
      final work = Work(
        id: 42,
        sourceId: 'RJ999',
        title: 'Test Work',
        circle: Circle(name: 'Test Circle'),
        nsfw: true,
      );
      final a = Child(type: 'audio', title: '01.mp3', mediaDownloadUrl: 'u1');
      final b = Child(type: 'audio', title: '02.mp3', mediaDownloadUrl: 'u2');
      final files = Files(children: [a, b]);
      final context = PlaybackContext(work: work, files: files, currentFile: a);

      final text = LlmTranslationContextBuilder.build(context, targetLangCode: 'en');

      expect(text, contains('RJ999'));
      expect(text, contains('Test Work'));
      expect(text, contains('Test Circle'));
      expect(text, contains('01.mp3'));
      expect(text, contains('02.mp3'));
      expect(text, contains('adult/NSFW'));
    });
  });
}
