import 'package:flutter_test/flutter_test.dart';
import 'package:lizunemu/core/lore/lore_json_utils.dart';
import 'package:lizunemu/core/lore/lore_pack_io.dart';
import 'package:lizunemu/core/lore/lore_state_projector.dart';
import 'package:lizunemu/core/lore/models/lore_character.dart';
import 'package:lizunemu/core/lore/models/lore_event.dart';
import 'package:lizunemu/core/lore/models/lore_ontology.dart';
import 'package:lizunemu/core/lore/models/lore_param.dart';
import 'package:lizunemu/core/lore/models/work_lore_pack.dart';

void main() {
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
