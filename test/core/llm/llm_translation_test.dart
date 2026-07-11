import 'package:flutter_test/flutter_test.dart';
import 'package:lizunemu/core/audio/models/playback_context.dart';
import 'package:lizunemu/core/audio/models/subtitle.dart';
import 'package:lizunemu/core/llm/llm_batch_planner.dart';
import 'package:lizunemu/core/llm/llm_translation_context_builder.dart';
import 'package:lizunemu/core/llm/llm_usage.dart';
import 'package:lizunemu/core/llm/streaming_translation_parser.dart';
import 'package:lizunemu/core/llm/subtitle_translation_completeness.dart';
import 'package:lizunemu/core/settings/llm_batch_split_mode.dart';
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

  group('StreamingTranslationParser', () {
    test('parses NDJSON incrementally across chunks', () {
      final parser = StreamingTranslationParser();
      final first = parser.feed('{"index":0,"text":"a"}\n');
      expect(first, hasLength(1));
      expect(first.first.key, 0);
      expect(first.first.value, 'a');

      final second = parser.feed('{"index":1,"text":"b"}\n');
      expect(second.single.key, 1);
      expect(second.single.value, 'b');
      expect(parser.flush(), isEmpty);
    });

    test('buffers partial line until newline', () {
      final parser = StreamingTranslationParser();
      expect(parser.feed('{"index":0,"text":"hel'), isEmpty);
      final done = parser.feed('lo"}\n');
      expect(done.single.value, 'hello');
    });

    test('flush parses trailing object without newline', () {
      final parser = StreamingTranslationParser();
      parser.feed('{"index":3,"text":"tail"}');
      final flushed = parser.flush();
      expect(flushed.single.key, 3);
      expect(flushed.single.value, 'tail');
    });
  });

  group('LlmBatchPlanner', () {
    final subs = List.generate(
      60,
      (i) => Subtitle(
        start: Duration(seconds: i),
        end: Duration(seconds: i + 1),
        text: 'line $i',
        index: i,
      ),
    );

    test('none mode returns single batch', () {
      final batches = LlmBatchPlanner.planBatches(
        subtitles: subs,
        mode: LlmBatchSplitMode.none,
        manualBatchSize: 25,
      );
      expect(batches, hasLength(1));
      expect(batches.first, hasLength(60));
    });

    test('manual mode respects batch size', () {
      final batches = LlmBatchPlanner.planBatches(
        subtitles: subs,
        mode: LlmBatchSplitMode.manual,
        manualBatchSize: 25,
      );
      expect(batches, hasLength(3));
      expect(batches[0], hasLength(25));
      expect(batches[2], hasLength(10));
    });

    test('provider mode estimates from context window', () {
      final longSubs = List.generate(
        200,
        (i) => Subtitle(
          start: Duration(seconds: i),
          end: Duration(seconds: i + 1),
          text: 'subtitle line number $i with extra words',
          index: i,
        ),
      );
      final batches = LlmBatchPlanner.planBatches(
        subtitles: longSubs,
        mode: LlmBatchSplitMode.provider,
        manualBatchSize: 25,
        providerContextTokens: 2000,
      );
      expect(batches.length, greaterThan(1));
    });

    test('provider mode does not hard-cap at 120 on large context', () {
      final longSubs = List.generate(
        400,
        (i) => Subtitle(
          start: Duration(seconds: i),
          end: Duration(seconds: i + 1),
          text: 'line $i',
          index: i,
        ),
      );
      final batches = LlmBatchPlanner.planBatches(
        subtitles: longSubs,
        mode: LlmBatchSplitMode.provider,
        manualBatchSize: 25,
        providerContextTokens: 128000,
      );
      expect(batches, hasLength(1));
      expect(batches.first, hasLength(400));
    });
  });

  group('LlmUsage', () {
    test('parses OpenRouter usage with cost', () {
      final usage = LlmUsage.fromJson({
        'prompt_tokens': 10,
        'completion_tokens': 20,
        'total_tokens': 30,
        'total_cost': 0.00042,
      });
      expect(usage?.totalTokens, 30);
      expect(usage?.totalCostUsd, closeTo(0.00042, 0.000001));
    });
  });

  group('SubtitleTranslationCompleteness', () {
    final source = SubtitleList([
      const Subtitle(
        start: Duration.zero,
        end: Duration(seconds: 1),
        text: 'A',
        index: 0,
      ),
      const Subtitle(
        start: Duration(seconds: 1),
        end: Duration(seconds: 2),
        text: 'B',
        index: 1,
      ),
    ]);

    test('pending excludes already translated lines', () {
      final lines = {0: 'α', 1: 'B'};
      expect(
        SubtitleTranslationCompleteness.pendingLines(source, lines),
        hasLength(1),
      );
      expect(
        SubtitleTranslationCompleteness.pendingLines(source, lines).first.index,
        1,
      );
    });

    test('isComplete requires every line translated', () {
      expect(
        SubtitleTranslationCompleteness.isComplete(source, {0: 'α', 1: 'β'}),
        isTrue,
      );
      expect(
        SubtitleTranslationCompleteness.isComplete(source, {0: 'α', 1: 'B'}),
        isFalse,
      );
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
