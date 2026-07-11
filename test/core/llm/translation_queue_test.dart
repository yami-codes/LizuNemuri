import 'package:flutter_test/flutter_test.dart';
import 'package:lizunemu/core/llm/llm_request_gate.dart';
import 'package:lizunemu/core/llm/translation_queue_models.dart';
import 'package:lizunemu/core/llm/translation_queue_store.dart';
import 'package:lizunemu/data/models/files/child.dart';
import 'package:lizunemu/data/models/files/files.dart';
import 'package:lizunemu/data/models/works/work.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LlmRequestGate', () {
    test('limits concurrent runners to maxConcurrent', () async {
      final gate = LlmRequestGate(maxConcurrent: 2);
      var active = 0;
      var peak = 0;

      Future<void> job() => gate.run(() async {
            active++;
            if (active > peak) peak = active;
            await Future<void>.delayed(const Duration(milliseconds: 30));
            active--;
          });

      await Future.wait([job(), job(), job(), job()]);
      expect(peak, 2);
      expect(gate.activeCount, 0);
      expect(gate.waitingCount, 0);
    });
  });

  group('TranslationQueueStore', () {
    test('round-trips jobs and restores running as pending', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = TranslationQueueStore(prefs);

      final job = TranslationQueueJob(
        id: 'job1',
        work: Work(id: 1, title: 'Test Work'),
        files: Files(
          type: 'folder',
          children: [
            Child(type: 'audio', title: 'a.mp3', hash: 'h1'),
            Child(type: 'text', title: 'a.vtt', hash: 'h2'),
          ],
        ),
        tracks: [
          TranslationQueueTrack(
            id: 't1',
            audio: Child(type: 'audio', title: 'a.mp3', hash: 'h1'),
            subtitle: Child(type: 'text', title: 'a.vtt', hash: 'h2'),
            status: TranslationQueueTrackStatus.running,
            attempts: 2,
          ),
          TranslationQueueTrack(
            id: 't2',
            audio: Child(type: 'audio', title: 'b.mp3', hash: 'h3'),
            subtitle: Child(type: 'text', title: 'b.vtt', hash: 'h4'),
            status: TranslationQueueTrackStatus.done,
          ),
        ],
      );

      await store.save([job]);
      final loaded = store.load();
      expect(loaded, hasLength(1));
      expect(loaded.first.workTitle, 'Test Work');
      expect(loaded.first.tracks[0].status, TranslationQueueTrackStatus.pending);
      expect(loaded.first.tracks[0].attempts, 2);
      expect(loaded.first.tracks[1].status, TranslationQueueTrackStatus.done);
    });
  });
}
