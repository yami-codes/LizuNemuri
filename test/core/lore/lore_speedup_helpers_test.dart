import 'package:flutter_test/flutter_test.dart';
import 'package:lizunemu/core/lore/lore_llm_pacer.dart';
import 'package:lizunemu/core/lore/lore_track_context_brief.dart';
import 'package:lizunemu/core/lore/models/lore_event.dart';
import 'package:lizunemu/core/lore/models/work_lore_pack.dart';

void main() {
  group('LoreLlmPacer', () {
    test('default pace is 0 — beforeNextCall is immediate', () async {
      final p = LoreLlmPacer();
      final sw = Stopwatch()..start();
      await p.beforeNextCall();
      p.markCallEnded();
      await p.beforeNextCall();
      sw.stop();
      expect(sw.elapsedMilliseconds, lessThan(50));
      expect(p.paceMs, 0);
    });

    test('cooloff waits after rate limit note', () async {
      final p = LoreLlmPacer();
      p.noteRateLimited(seconds: 1);
      final sw = Stopwatch()..start();
      await p.beforeNextCall();
      sw.stop();
      expect(sw.elapsedMilliseconds, greaterThanOrEqualTo(900));
    });
  });

  group('LoreTrackContextBrief', () {
    test('clips synopsis and slim carry', () {
      final brief = LoreTrackContextBrief.build(
        synopsis: 'A' * 500,
        completedSummaries: [
          LoreTrackSummary(
            trackKey: 't1',
            trackTitle: 'EP1',
            trackIndex: 0,
            summary: 'B' * 600,
          ),
        ],
        completedEvents: [
          LoreTimelineEvent(
            id: 'e1',
            trackKey: 't1',
            atMs: 0,
            kind: LoreEventKind.beat,
            title: 'Hello',
            speculative: false,
          ),
        ],
        carryState: {
          'c1': {'arousal': 10, 'empty': '', 'x': null},
        },
      );
      expect(brief.contains('Synopsis:'), isTrue);
      expect(brief.length, lessThan(500 + 500 + 200));
      expect(brief.contains('arousal'), isTrue);
      expect(brief.contains('empty'), isFalse);
    });

    test('shouldReconcile skips mono simple works', () {
      expect(
        LoreTrackContextBrief.shouldReconcile(
          characterCount: 1,
          summaries: [
            LoreTrackSummary(
              trackKey: 't',
              trackTitle: 't',
              trackIndex: 0,
              summary: 'ok',
              lowConfidence: false,
            ),
          ],
          seedNotes: const [],
        ),
        isFalse,
      );
    });

    test('shouldReconcile fires for ensemble / lowConfidence / seeds', () {
      expect(
        LoreTrackContextBrief.shouldReconcile(
          characterCount: 3,
          summaries: const [],
          seedNotes: const [],
        ),
        isTrue,
      );
      expect(
        LoreTrackContextBrief.shouldReconcile(
          characterCount: 1,
          summaries: [
            LoreTrackSummary(
              trackKey: 't',
              trackTitle: 't',
              trackIndex: 0,
              summary: '',
              lowConfidence: true,
            ),
          ],
          seedNotes: const [],
        ),
        isTrue,
      );
      expect(
        LoreTrackContextBrief.shouldReconcile(
          characterCount: 1,
          summaries: const [],
          seedNotes: [
            LoreSeedNote(id: 's', scope: LoreSeedScope.work, content: 'note'),
          ],
        ),
        isTrue,
      );
    });

    test('settleCarryFromEvents applies prior deltas', () {
      final carry = LoreTrackContextBrief.settleCarryFromEvents(
        baselines: {
          'c1': {'arousal': 0},
        },
        events: [
          LoreTimelineEvent(
            id: 'e1',
            trackKey: 't1',
            atMs: 0,
            kind: LoreEventKind.paramChange,
            title: 'up',
            characterId: 'c1',
            deltas: [
              LoreParamDelta(key: 'arousal', from: 0, to: 40),
            ],
          ),
        ],
        priorTrackKeys: {'t1'},
      );
      expect(carry['c1']?['arousal'], 40);
    });
  });
}
