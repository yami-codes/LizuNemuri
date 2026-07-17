import 'package:flutter_test/flutter_test.dart';
import 'package:lizunemu/core/lore/lore_resume.dart';
import 'package:lizunemu/core/lore/models/lore_character.dart';
import 'package:lizunemu/core/lore/models/lore_event.dart';
import 'package:lizunemu/core/lore/models/work_lore_pack.dart';

void main() {
  group('loreTrackSummaryIsComplete', () {
    test('null is incomplete', () {
      expect(loreTrackSummaryIsComplete(null), isFalse);
    });

    test('empty + lowConfidence is incomplete soft stub', () {
      expect(
        loreTrackSummaryIsComplete(
          const LoreTrackSummary(
            trackKey: 't0',
            trackTitle: 'A',
            trackIndex: 0,
            summary: '',
            lowConfidence: true,
          ),
        ),
        isFalse,
      );
    });

    test('non-empty summary is complete even if lowConfidence', () {
      expect(
        loreTrackSummaryIsComplete(
          const LoreTrackSummary(
            trackKey: 't0',
            trackTitle: 'A',
            trackIndex: 0,
            summary: 'thin metadata',
            lowConfidence: true,
          ),
        ),
        isTrue,
      );
    });

    test('empty without lowConfidence is complete', () {
      // Unusual but not the soft-fail stub shape.
      expect(
        loreTrackSummaryIsComplete(
          const LoreTrackSummary(
            trackKey: 't0',
            trackTitle: 'A',
            trackIndex: 0,
            summary: '   ',
            lowConfidence: false,
          ),
        ),
        isTrue,
      );
    });
  });

  group('lore resume skip helpers', () {
    late WorkLorePack pack;

    setUp(() {
      pack = WorkLorePack(
        workId: 'w1',
        synopsis: 'story',
        characters: const [LoreCharacter(id: 'c1', name: 'Aoi')],
        trackSummaries: const [
          LoreTrackSummary(
            trackKey: 't0',
            trackTitle: 'EP1',
            trackIndex: 0,
            summary: 'done',
          ),
          LoreTrackSummary(
            trackKey: 't1',
            trackTitle: 'EP2',
            trackIndex: 1,
            summary: '',
            lowConfidence: true,
          ),
        ],
        events: [
          LoreTimelineEvent(
            id: 'e1',
            trackKey: 't0',
            atMs: 0,
            kind: LoreEventKind.beat,
            title: 'Open',
            detail: '',
          ),
          LoreTimelineEvent(
            id: 'e2',
            trackKey: 't1',
            atMs: 0,
            kind: LoreEventKind.beat,
            title: 'Stub',
            detail: '',
          ),
        ],
        updatedAt: DateTime.utc(2026, 7, 18),
        loreHash: 'x',
      );
    });

    test('has reusable cast when characters present', () {
      expect(lorePackHasReusableCast(pack), isTrue);
      expect(lorePackHasReusableCast(null), isFalse);
      expect(
        lorePackHasReusableCast(
          WorkLorePack(
            workId: 'w',
            updatedAt: DateTime.utc(2026, 7, 18),
            loreHash: '',
          ),
        ),
        isFalse,
      );
    });

    test('skip only complete track keys in order', () {
      expect(
        loreResumeSkipTrackKeys(pack, ['t0', 't1', 't2']),
        ['t0'],
      );
    });

    test('seed summaries keep complete only in input order', () {
      final seeded = loreResumeSeedSummaries(pack, ['t0', 't1', 't2']);
      expect(seeded, hasLength(1));
      expect(seeded.first.trackKey, 't0');
    });

    test('seed events keep only skip-key events', () {
      final events = loreResumeSeedEvents(pack, {'t0'});
      expect(events, hasLength(1));
      expect(events.first.id, 'e1');
    });

    test('prior keys after skip include completed track for carry continuity', () {
      final ordered = ['t0', 't1', 't2'];
      final skip = loreResumeSkipTrackKeys(pack, ordered).toSet();
      final summaries = loreResumeSeedSummaries(pack, ordered);
      expect(skip, {'t0'});
      expect({for (final s in summaries) s.trackKey}, {'t0'});
      // Track t1 would settle carry with priorKeys == {t0}.
      expect(summaries.map((s) => s.trackKey).toSet(), contains('t0'));
    });
  });
}
