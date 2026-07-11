import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:lizunemu/core/lore/lore_json_utils.dart';
import 'package:lizunemu/core/lore/models/lore_character.dart';
import 'package:lizunemu/core/lore/models/lore_ontology.dart';
import 'package:lizunemu/core/lore/models/work_lore_pack.dart';
import 'package:lizunemu/core/lore/storage/ccv2_card_cache_repository.dart';
import 'package:lizunemu/core/settings/llm_model_slot.dart';
import 'package:lizunemu/data/services/llm_client.dart';

/// Character Card V2 export via LLM rewrite + cache.
class Ccv2ExportService {
  final LlmClient _llm;
  final Ccv2CardCacheRepository _cache;

  Ccv2ExportService({
    required LlmClient llm,
    required Ccv2CardCacheRepository cache,
  })  : _llm = llm,
        _cache = cache;

  static String cacheKeyForWorkCharacter(String workId, String characterId) =>
      '$workId:$characterId';

  Future<Map<String, dynamic>> exportCharacterCard({
    required WorkLorePack pack,
    required LoreCharacter character,
    bool includeSpeculative = false,
    bool forceRewrite = false,
  }) async {
    final key = cacheKeyForWorkCharacter(pack.workId, character.id);
    if (!forceRewrite) {
      final cached = await _cache.getValidCardJson(key, pack.loreHash);
      if (cached != null) {
        return Map<String, dynamic>.from(jsonDecode(cached) as Map);
      }
    }

    final card = await _rewriteCard(
      pack: pack,
      character: character,
      includeSpeculative: includeSpeculative,
    );
    await _cache.upsert(
      cacheKey: key,
      loreHash: pack.loreHash,
      cardJson: jsonEncode(card),
    );
    return card;
  }

  Future<String> exportCharacterCardJson({
    required WorkLorePack pack,
    required LoreCharacter character,
    bool includeSpeculative = false,
    bool forceRewrite = false,
    bool pretty = true,
  }) async {
    final card = await exportCharacterCard(
      pack: pack,
      character: character,
      includeSpeculative: includeSpeculative,
      forceRewrite: forceRewrite,
    );
    return pretty
        ? const JsonEncoder.withIndent('  ').convert(card)
        : jsonEncode(card);
  }

  Future<Uint8List> exportBatchZip({
    required WorkLorePack pack,
    bool includeSpeculative = false,
    bool forceRewrite = false,
  }) async {
    final archive = Archive();
    for (final character in pack.characters) {
      final json = await exportCharacterCardJson(
        pack: pack,
        character: character,
        includeSpeculative: includeSpeculative,
        forceRewrite: forceRewrite,
      );
      final bytes = utf8.encode(json);
      final name =
          '${_safe(character.name.isEmpty ? character.id : character.name)}.json';
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    }
    return Uint8List.fromList(ZipEncoder().encode(archive)!);
  }

  Future<Map<String, dynamic>> _rewriteCard({
    required WorkLorePack pack,
    required LoreCharacter character,
    required bool includeSpeculative,
  }) async {
    final filtered = includeSpeculative
        ? character
        : character.copyWith(
            params: character.params.where((p) => !p.speculative).toList(),
          );

    final lang = pack.languageCode ?? 'en';
    final user = '''
Rewrite this ASMR work character into a SillyTavern Character Card V2 JSON.
Do NOT dump raw gauge numbers as the description — write vivid prose character card fields.
Keep structured truth in data.extensions.lizunemu.

Return ONLY JSON:
{
  "spec": "chara_card_v2",
  "spec_version": "2.0",
  "data": {
    "name": "...",
    "description": "...",
    "personality": "...",
    "scenario": "...",
    "first_mes": "...",
    "mes_example": "",
    "creator_notes": "...",
    "system_prompt": "",
    "post_history_instructions": "",
    "tags": ["asmr","..."],
    "creator": "Lizunemu",
    "character_version": "1.0",
    "alternate_greetings": [],
    "extensions": {
      "lizunemu": {
        "workId": "...",
        "characterId": "...",
        "loreHash": "...",
        "params": [],
        "kinks": []
      }
    }
  }
}
Language: $lang
Work title: ${pack.workTitle}
Synopsis: ${pack.synopsis}
Character JSON: ${jsonEncode(filtered.toJson())}
''';

    final raw = await _llm.chatCompletion(
      messages: [
        {
          'role': 'system',
          'content':
              'You export Character Card V2 JSON only. No markdown fences.',
        },
        {'role': 'user', 'content': user},
      ],
      temperature: 0.4,
      modelSlot: LlmModelSlot.main,
    );

    final parsed = LoreJsonUtils.parseObject(raw);
    if (parsed != null && parsed['spec'] == 'chara_card_v2') {
      return _ensureLizunemuExtension(parsed, pack, filtered);
    }
    return _fallbackCard(pack, filtered);
  }

  Map<String, dynamic> _ensureLizunemuExtension(
    Map<String, dynamic> card,
    WorkLorePack pack,
    LoreCharacter character,
  ) {
    final data = Map<String, dynamic>.from(
      (card['data'] as Map?) ?? const {},
    );
    final extensions = Map<String, dynamic>.from(
      (data['extensions'] as Map?) ?? const {},
    );
    extensions['lizunemu'] = {
      'workId': pack.workId,
      'characterId': character.id,
      'loreHash': pack.loreHash,
      'ontologyVersion': LoreOntology.version,
      'params': character.params.map((e) => e.toJson()).toList(),
      'kinks': character.kinks.map((e) => e.toJson()).toList(),
      'appearance': character.appearance,
      'personality': character.personality,
    };
    data['extensions'] = extensions;
    data['name'] ??= character.name;
    data['creator'] ??= 'Lizunemu';
    return {
      'spec': 'chara_card_v2',
      'spec_version': card['spec_version'] ?? '2.0',
      'data': data,
    };
  }

  Map<String, dynamic> _fallbackCard(
    WorkLorePack pack,
    LoreCharacter character,
  ) {
    final desc = [
      if (character.appearance != null) character.appearance,
      if (character.personality != null) character.personality,
      if (character.relationshipToListener != null)
        'Relationship to listener: ${character.relationshipToListener}',
      if (pack.synopsis.isNotEmpty) 'Work context: ${pack.synopsis}',
    ].whereType<String>().join('\n\n');

    return _ensureLizunemuExtension(
      {
        'spec': 'chara_card_v2',
        'spec_version': '2.0',
        'data': {
          'name': character.name,
          'description': desc,
          'personality': character.personality ?? '',
          'scenario': pack.synopsis,
          'first_mes': '',
          'mes_example': '',
          'creator_notes': 'Exported from Lizunemu Work Lore',
          'system_prompt': '',
          'post_history_instructions': '',
          'tags': const ['asmr', 'lizunemu'],
          'creator': 'Lizunemu',
          'character_version': '1.0',
          'alternate_greetings': const [],
          'extensions': const {},
        },
      },
      pack,
      character,
    );
  }

  static String _safe(String raw) =>
      raw.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
}
