import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:lizunemu/core/lore/lore_json_utils.dart';
import 'package:lizunemu/core/lore/models/lore_character.dart';
import 'package:lizunemu/core/lore/models/lore_content_level.dart';
import 'package:lizunemu/core/lore/models/lore_event.dart';
import 'package:lizunemu/core/lore/models/lore_ontology.dart';
import 'package:lizunemu/core/lore/models/lore_param.dart';
import 'package:lizunemu/core/lore/models/work_lore_pack.dart';
import 'package:lizunemu/core/lore/storage/ccv2_card_cache_repository.dart';
import 'package:lizunemu/core/lore/storage/work_lore_repository.dart';
import 'package:lizunemu/core/settings/app_settings_service.dart';
import 'package:lizunemu/core/settings/llm_model_slot.dart';
import 'package:lizunemu/data/models/files/child.dart';
import 'package:lizunemu/data/models/works/work.dart';
import 'package:lizunemu/data/services/llm_client.dart';
import 'package:lizunemu/utils/logger.dart';

enum LoreRegenSection { work, track, character }

class LoreTrackInput {
  final String trackKey;
  final String title;
  final int index;
  final String? subtitleText;

  const LoreTrackInput({
    required this.trackKey,
    required this.title,
    required this.index,
    this.subtitleText,
  });

  bool get hasSubtitles =>
      subtitleText != null && subtitleText!.trim().isNotEmpty;
}

typedef LoreProgressCallback = void Function(String stage, double progress);

/// Multi-pass LLM lore generation + persistence.
class WorkLoreService {
  final LlmClient _llm;
  final AppSettingsService _settings;
  final WorkLoreRepository _repo;
  final Ccv2CardCacheRepository _ccv2Cache;
  final Random _rng;

  WorkLoreService({
    required LlmClient llm,
    required AppSettingsService settings,
    required WorkLoreRepository repo,
    required Ccv2CardCacheRepository ccv2Cache,
    Random? rng,
  })  : _llm = llm,
        _settings = settings,
        _repo = repo,
        _ccv2Cache = ccv2Cache,
        _rng = rng ?? Random();

  Future<WorkLorePack?> load(String workId) => _repo.getByWorkId(workId);

  Future<bool> hasLore(String workId) => _repo.exists(workId);

  Future<void> save(WorkLorePack pack) async {
    final hashed = pack.withRecomputedHash().copyWith(
          updatedAt: DateTime.now().toUtc(),
        );
    await _repo.upsert(hashed);
    await _ccv2Cache.deleteByPrefix('${hashed.workId}:');
  }

  Future<void> delete(String workId) async {
    await _repo.delete(workId);
    await _ccv2Cache.deleteByPrefix('$workId:');
  }

  Future<WorkLorePack> updatePack(WorkLorePack pack) async {
    final next = pack.withRecomputedHash().copyWith(
          updatedAt: DateTime.now().toUtc(),
        );
    await save(next);
    return next;
  }

  static List<LoreTrackInput> tracksFromChildren(List<Child> audioTracks) {
    final out = <LoreTrackInput>[];
    for (var i = 0; i < audioTracks.length; i++) {
      final c = audioTracks[i];
      out.add(
        LoreTrackInput(
          trackKey: LoreJsonUtils.trackKeyFor(
            index: i,
            hash: c.hash,
            mediaDownloadUrl: c.mediaDownloadUrl,
            title: c.title,
          ),
          title: c.title ?? 'Track ${i + 1}',
          index: i,
        ),
      );
    }
    return out;
  }

