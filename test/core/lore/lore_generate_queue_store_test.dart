import 'package:flutter_test/flutter_test.dart';
import 'package:lizunemu/core/lore/lore_generate_queue_models.dart';
import 'package:lizunemu/core/lore/lore_generate_queue_store.dart';
import 'package:lizunemu/data/models/files/child.dart';
import 'package:lizunemu/data/models/works/work.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('LoreGenerateQueueStore round-trip remaps running→pending', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LoreGenerateQueueStore(prefs);

    final job = LoreGenerateQueueJob(
      id: 'j1',
      work: Work(id: 9, title: 'RJ'),
      pairs: [
        (
          audio: Child(type: 'audio', title: 'a.mp3', hash: 'h1'),
          subtitle: Child(type: 'text', title: 'a.vtt', hash: 'h2'),
        ),
      ],
      kind: LoreGenerateKind.fullGenerate,
      status: LoreGenerateQueueJobStatus.running,
      progress: 0.4,
      progressStage: 'track:h1',
      attempts: 1,
    );

    await store.save([job]);
    final loaded = store.load();
    expect(loaded, hasLength(1));
    expect(loaded.first.status, LoreGenerateQueueJobStatus.pending);
    expect(loaded.first.workTitle, 'RJ');
    expect(loaded.first.pairs, hasLength(1));
    expect(loaded.first.attempts, 1);
  });
}
