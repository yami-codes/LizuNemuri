import 'package:flutter_test/flutter_test.dart';
import 'package:lizunemu/core/lore/lore_json_utils.dart';
import 'package:lizunemu/core/lore/lore_pack_io.dart';
import 'package:lizunemu/core/lore/lore_state_projector.dart';
import 'package:lizunemu/core/lore/models/lore_character.dart';
import 'package:lizunemu/core/lore/models/lore_event.dart';
import 'package:lizunemu/core/lore/models/lore_ontology.dart';
import 'package:lizunemu/core/lore/models/lore_param.dart';
import 'package:lizunemu/core/lore/models/work_lore_pack.dart';
import 'package:lizunemu/core/lore/work_lore_service.dart';

void main() {
  group('LoreTimelineEvent.fromJson', () {
    test('accepts deltas as a list', () {
      final e = LoreTimelineEvent.fromJson({
        'id': 'e1',
        'trackKey': 't1',
        'title': 'x',
        'detail': 'y',
        'deltas': [
          {'key': 'arousal', 'from': 0, 'to': 10},
        ],
      });
      expect(e.deltas, hasLength(1));
      expect(e.deltas.first.key, 'arousal');
      expect(e.deltas.first.to, 10);
    });

    test('accepts deltas as a map (LLM shape)', () {
      final e = LoreTimelineEvent.fromJson({
        'id': 'e1',
        'trackKey': 't1',
        'title': 'x',
        'detail': 'y',
        'deltas': {
          'arousal': {'from': 0, 'to': 40},
          'wetness': 12,
        },
      });
      expect(e.deltas, hasLength(2));
      final byKey = {for (final d in e.deltas) d.key: d};
      expect(byKey['arousal']?.to, 40);
      expect(byKey['wetness']?.to, 12);
    });

    test('null or bad deltas become empty', () {
      final e = LoreTimelineEvent.fromJson({
        'id': 'e1',
        'trackKey': 't1',
        'deltas': 'nope',
      });
      expect(e.deltas, isEmpty);
    });
  });

  group('LoreJsonUtils', () {
    test('extracts JSON object from fenced LLM reply', () {
      const raw = 'Sure!\n```json\n{"a":1,"b":"x"}\n```\n';
      final map = LoreJsonUtils.parseObject(raw);
      expect(map?['a'], 1);
      expect(map?['b'], 'x');
    });

    test('trackKey prefers hash then url then title', () {
      expect(
        LoreJsonUtils.trackKeyFor(index: 0, hash: 'h1', title: 't'),
        'h1',
      );
      expect(
        LoreJsonUtils.trackKeyFor(
          index: 1,
          mediaDownloadUrl: 'https://x/a',
          title: 't',
        ),
        'https://x/a',
      );
      expect(
        LoreJsonUtils.trackKeyFor(index: 2, title: 'Intro'),
        'idx:2:Intro',
      );
    });
  });

  group('LoreStateProjector', () {
    late WorkLorePack pack;

    setUp(() {
      pack = WorkLorePack(
        workId: '1',
        synopsis: 'story',
        characters: [
          LoreCharacter(
            id: 'c1',
            name: 'Aoi',
            isFocusDefault: true,
            params: const [
              LoreParam(
                key: 'arousal',
                module: 'psyche',
                label: 'Arousal',
                type: LoreParamType.gauge,
                value: 10,
                hudPinned: true,
              ),
            ],
          ),
        ],
        events: const [
          LoreTimelineEvent(
            id: 'e1',
            trackKey: 't1',
            atMs: 5000,
            kind: LoreEventKind.paramChange,
            title: 'Rising',
            characterId: 'c1',
            deltas: [
              LoreParamDelta(key: 'arousal', from: 10, to: 40),
            ],
          ),
          LoreTimelineEvent(
            id: 'e2',
            trackKey: 't1',
            atMs: 15000,
            kind: LoreEventKind.paramChange,
            title: 'Peak',
            characterId: 'c1',
            deltas: [
              LoreParamDelta(key: 'arousal', from: 40, to: 80),
            ],
          ),
        ],
        updatedAt: DateTime.utc(2026, 1, 1),
        loreHash: 'x',
      );
    });

    test('projects forward and backward from event log', () {
      // Explicit endMs so lerp settles before next cue.
      pack = WorkLorePack(
        workId: '1',
        synopsis: 'story',
        characters: [
          LoreCharacter(
            id: 'c1',
            name: 'Aoi',
            isFocusDefault: true,
            params: const [
              LoreParam(
                key: 'arousal',
                module: 'psyche',
                label: 'Arousal',
                type: LoreParamType.gauge,
                value: 10,
                hudPinned: true,
              ),
            ],
          ),
        ],
        events: const [
          LoreTimelineEvent(
            id: 'e1',
            trackKey: 't1',
            atMs: 5000,
            endMs: 6000,
            kind: LoreEventKind.paramChange,
            title: 'Rising',
            characterId: 'c1',
            deltas: [
              LoreParamDelta(key: 'arousal', from: 10, to: 40),
            ],
          ),
          LoreTimelineEvent(
            id: 'e2',
            trackKey: 't1',
            atMs: 15000,
            endMs: 16000,
            kind: LoreEventKind.paramChange,
            title: 'Peak',
            characterId: 'c1',
            deltas: [
              LoreParamDelta(key: 'arousal', from: 40, to: 80),
            ],
          ),
        ],
        updatedAt: DateTime.utc(2026, 1, 1),
        loreHash: 'x',
      );

      final mid = LoreStateProjector.project(
        pack: pack,
        trackKey: 't1',
        positionMs: 6000,
      );
      expect(mid.projectedParams.first.gaugeValue, 40);
      expect(mid.revealedEvents.length, 1);

      final late = LoreStateProjector.project(
        pack: pack,
        trackKey: 't1',
        positionMs: 20000,
      );
      expect(late.projectedParams.first.gaugeValue, 80);
      expect(late.revealedEvents.length, 2);

      final early = LoreStateProjector.project(
        pack: pack,
        trackKey: 't1',
        positionMs: 0,
      );
      expect(early.projectedParams.first.gaugeValue, 10);
      expect(early.revealedEvents, isEmpty);
    });

    test('interpolates numeric deltas across a span block', () {
      final block = WorkLorePack(
        workId: '1',
        synopsis: 's',
        characters: [
          LoreCharacter(
            id: 'c1',
            name: 'Aoi',
            isFocusDefault: true,
            params: const [
              LoreParam(
                key: 'arousal',
                module: 'psyche',
                label: 'Arousal',
                type: LoreParamType.gauge,
                value: 0,
                hudPinned: true,
              ),
            ],
          ),
        ],
        events: const [
          LoreTimelineEvent(
            id: 'e1',
            trackKey: 't1',
            atMs: 0,
            endMs: 10000,
            kind: LoreEventKind.paramChange,
            title: 'Ramp',
            characterId: 'c1',
            deltas: [LoreParamDelta(key: 'arousal', from: 0, to: 100)],
          ),
        ],
        updatedAt: DateTime.utc(2026, 1, 1),
        loreHash: 'x',
      );

      final mid = LoreStateProjector.project(
        pack: block,
        trackKey: 't1',
        positionMs: 5000,
      );
      expect(mid.projectedParams.first.gaugeValue, closeTo(50, 0.01));
      expect(mid.activeSpans, isNotEmpty);
      expect(mid.trackSpans.single.startMs, 0);
      expect(mid.trackSpans.single.endMs, 10000);
    });

    test('pulses discrete status snaps near settle time', () {
      final packStatus = WorkLorePack(
        workId: '1',
        synopsis: 's',
        characters: [
          LoreCharacter(
            id: 'c1',
            name: 'Aoi',
            isFocusDefault: true,
            params: const [
              LoreParam(
                key: 'clothing_state',
                module: 'clothing',
                label: 'Clothing',
                type: LoreParamType.enumeration,
                value: 'dressed',
                hudPinned: true,
              ),
            ],
          ),
        ],
        events: const [
          LoreTimelineEvent(
            id: 'e1',
            trackKey: 't1',
            atMs: 1000,
            endMs: 3000,
            kind: LoreEventKind.clothing,
            title: 'Undress',
            characterId: 'c1',
            deltas: [
              LoreParamDelta(
                key: 'clothing_state',
                from: 'dressed',
                to: 'half',
              ),
            ],
          ),
        ],
        updatedAt: DateTime.utc(2026, 1, 1),
        loreHash: 'x',
      );

      final during = LoreStateProjector.project(
        pack: packStatus,
        trackKey: 't1',
        positionMs: 2000,
      );
      expect(during.projectedParams.first.value, 'dressed');
      expect(during.activeSpans, isNotEmpty);

      final after = LoreStateProjector.project(
        pack: packStatus,
        trackKey: 't1',
        positionMs: 3100,
      );
      expect(after.projectedParams.first.value, 'half');
      expect(after.changePulses, isNotEmpty);
      expect(after.changePulses.first.key, 'clothing_state');
    });

    test('carries prior-track end state into later track at t=0', () {
      final multi = WorkLorePack(
        workId: '1',
        synopsis: 'story',
        characters: [
          LoreCharacter(
            id: 'c1',
            name: 'Aoi',
            isFocusDefault: true,
            params: const [
              LoreParam(
                key: 'arousal',
                module: 'psyche',
                label: 'Arousal',
                type: LoreParamType.gauge,
                value: 0,
                hudPinned: true,
              ),
            ],
          ),
        ],
        trackSummaries: const [
          LoreTrackSummary(
            trackKey: 't1',
            trackTitle: '01.intro.mp3',
            trackIndex: 0,
            summary: 'a',
          ),
          LoreTrackSummary(
            trackKey: 't2',
            trackTitle: '02.next.mp3',
            trackIndex: 1,
            summary: 'b',
          ),
        ],
        events: const [
          LoreTimelineEvent(
            id: 'e1',
            trackKey: 't1',
            atMs: 1000,
            kind: LoreEventKind.paramChange,
            title: 'Rise',
            characterId: 'c1',
            deltas: [LoreParamDelta(key: 'arousal', from: 0, to: 40)],
          ),
          LoreTimelineEvent(
            id: 'e2',
            trackKey: 't2',
            atMs: 5000,
            endMs: 5500,
            kind: LoreEventKind.paramChange,
            title: 'Higher',
            characterId: 'c1',
            deltas: [LoreParamDelta(key: 'arousal', from: 40, to: 70)],
          ),
        ],
        updatedAt: DateTime.utc(2026, 1, 1),
        loreHash: 'x',
      );

      final atTrack2Start = LoreStateProjector.project(
        pack: multi,
        trackKey: 't2',
        positionMs: 0,
      );
      expect(atTrack2Start.projectedParams.first.gaugeValue, 40);

      final midTrack2 = LoreStateProjector.project(
        pack: multi,
        trackKey: 't2',
        positionMs: 6000,
      );
      expect(midTrack2.projectedParams.first.gaugeValue, 70);
    });

    test('resolves no-SFX alt hash to lore track by normalized title', () {
      final multi = WorkLorePack(
        workId: '1',
        synopsis: 'story',
        characters: [
          LoreCharacter(
            id: 'c1',
            name: 'Aoi',
            isFocusDefault: true,
            params: const [
              LoreParam(
                key: 'arousal',
                module: 'psyche',
                label: 'Arousal',
                type: LoreParamType.gauge,
                value: 0,
                hudPinned: true,
              ),
            ],
          ),
        ],
        trackSummaries: const [
          LoreTrackSummary(
            trackKey: 'hash/main',
            trackTitle: '01.心跳加速的初次见面！面试的时间.mp3',
            trackIndex: 0,
            summary: 'a',
          ),
          LoreTrackSummary(
            trackKey: 'hash/nosfx',
            trackTitle: '01.心跳加速的初次见面！面试的时间（无效果音）.mp3',
            trackIndex: 10,
            summary: 'thin',
            lowConfidence: true,
          ),
        ],
        events: const [
          LoreTimelineEvent(
            id: 'e1',
            trackKey: 'hash/main',
            atMs: 2000,
            kind: LoreEventKind.paramChange,
            title: 'Rise',
            characterId: 'c1',
            deltas: [LoreParamDelta(key: 'arousal', from: 0, to: 25)],
          ),
        ],
        updatedAt: DateTime.utc(2026, 1, 1),
        loreHash: 'x',
      );

      final snap = LoreStateProjector.project(
        pack: multi,
        trackKey: 'hash/nosfx',
        trackTitle: '01.心跳加速的初次见面！面试的时间（无效果音）.mp3',
        positionMs: 5000,
      );
      expect(snap.projectedParams.first.gaugeValue, 25);
      expect(
        LoreStateProjector.normalizeTrackTitle(
          '01.心跳加速的初次见面！面试的时间（无效果音）.mp3',
        ),
        LoreStateProjector.normalizeTrackTitle(
          '01.心跳加速的初次见面！面试的时间.mp3',
        ),
      );
    });

    test('trackParamArcs summarizes per-track from→to for a character', () {
      final pack = WorkLorePack(
        workId: '1',
        synopsis: 's',
        characters: [
          LoreCharacter(
            id: 'c1',
            name: 'Aoi',
            isFocusDefault: true,
            params: const [
              LoreParam(
                key: 'arousal',
                module: 'psyche',
                label: 'Arousal',
                type: LoreParamType.gauge,
                value: 0,
              ),
              LoreParam(
                key: 'affection',
                module: 'psyche',
                label: 'Affection',
                type: LoreParamType.gauge,
                value: 0,
              ),
            ],
          ),
        ],
        trackSummaries: const [
          LoreTrackSummary(
            trackKey: 't1',
            trackTitle: '01.intro',
            trackIndex: 0,
            summary: 'a',
          ),
          LoreTrackSummary(
            trackKey: 't2',
            trackTitle: '02.next',
            trackIndex: 1,
            summary: 'b',
          ),
        ],
        events: const [
          LoreTimelineEvent(
            id: 'e1',
            trackKey: 't1',
            atMs: 1000,
            kind: LoreEventKind.paramChange,
            title: 'a',
            characterId: 'c1',
            deltas: [LoreParamDelta(key: 'arousal', from: 0, to: 20)],
          ),
          LoreTimelineEvent(
            id: 'e2',
            trackKey: 't1',
            atMs: 5000,
            kind: LoreEventKind.paramChange,
            title: 'b',
            characterId: 'c1',
            deltas: [
              LoreParamDelta(key: 'arousal', from: 20, to: 40),
              LoreParamDelta(key: 'affection', from: 0, to: 10),
            ],
          ),
          LoreTimelineEvent(
            id: 'e3',
            trackKey: 't2',
            atMs: 1000,
            kind: LoreEventKind.paramChange,
            title: 'c',
            characterId: 'c1',
            deltas: [LoreParamDelta(key: 'arousal', from: 40, to: 70)],
          ),
        ],
        updatedAt: DateTime.utc(2026, 1, 1),
        loreHash: 'x',
      );

      final arcs = LoreStateProjector.trackParamArcs(
        pack: pack,
        characterId: 'c1',
      );
      expect(arcs.length, 2);
      expect(arcs.first.trackKey, 't1');
      final t1 = {for (final d in arcs.first.deltas) d.key: d};
      expect(t1['arousal']!.from, 0);
      expect(t1['arousal']!.to, 40);
      expect(t1['affection']!.to, 10);
      expect(arcs.last.deltas.single.to, 70);
    });

    test('seedSpeculativeBaselines adds explicit ontology keys', () {
      final seeded = WorkLoreService.seedSpeculativeBaselinesForTest([
        const LoreCharacter(
          id: 'c1',
          name: 'Aoi',
          params: [
            LoreParam(
              key: 'arousal',
              module: 'psyche',
              label: 'Arousal',
              type: LoreParamType.gauge,
              value: 0,
            ),
          ],
        ),
      ]);
      final keys = seeded.single.params.map((p) => p.key).toSet();
      expect(keys.contains('arousal'), isTrue);
      expect(keys.contains('wetness'), isTrue);
      expect(keys.contains('hymen'), isTrue);
      final wet = seeded.single.params.firstWhere((p) => p.key == 'wetness');
      expect(wet.speculative, isTrue);
    });
  });

  group('LorePackIo', () {
    test('round-trips pack JSON with schema_version', () {
      final pack = WorkLorePack(
        workId: '42',
        sourceId: 'RJ123',
        synopsis: 'hello',
        characters: const [
          LoreCharacter(id: 'c1', name: 'Aoi'),
        ],
        updatedAt: DateTime.utc(2026, 7, 11),
        loreHash: '',
      ).withRecomputedHash();

      final json = LorePackIo.exportPackJson(pack);
      final imported = LorePackIo.importPackJson(json);
      expect(imported.workId, '42');
      expect(imported.synopsis, 'hello');
      expect(imported.characters.single.name, 'Aoi');
      expect(imported.loreHash, isNotEmpty);
    });

    test('batch zip round-trip', () {
      final packs = [
        WorkLorePack(
          workId: '1',
          synopsis: 'a',
          updatedAt: DateTime.utc(2026, 1, 1),
          loreHash: '',
        ).withRecomputedHash(),
        WorkLorePack(
          workId: '2',
          synopsis: 'b',
          updatedAt: DateTime.utc(2026, 1, 2),
          loreHash: '',
        ).withRecomputedHash(),
      ];
      final zip = LorePackIo.exportBatchZip(packs);
      final back = LorePackIo.importBatchZip(zip);
      expect(back.length, 2);
      expect(back.map((p) => p.workId).toSet(), {'1', '2'});
    });
  });

  group('LoreOntology', () {
    test('v3 starter params include expanded body/fluids/psyche set', () {
      final keys =
          LoreOntology.starterParams().map((p) => p.key).toSet();
      expect(LoreOntology.version, 3);
      expect(LoreOntology.explicitModules, containsAll([
        LoreOntology.moduleFace,
        LoreOntology.moduleRisk,
        LoreOntology.moduleToys,
      ]));
      for (final key in [
        // prior set
        'hymen',
        'horny',
        'womb_ml',
        'pussy_ml',
        'sperm_in_pussy_ml',
        'sperm_in_womb_ml',
        'sperm_in_womb_million',
        'ovulation',
        'egg_quality',
        'menstruation_cycles',
        'cycle_day',
        'cervical_position',
        'cervical_mucus_ml',
        'panties',
        'scent_pussy',
        'scent_panties',
        'pregnancy_chance',
        'pregnancy_detail',
        'masturbation_week',
        'masturbation_lifetime',
        'sex_lifetime',
        // v3 expansion
        'breast_sensitivity',
        'nipple_state',
        'clit_sensitivity',
        'clit_state',
        'labia_state',
        'ass_tightness',
        'throat_training',
        'gape_vaginal',
        'gape_anal',
        'belly_state',
        'body_temperature',
        'sweat',
        'face_state',
        'hair_state',
        'voice_moan_level',
        'breathing',
        'pussy_juice_ml',
        'anal_cum_ml',
        'oral_cum_ml',
        'creampie_freshness',
        'squirt_count_session',
        'squirt_count_lifetime',
        'squirt_volume_session_ml',
        'breast_milk_ml',
        'lubricant_ml',
        'lubricant_type',
        'bladder_urgency',
        'bowel_urgency',
        'stain_thighs_sheets',
        'fertile_window',
        'fertile_hours_left',
        'implantation_chance',
        'contraception',
        'contraception_reliability',
        'pregnancy_weeks',
        'trimester',
        'morning_sickness',
        'sperm_motility',
        'last_creampie_ago',
        'breeding_urge',
        'bra_state',
        'skirt_hiked',
        'exposure_level',
        'cum_on_clothes',
        'ruined_clothing',
        'accessories',
        'toy_in_use',
        'shame',
        'pleasure',
        'pain',
        'fear',
        'trust',
        'obedience',
        'resistance',
        'climax_count_session',
        'climax_count_track',
        'climax_count_lifetime',
        'orgasm_denied',
        'orgasm_denied_count',
        'aftercare_need',
        'corruption_stage',
        'oral_given_lifetime',
        'oral_received_lifetime',
        'anal_sex_lifetime',
        'creampie_count_lifetime',
        'creampie_count_today',
        'partners_count',
        'public_play_count',
        'toy_use_lifetime',
      ]) {
        expect(keys, contains(key), reason: 'missing $key');
      }
      expect(keys.length, greaterThanOrEqualTo(80));
    });
  });
}