  Future<WorkLorePack> generate({
    required Work work,
    required List<LoreTrackInput> tracks,
    List<LoreSeedNote> seedNotes = const [],
    LoreProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    _throwIfCancelled(cancelToken);
    final workId = '${work.id ?? work.sourceId ?? 'unknown'}';
    final lang = _settings.resolvedLoreLanguageCode;
    final maxTracks = _settings.maxLoreTracksPerGenerate;
    final limited = tracks.take(maxTracks).toList();

    onProgress?.call('cast', 0.05);
    final cast = await _generateCastAndSynopsis(
      work: work,
      tracks: limited,
      seedNotes: seedNotes,
      languageCode: lang,
      cancelToken: cancelToken,
    );

    var characters = cast.characters;
    var synopsis = cast.synopsis;
    var contentLevel = cast.contentLevel;
    final focusId = cast.focusCharacterId ??
        (characters.isNotEmpty ? characters.first.id : null);

    final summaries = <LoreTrackSummary>[];
    final events = <LoreTimelineEvent>[];
    final carry = <String, Map<String, dynamic>>{
      for (final c in characters)
        c.id: {
          for (final p in c.params)
            if (p.value != null) p.key: p.value,
        },
    };

    for (var i = 0; i < limited.length; i++) {
      _throwIfCancelled(cancelToken);
      final progress = 0.15 + (0.7 * (i / max(1, limited.length)));
      onProgress?.call('track:${limited[i].trackKey}', progress);

      final trackResult = await _generateTrackPass(
        work: work,
        track: limited[i],
        characters: characters,
        carryState: carry,
        seedNotes: seedNotes,
        languageCode: lang,
        cancelToken: cancelToken,
      );
      summaries.add(trackResult.summary);
      events.addAll(trackResult.events);
      for (final entry in trackResult.carryUpdates.entries) {
        carry[entry.key] = {
          ...?carry[entry.key],
          ...entry.value,
        };
      }
    }

    onProgress?.call('reconcile', 0.9);
    final reconciled = await _reconcile(
      work: work,
      synopsis: synopsis,
      characters: characters,
      summaries: summaries,
      events: events,
      languageCode: lang,
      cancelToken: cancelToken,
    );
    synopsis = reconciled.synopsis.isNotEmpty ? reconciled.synopsis : synopsis;
    if (reconciled.characters.isNotEmpty) {
      characters = reconciled.characters;
    }

    final pack = WorkLorePack(
      workId: workId,
      sourceId: work.sourceId,
      workTitle: work.title,
      contentLevel: contentLevel,
      synopsis: synopsis,
      characters: characters,
      trackSummaries: summaries,
      events: events,
      seedNotes: seedNotes,
      focusCharacterId: focusId,
      updatedAt: DateTime.now().toUtc(),
      loreHash: '',
      languageCode: lang,
    ).withRecomputedHash();

    await save(pack);
    onProgress?.call('done', 1.0);
    return pack;
  }

  Future<WorkLorePack> regenerateSection({
    required Work work,
    required WorkLorePack pack,
    required LoreRegenSection section,
    String? trackKey,
    String? characterId,
    List<LoreTrackInput> tracks = const [],
    LoreProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    switch (section) {
      case LoreRegenSection.work:
        onProgress?.call('cast', 0.2);
        final cast = await _generateCastAndSynopsis(
          work: work,
          tracks: tracks.isEmpty
              ? pack.trackSummaries
                  .map(
                    (t) => LoreTrackInput(
                      trackKey: t.trackKey,
                      title: t.trackTitle,
                      index: t.trackIndex,
                    ),
                  )
                  .toList()
              : tracks,
          seedNotes: pack.seedNotes,
          languageCode: pack.languageCode ?? _settings.resolvedLoreLanguageCode,
          cancelToken: cancelToken,
          existingCharacters: pack.characters,
        );
        final next = pack.copyWith(
          synopsis: cast.synopsis.isNotEmpty ? cast.synopsis : pack.synopsis,
          characters:
              cast.characters.isNotEmpty ? cast.characters : pack.characters,
          contentLevel: cast.contentLevel,
          focusCharacterId: cast.focusCharacterId ?? pack.focusCharacterId,
          updatedAt: DateTime.now().toUtc(),
        );
        return updatePack(next);
      case LoreRegenSection.track:
        if (trackKey == null) {
          throw ArgumentError('trackKey required for track regen');
        }
        LoreTrackInput? track;
        for (final t in tracks) {
          if (t.trackKey == trackKey) {
            track = t;
            break;
          }
        }
        if (track == null) {
          for (final s in pack.trackSummaries) {
            if (s.trackKey == trackKey) {
              track = LoreTrackInput(
                trackKey: s.trackKey,
                title: s.trackTitle,
                index: s.trackIndex,
              );
              break;
            }
          }
        }
        if (track == null) {
          throw StateError('track not found: $trackKey');
        }
        onProgress?.call('track:$trackKey', 0.4);
        final carry = <String, Map<String, dynamic>>{
          for (final c in pack.characters)
            c.id: {
              for (final p in c.params)
                if (p.value != null) p.key: p.value,
            },
        };
        final result = await _generateTrackPass(
          work: work,
          track: track,
          characters: pack.characters,
          carryState: carry,
          seedNotes: pack.seedNotes,
          languageCode: pack.languageCode ?? _settings.resolvedLoreLanguageCode,
          cancelToken: cancelToken,
        );
        final summaries = pack.trackSummaries
            .where((s) => s.trackKey != trackKey)
            .toList()
          ..add(result.summary)
          ..sort((a, b) => a.trackIndex.compareTo(b.trackIndex));
        final events = pack.events.where((e) => e.trackKey != trackKey).toList()
          ..addAll(result.events);
        return updatePack(
          pack.copyWith(
            trackSummaries: summaries,
            events: events,
            updatedAt: DateTime.now().toUtc(),
          ),
        );
      case LoreRegenSection.character:
        if (characterId == null) {
          throw ArgumentError('characterId required for character regen');
        }
        onProgress?.call('character:$characterId', 0.4);
        final refreshed = await _regenerateCharacter(
          work: work,
          pack: pack,
          characterId: characterId,
          cancelToken: cancelToken,
        );
        final chars = pack.characters
            .map((c) => c.id == characterId ? refreshed : c)
            .toList();
        return updatePack(
          pack.copyWith(
            characters: chars,
            updatedAt: DateTime.now().toUtc(),
          ),
        );
    }
  }

  Future<WorkLorePack> generateSecrets(WorkLorePack pack) async {
    final lang = pack.languageCode ?? _settings.resolvedLoreLanguageCode;
    final prompt = '''
You fill speculative NSFW character parameters for an ASMR work lore pack.
Mark every filled param with speculative=true. Do NOT invent events.
Return JSON: {"characters":[{"id":"...","params":[{"key":"...","module":"...","label":"...","type":"gauge|text|number|enumeration|boolean","value":...,"speculative":true,"hudPinned":false}]}]}
Ontology modules for explicit: ${LoreOntology.explicitModules.join(', ')}.
Fill speculative NSFW params using ontology starter keys (all speculative=true). Prefer body/fluids/fertility/risk/toys/kink modules when inventing secrets.
Starter keys: ${LoreOntology.starterParams().map((p) => p.key).join(', ')}.
Language for labels/text values: $lang.
Existing cast:
${jsonEncode(pack.characters.map((c) => c.toJson()).toList())}
''';
    final raw = await _llm.chatCompletion(
      messages: [
        {'role': 'system', 'content': _systemPrompt(lang)},
        {'role': 'user', 'content': prompt},
      ],
      temperature: 0.4,
      modelSlot: LlmModelSlot.main,
    );
    final map = LoreJsonUtils.parseObject(raw) ?? {};
    final updates = <String, List<LoreParam>>{};
    for (final item in (map['characters'] as List?) ?? const []) {
      if (item is! Map) continue;
      final id = item['id'] as String? ?? '';
      final params = (item['params'] as List?)
              ?.whereType<Map>()
              .map((e) {
                final p = LoreParam.fromJson(Map<String, dynamic>.from(e));
                return p.copyWith(speculative: true);
              })
              .toList() ??
          const <LoreParam>[];
      if (id.isNotEmpty) updates[id] = params;
    }

    final characters = pack.characters.map((c) {
      final extra = updates[c.id];
      if (extra == null || extra.isEmpty) return c;
      final byKey = <String, LoreParam>{for (final p in c.params) p.key: p};
      for (final p in extra) {
        byKey[p.key] = p;
      }
      return c.copyWith(params: byKey.values.toList());
    }).toList();

    return updatePack(
      pack.copyWith(
        characters: characters,
        contentLevel: LoreContentLevel.explicit,
        explicitRevealed: true,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  // --- pipeline internals ---

  String _systemPrompt(String lang) => '''
You are a careful ASMR work-lore analyst for Lizunemu.
Output ONLY valid JSON (no markdown). Write prose fields in language code "$lang".
Prefer evidence from subtitles when present. Sparse params: omit unknown values.
Never invent VA links as confirmed — set vaLinkProposed true and vaLinkConfirmed false.
''';

  Future<_CastPassResult> _generateCastAndSynopsis({
    required Work work,
    required List<LoreTrackInput> tracks,
    required List<LoreSeedNote> seedNotes,
    required String languageCode,
    CancelToken? cancelToken,
    List<LoreCharacter>? existingCharacters,
  }) async {
    _throwIfCancelled(cancelToken);
    final sampleSubs = tracks
        .where((t) => t.hasSubtitles)
        .take(3)
        .map((t) => {
              'track': t.title,
              'excerpt': _clip(t.subtitleText!, 2500),
            })
        .toList();

    final vas = _vaSummaries(work.vas);

    final user = '''
Build work-level lore cast + synopsis.
Return JSON:
{
  "synopsis": "...",
  "contentLevel": "sfw|suggestive|explicit",
  "focusCharacterId": "c1",
  "characters": [
    {
      "id": "c1",
      "name": "...",
      "aliases": [],
      "role": "...",
      "appearance": "...",
      "personality": "...",
      "relationshipToListener": "...",
      "voiceActorId": null,
      "voiceActorName": null,
      "vaLinkProposed": false,
      "vaLinkConfirmed": false,
      "kinks": [{"name":"...","stance":"yes|maybe|no|unknown"}],
      "params": [{"key":"arousal","module":"psyche","label":"Arousal","type":"gauge","value":0,"hudPinned":true}],
      "notes": null,
      "isFocusDefault": true
    }
  ]
}
Pin HUD defaults on arousal/horny/pleasure/affection/corruption/wetness/pregnancy_chance/clothing_state/panties/location when relevant.
Use ontology starter keys when evidence supports them (sparse — omit unknowns). Modules: ${LoreOntology.allModules.join(', ')}.
Ontology starter keys: ${LoreOntology.starterParams().map((p) => '${p.key}(${p.module})').join(', ')}.

Work metadata:
${jsonEncode({
      'id': work.id,
      'sourceId': work.sourceId,
      'title': work.title,
      'circle': work.circle?.name,
      'tags': work.tags?.map((t) => t.name).toList(),
      'vas': vas,
      'nsfw': work.nsfw,
    })}
Track list: ${jsonEncode(tracks.map((t) => {'key': t.trackKey, 'title': t.title, 'hasSubs': t.hasSubtitles}).toList())}
Seed notes: ${jsonEncode(seedNotes.map((e) => e.toJson()).toList())}
Subtitle samples: ${jsonEncode(sampleSubs)}
${existingCharacters != null ? 'Existing characters to refine: ${jsonEncode(existingCharacters.map((e) => e.toJson()).toList())}' : ''}
''';

    final raw = await _llm.chatCompletion(
      messages: [
        {'role': 'system', 'content': _systemPrompt(languageCode)},
        {'role': 'user', 'content': user},
      ],
      temperature: 0.3,
      modelSlot: LlmModelSlot.main,
    );
    final map = LoreJsonUtils.parseObject(raw) ?? {};
    final characters = (map['characters'] as List?)
            ?.whereType<Map>()
            .map((e) => LoreCharacter.fromJson(Map<String, dynamic>.from(e)))
            .where((c) => c.id.isNotEmpty && c.name.isNotEmpty)
            .toList() ??
        const <LoreCharacter>[];

    return _CastPassResult(
      synopsis: map['synopsis'] as String? ?? '',
      contentLevel: LoreContentLevelX.parse(map['contentLevel'] as String?),
      focusCharacterId: map['focusCharacterId'] as String?,
      characters: characters.isEmpty
          ? [
              LoreCharacter(
                id: 'c1',
                name: _firstVaName(work.vas) ?? 'Character',
                isFocusDefault: true,
                params: LoreOntology.starterParams(includeExplicit: false)
                    .where((p) => p.hudPinned)
                    .toList(),
              ),
            ]
          : characters,
    );
  }

  static List<Map<String, dynamic>> _vaSummaries(List<dynamic>? vas) {
    if (vas == null) return const [];
    final out = <Map<String, dynamic>>[];
    for (final v in vas) {
      if (v is Map) {
        out.add({
          'id': v['id'],
          'name': v['name'],
        });
      } else {
        out.add({'name': v.toString()});
      }
    }
    return out;
  }

  static String? _firstVaName(List<dynamic>? vas) {
    final list = _vaSummaries(vas);
    if (list.isEmpty) return null;
    final name = list.first['name'];
    return name?.toString();
  }

  Future<_TrackPassResult> _generateTrackPass({
    required Work work,
    required LoreTrackInput track,
    required List<LoreCharacter> characters,
    required Map<String, Map<String, dynamic>> carryState,
    required List<LoreSeedNote> seedNotes,
    required String languageCode,
    CancelToken? cancelToken,
  }) async {
    _throwIfCancelled(cancelToken);
    final hasSubs = track.hasSubtitles;
    final user = '''
Analyze ONE track. Return JSON:
{
  "summary": {"trackKey":"${track.trackKey}","trackTitle":"${track.title}","trackIndex":${track.index},"summary":"...","lowConfidence":${!hasSubs},"hasSubtitles":$hasSubs},
  "events": [
    {
      "id":"e1","trackKey":"${track.trackKey}","atMs":12000,"kind":"paramChange|beat|clothing|body|relationship|location|addition|other",
      "title":"...","detail":"...","characterId":"c1",
      "deltas":[{"key":"arousal","from":10,"to":40}],
      "evidenceQuote":"...","evidenceStartMs":11000,"evidenceEndMs":15000,
      "speculative":false,"confidence":0.8
    }
  ],
  "carryUpdates": {"c1": {"arousal": 40, "clothing_state": "..."}}
}
If no subtitles, write a thin metadata-based summary, lowConfidence true, few or no events.
Carry-in state: ${jsonEncode(carryState)}
Characters: ${jsonEncode(characters.map((c) => {'id': c.id, 'name': c.name}).toList())}
Seed notes: ${jsonEncode(seedNotes.map((e) => e.toJson()).toList())}
Work: ${work.title} (${work.sourceId})
Track: ${track.title}
Subtitles:
${hasSubs ? _clip(track.subtitleText!, 12000) : '(none)'}
''';

    try {
      final raw = await _llm.chatCompletion(
        messages: [
          {'role': 'system', 'content': _systemPrompt(languageCode)},
          {'role': 'user', 'content': user},
        ],
        temperature: 0.3,
        modelSlot: LlmModelSlot.lite,
      );
      final map = LoreJsonUtils.parseObject(raw) ?? {};
      final summaryJson = map['summary'];
      final summary = summaryJson is Map
          ? LoreTrackSummary.fromJson(Map<String, dynamic>.from(summaryJson))
          : LoreTrackSummary(
              trackKey: track.trackKey,
              trackTitle: track.title,
              trackIndex: track.index,
              summary: hasSubs ? '' : 'No subtitles; thin lore.',
              lowConfidence: !hasSubs,
              hasSubtitles: hasSubs,
            );

      final events = (map['events'] as List?)
              ?.whereType<Map>()
              .map((e) {
                final m = Map<String, dynamic>.from(e);
                m['trackKey'] = m['trackKey'] ?? track.trackKey;
                m['id'] = m['id'] ?? _newId('e');
                return LoreTimelineEvent.fromJson(m);
              })
              .toList() ??
          const <LoreTimelineEvent>[];

      final carryUpdates = <String, Map<String, dynamic>>{};
      final carryRaw = map['carryUpdates'];
      if (carryRaw is Map) {
        for (final entry in carryRaw.entries) {
          if (entry.value is Map) {
            carryUpdates[entry.key.toString()] =
                Map<String, dynamic>.from(entry.value as Map);
          }
        }
      }

      return _TrackPassResult(
        summary: summary.copyWith(
          trackKey: track.trackKey,
          trackTitle: track.title,
          trackIndex: track.index,
          hasSubtitles: hasSubs,
          lowConfidence: summary.lowConfidence || !hasSubs,
        ),
        events: events,
        carryUpdates: carryUpdates,
      );
    } catch (e, st) {
      AppLogger.error('Lore track pass failed: ${track.trackKey}', e, st);
      return _TrackPassResult(
        summary: LoreTrackSummary(
          trackKey: track.trackKey,
          trackTitle: track.title,
          trackIndex: track.index,
          summary: '',
          lowConfidence: true,
          hasSubtitles: hasSubs,
        ),
        events: const [],
        carryUpdates: const {},
      );
    }
  }

  Future<_ReconcileResult> _reconcile({
    required Work work,
    required String synopsis,
    required List<LoreCharacter> characters,
    required List<LoreTrackSummary> summaries,
    required List<LoreTimelineEvent> events,
    required String languageCode,
    CancelToken? cancelToken,
  }) async {
    _throwIfCancelled(cancelToken);
    final user = '''
Reconcile lore consistency. Fix name drift, ensure focus character exists, polish synopsis.
Return JSON: {"synopsis":"...","characters":[...same schema...]}
Current synopsis: $synopsis
Characters: ${jsonEncode(characters.map((e) => e.toJson()).toList())}
Track summaries: ${jsonEncode(summaries.map((e) => e.toJson()).toList())}
Event count: ${events.length}
Work: ${work.title}
''';
    try {
      final raw = await _llm.chatCompletion(
        messages: [
          {'role': 'system', 'content': _systemPrompt(languageCode)},
          {'role': 'user', 'content': user},
        ],
        temperature: 0.2,
        modelSlot: LlmModelSlot.main,
      );
      final map = LoreJsonUtils.parseObject(raw) ?? {};
      final chars = (map['characters'] as List?)
              ?.whereType<Map>()
              .map((e) => LoreCharacter.fromJson(Map<String, dynamic>.from(e)))
              .where((c) => c.id.isNotEmpty)
              .toList() ??
          const <LoreCharacter>[];
      return _ReconcileResult(
        synopsis: map['synopsis'] as String? ?? synopsis,
        characters: chars,
      );
    } catch (e, st) {
      AppLogger.error('Lore reconcile failed', e, st);
      return _ReconcileResult(synopsis: synopsis, characters: characters);
    }
  }

  Future<LoreCharacter> _regenerateCharacter({
    required Work work,
    required WorkLorePack pack,
    required String characterId,
    CancelToken? cancelToken,
  }) async {
    _throwIfCancelled(cancelToken);
    final existing = pack.characterById(characterId);
    if (existing == null) {
      throw StateError('character not found: $characterId');
    }
    final lang = pack.languageCode ?? _settings.resolvedLoreLanguageCode;
    final user = '''
Regenerate ONE character sheet in place (keep id="$characterId").
Return JSON character object only.
Existing: ${jsonEncode(existing.toJson())}
Synopsis: ${pack.synopsis}
Work: ${work.title}
Seed notes: ${jsonEncode(pack.seedNotes.map((e) => e.toJson()).toList())}
''';
    final raw = await _llm.chatCompletion(
      messages: [
        {'role': 'system', 'content': _systemPrompt(lang)},
        {'role': 'user', 'content': user},
      ],
      temperature: 0.3,
      modelSlot: LlmModelSlot.main,
    );
    final map = LoreJsonUtils.parseObject(raw);
    if (map == null) return existing;
    final next = LoreCharacter.fromJson({...map, 'id': characterId});
    return next.name.isEmpty ? existing : next;
  }

  String _clip(String s, int max) =>
      s.length <= max ? s : '${s.substring(0, max)}\n…';

  String _newId(String prefix) =>
      '$prefix${DateTime.now().millisecondsSinceEpoch}_${_rng.nextInt(1 << 20)}';

  void _throwIfCancelled(CancelToken? token) {
    if (token != null && token.isCancelled) {
      throw DioException(
        requestOptions: RequestOptions(path: 'lore'),
        type: DioExceptionType.cancel,
        error: 'cancelled',
      );
    }
  }
}

class _CastPassResult {
  final String synopsis;
  final LoreContentLevel contentLevel;
  final String? focusCharacterId;
  final List<LoreCharacter> characters;

  const _CastPassResult({
    required this.synopsis,
    required this.contentLevel,
    required this.focusCharacterId,
    required this.characters,
  });
}

class _TrackPassResult {
  final LoreTrackSummary summary;
  final List<LoreTimelineEvent> events;
  final Map<String, Map<String, dynamic>> carryUpdates;

  const _TrackPassResult({
    required this.summary,
    required this.events,
    required this.carryUpdates,
  });
}

class _ReconcileResult {
  final String synopsis;
  final List<LoreCharacter> characters;

  const _ReconcileResult({
    required this.synopsis,
    required this.characters,
  });
}
