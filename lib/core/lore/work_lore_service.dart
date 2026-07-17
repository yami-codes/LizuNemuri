import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:lizunemu/core/lore/lore_json_utils.dart';
import 'package:lizunemu/core/lore/lore_llm_pacer.dart';
import 'package:lizunemu/core/lore/lore_resume.dart';
import 'package:lizunemu/core/lore/lore_state_projector.dart';
import 'package:lizunemu/core/lore/lore_track_context_brief.dart';
import 'package:lizunemu/core/lore/models/lore_character.dart';
import 'package:lizunemu/core/lore/models/lore_content_level.dart';
import 'package:lizunemu/core/lore/models/lore_event.dart';
import 'package:lizunemu/core/lore/models/lore_ontology.dart';
import 'package:lizunemu/core/lore/models/lore_param.dart';
import 'package:lizunemu/core/lore/models/work_lore_pack.dart';
import 'package:lizunemu/core/lore/streaming_lore_track_parser.dart';
import 'package:lizunemu/core/lore/storage/ccv2_card_cache_repository.dart';
import 'package:lizunemu/core/lore/storage/work_lore_repository.dart';
import 'package:lizunemu/core/settings/app_settings_service.dart';
import 'package:lizunemu/core/settings/llm_model_slot.dart';
import 'package:lizunemu/data/models/files/child.dart';
import 'package:lizunemu/data/models/works/work.dart';
import 'package:lizunemu/data/services/exceptions/llm_translation_exception.dart';
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
typedef LoreWaitingCallback = void Function(bool waiting);

/// Live NDJSON partials while a track LLM pass is streaming.
class LoreTrackPartial {
  final String? summary;
  final int eventCount;
  final String? lastEventTitle;

  const LoreTrackPartial({
    this.summary,
    this.eventCount = 0,
    this.lastEventTitle,
  });
}

typedef LoreTrackPartialCallback = void Function(LoreTrackPartial partial);

bool loreIsHardLlmError(LlmTranslationException e) =>
    e.type == LlmTranslationErrorType.rateLimited ||
    e.type == LlmTranslationErrorType.authError ||
    e.type == LlmTranslationErrorType.missingApiKey ||
    e.type == LlmTranslationErrorType.invalidConfig;

/// Soft-retry delay: exponential base with jitter (BullMQ-style).
Duration loreSoftRetryDelay(int attempt, {Random? random}) {
  final a = attempt.clamp(1, 8);
  final baseMs = (500 * (1 << (a - 1))).clamp(500, 8000);
  final jitter = (random ?? Random()).nextInt(max(1, baseMs ~/ 2));
  return Duration(milliseconds: baseMs + jitter);
}


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
    bool includeSecrets = true,
    WorkLorePack? resumeFrom,
    LoreProgressCallback? onProgress,
    LoreWaitingCallback? onWaiting,
    LoreTrackPartialCallback? onTrackPartial,
    CancelToken? cancelToken,
  }) async {
    _throwIfCancelled(cancelToken);
    final workId = '${work.id ?? work.sourceId ?? 'unknown'}';
    final lang = _settings.resolvedLoreLanguageCode;
    final maxTracks = _settings.maxLoreTracksPerGenerate;
    final limited = tracks.take(maxTracks).toList();
    final pacer = LoreLlmPacer(paceMs: _settings.loreLlmPaceMs);
    final orderedKeys = [for (final t in limited) t.trackKey];

    late List<LoreCharacter> characters;
    late String synopsis;
    late LoreContentLevel contentLevel;
    late String? focusId;

    final reuseCast = lorePackHasReusableCast(resumeFrom);
    if (reuseCast) {
      characters = List<LoreCharacter>.from(resumeFrom!.characters);
      synopsis = resumeFrom.synopsis;
      contentLevel = resumeFrom.contentLevel;
      focusId = resumeFrom.focusCharacterId ??
          (characters.isNotEmpty ? characters.first.id : null);
      onProgress?.call('cast', 0.05);
      AppLogger.debug('Lore resume: reuse cast (${characters.length} chars)');
    } else {
      onProgress?.call('cast', 0.05);
      await pacer.beforeNextCall();
      final cast = await _chatWithPacer(
        pacer: pacer,
        onWaiting: onWaiting,
        run: () => _generateCastAndSynopsis(
          work: work,
          tracks: limited,
          seedNotes: seedNotes,
          languageCode: lang,
          cancelToken: cancelToken,
          slimOntology: includeSecrets,
        ),
      );
      characters = cast.characters;
      synopsis = cast.synopsis;
      contentLevel = cast.contentLevel;
      focusId = cast.focusCharacterId ??
          (characters.isNotEmpty ? characters.first.id : null);
    }

    // Seed secret baselines locally before the merged track+secrets pass.
    if (includeSecrets) {
      characters = _seedSpeculativeBaselines(characters);
      if (contentLevel.index < LoreContentLevel.explicit.index) {
        contentLevel = LoreContentLevel.explicit;
      }
    }

    final skipKeys = loreResumeSkipTrackKeys(resumeFrom, orderedKeys).toSet();
    final summaries = loreResumeSeedSummaries(resumeFrom, orderedKeys).toList();
    final events = loreResumeSeedEvents(resumeFrom, skipKeys).toList();

    var carry = <String, Map<String, dynamic>>{
      for (final c in characters)
        c.id: {
          for (final p in c.params)
            if (p.value != null) p.key: p.value,
        },
    };
    final baselines = {
      for (final e in carry.entries) e.key: Map<String, dynamic>.from(e.value),
    };

    WorkLorePack checkpoint({
      required List<LoreTrackSummary> trackSummaries,
      required List<LoreTimelineEvent> trackEvents,
    }) {
      return WorkLorePack(
        workId: workId,
        sourceId: work.sourceId,
        workTitle: work.title,
        contentLevel: contentLevel,
        synopsis: synopsis,
        characters: characters,
        trackSummaries: List<LoreTrackSummary>.from(trackSummaries)
          ..sort((a, b) => a.trackIndex.compareTo(b.trackIndex)),
        events: List<LoreTimelineEvent>.from(trackEvents),
        seedNotes: seedNotes.isNotEmpty
            ? seedNotes
            : (resumeFrom?.seedNotes ?? const []),
        focusCharacterId: focusId,
        updatedAt: DateTime.now().toUtc(),
        loreHash: '',
        languageCode: lang,
        explicitRevealed: includeSecrets,
      ).withRecomputedHash();
    }

    // Persist cast (+ any resumed tracks) so a kill mid-loop keeps progress.
    await save(
      checkpoint(trackSummaries: summaries, trackEvents: events),
    );

    for (var i = 0; i < limited.length; i++) {
      _throwIfCancelled(cancelToken);
      final track = limited[i];
      final progress = 0.08 + (0.75 * (i / max(1, limited.length)));
      onProgress?.call(
        'track:${i + 1}/${limited.length}:${track.title}',
        progress,
      );

      if (skipKeys.contains(track.trackKey)) {
        AppLogger.debug('Lore resume: skip track ${track.trackKey}');
        final after = 0.08 + (0.75 * ((i + 1) / max(1, limited.length)));
        onProgress?.call(
          'track:${i + 1}/${limited.length}:${track.title}',
          after.clamp(0.0, 0.87),
        );
        continue;
      }

      // Drop incomplete stub for this key if present (soft-empty redo).
      summaries.removeWhere((s) => s.trackKey == track.trackKey);
      events.removeWhere((e) => e.trackKey == track.trackKey);

      if (summaries.isNotEmpty) {
        final priorKeys = {for (final s in summaries) s.trackKey};
        carry = LoreTrackContextBrief.settleCarryFromEvents(
          baselines: baselines,
          events: events,
          priorTrackKeys: priorKeys,
        );
      }

      final priorBrief = LoreTrackContextBrief.build(
        synopsis: synopsis,
        completedSummaries: summaries,
        completedEvents: events,
        carryState: carry,
        slimCarry: summaries.isNotEmpty,
      );

      await pacer.beforeNextCall();
      final trackResult = await _chatWithPacer(
        pacer: pacer,
        onWaiting: onWaiting,
        run: () => _generateTrackPass(
          work: work,
          track: track,
          characters: characters,
          carryState: summaries.isEmpty
              ? carry
              : LoreTrackContextBrief.slimCarryMap(carry),
          seedNotes: summaries.isEmpty ? seedNotes : const [],
          languageCode: lang,
          cancelToken: cancelToken,
          includeSecrets: includeSecrets,
          priorContextBrief: priorBrief,
          isFirstTrack: summaries.isEmpty,
          onTrackPartial: onTrackPartial,
        ),
      );
      summaries.add(trackResult.summary);
      events.addAll(trackResult.events);
      for (final entry in trackResult.carryUpdates.entries) {
        carry[entry.key] = {
          ...?carry[entry.key],
          ...entry.value,
        };
      }

      await save(
        checkpoint(trackSummaries: summaries, trackEvents: events),
      );

      final after = 0.08 + (0.75 * ((i + 1) / max(1, limited.length)));
      onProgress?.call(
        'track:${i + 1}/${limited.length}:${track.title}',
        after.clamp(0.0, 0.87),
      );
    }

    // Rebuild carry across all completed tracks before reconcile / params.
    if (summaries.isNotEmpty) {
      carry = LoreTrackContextBrief.settleCarryFromEvents(
        baselines: baselines,
        events: events,
        priorTrackKeys: {for (final s in summaries) s.trackKey},
      );
    }

    final doReconcile = LoreTrackContextBrief.shouldReconcile(
      characterCount: characters.length,
      summaries: summaries,
      seedNotes: seedNotes,
    );
    if (doReconcile) {
      onProgress?.call('reconcile', 0.88);
      await pacer.beforeNextCall();
      final reconciled = await _chatWithPacer(
        pacer: pacer,
        onWaiting: onWaiting,
        run: () => _reconcile(
          work: work,
          synopsis: synopsis,
          characters: characters,
          summaries: summaries,
          events: events,
          languageCode: lang,
          cancelToken: cancelToken,
        ),
      );
      synopsis =
          reconciled.synopsis.isNotEmpty ? reconciled.synopsis : synopsis;
      if (reconciled.characters.isNotEmpty) {
        characters = reconciled.characters;
        if (includeSecrets) {
          characters = _seedSpeculativeBaselines(characters);
        }
      }
    }

    if (includeSecrets) {
      characters = _applyCarryToParams(
        characters,
        carry,
        speculativeOnly: true,
      );
    }

    final pack = checkpoint(
      trackSummaries: summaries,
      trackEvents: events,
    ).copyWith(
      characters: characters,
      synopsis: synopsis,
      updatedAt: DateTime.now().toUtc(),
    ).withRecomputedHash();

    // Secrets are merged into the track pass — no second N× secrets loop.
    await save(pack);
    onProgress?.call('done', 1.0);
    return pack;
  }

  Future<T> _chatWithPacer<T>({
    required LoreLlmPacer pacer,
    required Future<T> Function() run,
    LoreWaitingCallback? onWaiting,
  }) async {
    onWaiting?.call(true);
    try {
      final result = await run();
      pacer.markCallEnded();
      return result;
    } on LlmTranslationException catch (e) {
      pacer.markCallEnded();
      if (e.type == LlmTranslationErrorType.rateLimited) {
        pacer.noteRateLimited(seconds: 8);
      }
      rethrow;
    } catch (e) {
      pacer.markCallEnded();
      rethrow;
    } finally {
      onWaiting?.call(false);
    }
  }

  Future<WorkLorePack> regenerateSection({
    required Work work,
    required WorkLorePack pack,
    required LoreRegenSection section,
    String? trackKey,
    String? characterId,
    List<LoreTrackInput> tracks = const [],
    LoreProgressCallback? onProgress,
    LoreWaitingCallback? onWaiting,
    LoreTrackPartialCallback? onTrackPartial,
    CancelToken? cancelToken,
  }) async {
    switch (section) {
      case LoreRegenSection.work:
        onProgress?.call('cast', 0.2);
        onWaiting?.call(true);
        late final _CastPassResult cast;
        try {
          cast = await _generateCastAndSynopsis(
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
            languageCode:
                pack.languageCode ?? _settings.resolvedLoreLanguageCode,
            cancelToken: cancelToken,
            existingCharacters: pack.characters,
          );
        } finally {
          onWaiting?.call(false);
        }
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
        final resolvedTrack = track;
        onProgress?.call('track:$trackKey', 0.4);
        final baselines = <String, Map<String, dynamic>>{
          for (final c in pack.characters)
            c.id: {
              for (final p in c.params)
                if (p.value != null) p.key: p.value,
            },
        };
        final primary = LoreStateProjector.primaryTrackKeys(pack);
        final ord = primary.indexOf(trackKey);
        final priorKeys = ord <= 0
            ? <String>{}
            : primary.sublist(0, ord).toSet();
        final carry = LoreTrackContextBrief.settleCarryFromEvents(
          baselines: baselines,
          events: pack.events,
          priorTrackKeys: priorKeys,
        );
        final priorSummaries = pack.trackSummaries
            .where((s) => priorKeys.contains(s.trackKey))
            .toList();
        final brief = LoreTrackContextBrief.build(
          synopsis: pack.synopsis,
          completedSummaries: priorSummaries,
          completedEvents:
              pack.events.where((e) => priorKeys.contains(e.trackKey)).toList(),
          carryState: carry,
        );
        final pacer = LoreLlmPacer(paceMs: _settings.loreLlmPaceMs);
        await pacer.beforeNextCall();
        final result = await _chatWithPacer(
          pacer: pacer,
          onWaiting: onWaiting,
          run: () => _generateTrackPass(
            work: work,
            track: resolvedTrack,
            characters: pack.characters,
            carryState: LoreTrackContextBrief.slimCarryMap(carry),
            seedNotes: pack.seedNotes,
            languageCode:
                pack.languageCode ?? _settings.resolvedLoreLanguageCode,
            cancelToken: cancelToken,
            includeSecrets: pack.explicitRevealed,
            priorContextBrief: brief,
            isFirstTrack: priorKeys.isEmpty,
            onTrackPartial: onTrackPartial,
          ),
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
        onWaiting?.call(true);
        late final LoreCharacter refreshed;
        try {
          refreshed = await _regenerateCharacter(
            work: work,
            pack: pack,
            characterId: characterId,
            cancelToken: cancelToken,
          );
        } finally {
          onWaiting?.call(false);
        }
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

  Future<WorkLorePack> generateSecrets(
    WorkLorePack pack, {
    required Work work,
    List<LoreTrackInput> tracks = const [],
    LoreProgressCallback? onProgress,
    LoreWaitingCallback? onWaiting,
    LoreTrackPartialCallback? onTrackPartial,
    CancelToken? cancelToken,
  }) async {
    return _applySecretsTimeline(
      pack: pack,
      work: work,
      tracks: tracks,
      onProgress: onProgress,
      onWaiting: onWaiting,
      onTrackPartial: onTrackPartial,
      cancelToken: cancelToken,
      persist: true,
    );
  }

  /// Seeds speculative baselines + per-track secret events.
  /// When [persist] is false, caller saves (used by bulk [generate]).
  Future<WorkLorePack> _applySecretsTimeline({
    required WorkLorePack pack,
    required Work work,
    List<LoreTrackInput> tracks = const [],
    LoreProgressCallback? onProgress,
    LoreWaitingCallback? onWaiting,
    LoreTrackPartialCallback? onTrackPartial,
    CancelToken? cancelToken,
    required bool persist,
  }) async {
    final lang = pack.languageCode ?? _settings.resolvedLoreLanguageCode;
    onProgress?.call('secrets:seed', 0.05);
    _throwIfCancelled(cancelToken);

    var characters = _seedSpeculativeBaselines(pack.characters);

    final inputs = _secretTrackInputs(pack: pack, tracks: tracks);
    final maxTracks = _settings.maxLoreTracksPerGenerate;
    final limited = inputs.take(maxTracks).toList();

    final kept = pack.events.where((e) => !e.speculative).toList();
    final newSecretEvents = <LoreTimelineEvent>[];
    final pacer = LoreLlmPacer(paceMs: _settings.loreLlmPaceMs);

    var carry = <String, Map<String, dynamic>>{
      for (final c in characters)
        c.id: {
          for (final p in c.params)
            if (p.value != null) p.key: p.value,
        },
    };
    final baselines = {
      for (final e in carry.entries) e.key: Map<String, dynamic>.from(e.value),
    };
    final completedKeys = <String>{};

    for (var i = 0; i < limited.length; i++) {
      _throwIfCancelled(cancelToken);
      final track = limited[i];
      final progress = 0.1 + (0.8 * (i / max(1, limited.length)));
      onProgress?.call('secrets:${track.trackKey}', progress);

      if (i > 0) {
        carry = LoreTrackContextBrief.settleCarryFromEvents(
          baselines: baselines,
          events: [...kept, ...newSecretEvents],
          priorTrackKeys: completedKeys,
        );
      }

      final brief = LoreTrackContextBrief.build(
        synopsis: pack.synopsis,
        completedSummaries: pack.trackSummaries
            .where((s) => completedKeys.contains(s.trackKey))
            .toList(),
        completedEvents: [...kept, ...newSecretEvents],
        carryState: carry,
        slimCarry: i > 0,
      );

      await pacer.beforeNextCall();
      final pass = await _chatWithPacer(
        pacer: pacer,
        onWaiting: onWaiting,
        run: () => _generateSecretsTrackPass(
          work: work,
          track: track,
          characters: characters,
          carryState: i == 0
              ? carry
              : LoreTrackContextBrief.slimCarryMap(carry),
          existingTrackEvents: kept.where((e) => e.trackKey == track.trackKey),
          languageCode: lang,
          cancelToken: cancelToken,
          priorContextBrief: brief,
          onTrackPartial: onTrackPartial,
        ),
      );
      newSecretEvents.addAll(pass.events);
      completedKeys.add(track.trackKey);
      for (final entry in pass.carryUpdates.entries) {
        carry[entry.key] = {
          ...?carry[entry.key],
          ...entry.value,
        };
      }
    }

    characters = _applyCarryToParams(
      characters,
      carry,
      speculativeOnly: true,
    );

    final next = pack.copyWith(
      characters: characters,
      events: [...kept, ...newSecretEvents],
      contentLevel: LoreContentLevel.explicit,
      explicitRevealed: true,
      updatedAt: DateTime.now().toUtc(),
    );

    onProgress?.call('done', 1.0);
    if (persist) return updatePack(next);
    return next.withRecomputedHash();
  }

  /// Ensure explicit-ontology keys exist as speculative baselines (no LLM).
  static List<LoreCharacter> seedSpeculativeBaselinesForTest(
    List<LoreCharacter> characters,
  ) =>
      _seedSpeculativeBaselines(characters);

  static List<LoreCharacter> _seedSpeculativeBaselines(
    List<LoreCharacter> characters,
  ) {
    final starters = LoreOntology.starterParams(includeExplicit: true)
        .where((p) => LoreOntology.explicitModules.contains(p.module))
        .toList();
    return characters.map((c) {
      final byKey = <String, LoreParam>{for (final p in c.params) p.key: p};
      for (final s in starters) {
        if (byKey.containsKey(s.key)) {
          final existing = byKey[s.key]!;
          if (LoreOntology.explicitModules.contains(existing.module) &&
              !existing.speculative) {
            // Keep evidence values; only mark module-explicit unknowns later.
            continue;
          }
          continue;
        }
        byKey[s.key] = s.copyWith(speculative: true);
      }
      return c.copyWith(params: byKey.values.toList());
    }).toList();
  }

  static List<LoreCharacter> _applyCarryToParams(
    List<LoreCharacter> characters,
    Map<String, Map<String, dynamic>> carry, {
    required bool speculativeOnly,
  }) {
    return characters.map((c) {
      final updates = carry[c.id];
      if (updates == null || updates.isEmpty) return c;
      final byKey = <String, LoreParam>{for (final p in c.params) p.key: p};
      for (final entry in updates.entries) {
        final existing = byKey[entry.key];
        if (existing == null) {
          byKey[entry.key] = LoreParam(
            key: entry.key,
            module: LoreOntology.moduleCustom,
            label: entry.key,
            type: entry.value is num ? LoreParamType.gauge : LoreParamType.text,
            value: entry.value,
            speculative: true,
          );
          continue;
        }
        if (speculativeOnly &&
            !existing.speculative &&
            !LoreOntology.explicitModules.contains(existing.module)) {
          continue;
        }
        byKey[entry.key] = existing.copyWith(
          value: entry.value,
          speculative: existing.speculative ||
              LoreOntology.explicitModules.contains(existing.module),
        );
      }
      return c.copyWith(params: byKey.values.toList());
    }).toList();
  }

  List<LoreTrackInput> _secretTrackInputs({
    required WorkLorePack pack,
    required List<LoreTrackInput> tracks,
  }) {
    final primary = LoreStateProjector.primaryTrackKeys(pack);
    final byKey = <String, LoreTrackInput>{
      for (final t in tracks) t.trackKey: t,
    };
    // Prefer primary keys that already have story events; then remaining primary.
    final withEvents = pack.events
        .where((e) => !e.speculative)
        .map((e) => e.trackKey)
        .toSet();
    final ordered = [
      ...primary.where(withEvents.contains),
      ...primary.where((k) => !withEvents.contains(k)),
    ];

    final out = <LoreTrackInput>[];
    final seen = <String>{};
    for (final key in ordered) {
      if (!seen.add(key)) continue;
      final provided = byKey[key];
      if (provided != null) {
        out.add(provided);
        continue;
      }
      LoreTrackSummary? summary;
      for (final s in pack.trackSummaries) {
        if (s.trackKey == key) {
          summary = s;
          break;
        }
      }
      out.add(
        LoreTrackInput(
          trackKey: key,
          title: summary?.trackTitle ?? key,
          index: summary?.trackIndex ?? out.length,
        ),
      );
    }
    if (out.isEmpty && tracks.isNotEmpty) return tracks;
    return out;
  }

  Future<_TrackPassResult> _generateSecretsTrackPass({
    required Work work,
    required LoreTrackInput track,
    required List<LoreCharacter> characters,
    required Map<String, Map<String, dynamic>> carryState,
    required Iterable<LoreTimelineEvent> existingTrackEvents,
    required String languageCode,
    CancelToken? cancelToken,
    String priorContextBrief = '',
    LoreTrackPartialCallback? onTrackPartial,
  }) async {
    _throwIfCancelled(cancelToken);
    final hasSubs = track.hasSubtitles;
    final existingBrief = existingTrackEvents
        .take(12)
        .map((e) => {
              'atMs': e.atMs,
              'title': e.title,
              'deltas': e.deltas.map((d) => d.key).toList(),
            })
        .toList();
    final priorBlock = priorContextBrief.isEmpty
        ? ''
        : 'Prior context:\n$priorContextBrief\n';
    final streaming = _settings.llmStreamingEnabled;

    final user = streaming
        ? '''
Fill SPECULATIVE secret NSFW param changes for ONE track as timeline events.
These are inferred / fantasy fills — every event MUST have speculative=true.
Do NOT rewrite synopsis or non-secret story beats.
Modules (emit only changed keys): body, fluids, fertility, risk, toys, kink.
Baselines already seeded — do not dump the full key catalog.
Emit NDJSON — one JSON object per line (no array, no markdown fences):
{"type":"event","id":"s1","trackKey":"${track.trackKey}","atMs":30000,"endMs":45000,"kind":"body|fluids|clothing|paramChange|other","title":"...","detail":"...","characterId":"c1","deltas":[{"key":"wetness","from":0,"to":40}],"speculative":true,"confidence":0.4}
{"type":"carry","carryUpdates":{"c1":{"wetness":40}}}
Rules:
- 2–8 event lines spanning the track; use endMs for ramps (numeric lerp).
- Align roughly with existing story cues when present: ${jsonEncode(existingBrief)}
$priorBlock
- Carry-in: ${jsonEncode(carryState)}
- Characters: ${jsonEncode(characters.map((c) => {'id': c.id, 'name': c.name, 'role': c.role}).toList())}
- Work: ${work.title} (${work.sourceId})
- Track: ${track.title}
- Subtitles: ${hasSubs ? _clip(track.subtitleText!, 8000) : '(none — invent sparse speculative beats from title/summary)'}
'''
        : '''
Fill SPECULATIVE secret NSFW param changes for ONE track as timeline events.
These are inferred / fantasy fills — every event MUST have speculative=true.
Do NOT rewrite synopsis or non-secret story beats.
Modules (emit only changed keys): body, fluids, fertility, risk, toys, kink.
Baselines already seeded — do not dump the full key catalog.
Return JSON ONLY:
{
  "events": [
    {
      "id":"s1","trackKey":"${track.trackKey}","atMs":30000,"endMs":45000,
      "kind":"body|fluids|clothing|paramChange|other",
      "title":"...","detail":"...","characterId":"c1",
      "deltas":[{"key":"wetness","from":0,"to":40}],
      "speculative":true,"confidence":0.4
    }
  ],
  "carryUpdates": {"c1": {"wetness": 40}}
}
Rules:
- 2–8 events spanning the track; use endMs for ramps (numeric lerp).
- Align roughly with existing story cues when present: ${jsonEncode(existingBrief)}
$priorBlock
- Carry-in: ${jsonEncode(carryState)}
- Characters: ${jsonEncode(characters.map((c) => {'id': c.id, 'name': c.name, 'role': c.role}).toList())}
- Work: ${work.title} (${work.sourceId})
- Track: ${track.title}
- Subtitles: ${hasSubs ? _clip(track.subtitleText!, 8000) : '(none — invent sparse speculative beats from title/summary)'}
''';

    return _withSoftTrackRetries(
      trackKey: track.trackKey,
      run: () async {
        final messages = [
          {
            'role': 'system',
            'content': _systemPrompt(languageCode, streamingNdjson: streaming),
          },
          {'role': 'user', 'content': user},
        ];
        if (streaming) {
          return _collectStreamedTrackPass(
            messages: messages,
            temperature: 0.45,
            track: track,
            hasSubs: hasSubs,
            cancelToken: cancelToken,
            onTrackPartial: onTrackPartial,
            forceSpeculative: true,
            idPrefix: 's',
            requireSummary: false,
          );
        }

        final raw = await _llm.chatCompletion(
          messages: messages,
          temperature: 0.45,
          modelSlot: LlmModelSlot.lite,
        );
        final map = LoreJsonUtils.parseObject(raw) ?? {};
        final events = (map['events'] as List?)
                ?.whereType<Map>()
                .map((e) {
                  final m = Map<String, dynamic>.from(e);
                  m['trackKey'] = track.trackKey;
                  m['id'] = m['id'] ?? _newId('s');
                  m['speculative'] = true;
                  return LoreTimelineEvent.fromJson(m);
                })
                .toList() ??
            const <LoreTimelineEvent>[];

        return _TrackPassResult(
          summary: LoreTrackSummary(
            trackKey: track.trackKey,
            trackTitle: track.title,
            trackIndex: track.index,
            summary: '',
            hasSubtitles: hasSubs,
          ),
          events: events,
          carryUpdates: _carryUpdatesFromRaw(map['carryUpdates']),
        );
      },
      onExhausted: () => _TrackPassResult(
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
      ),
    );
  }

  // --- pipeline internals ---

  String _systemPrompt(String lang, {bool streamingNdjson = false}) {
    final format = streamingNdjson
        ? '''
Emit NDJSON only: one complete JSON object per line. No markdown fences, no array wrapper.
Each line must include "type": "summary" | "event" | "carry".
Typical order: one summary line, then event lines, then optional carry line.
'''
        : 'Output ONLY valid JSON (no markdown).\n';
    return '''
You are a careful ASMR work-lore analyst for Lizunemu.
$format
Write prose fields in language code "$lang".
Prefer evidence from subtitles when present. Sparse params: omit unknown values.
Never invent VA links as confirmed — set vaLinkProposed true and vaLinkConfirmed false.
Subtitle cue text provided in prompts is ALREADY in language "$lang".
evidenceQuote MUST be copied from those provided subtitle lines (same language).
Do NOT quote Japanese/Chinese/original-language lines, and do not invent bilingual quotes.
''';
  }
  Future<_CastPassResult> _generateCastAndSynopsis({
    required Work work,
    required List<LoreTrackInput> tracks,
    required List<LoreSeedNote> seedNotes,
    required String languageCode,
    CancelToken? cancelToken,
    List<LoreCharacter>? existingCharacters,
    bool slimOntology = false,
  }) async {
    _throwIfCancelled(cancelToken);
    final richMeta = (work.tags?.length ?? 0) >= 3 || (work.vas?.isNotEmpty ?? false);
    final sampleTake = richMeta ? 2 : 3;
    final sampleChars = richMeta ? 1500 : 2500;
    final sampleSubs = tracks
        .where((t) => t.hasSubtitles)
        .take(sampleTake)
        .map((t) => {
              'track': t.title,
              'excerpt': _clip(t.subtitleText!, sampleChars),
            })
        .toList();

    final vas = _vaSummaries(work.vas);
    final ontologyHint = slimOntology
        ? 'Use sparse non-explicit starter params only (arousal/affection/clothing/location…). '
            'Secret body/fluids/fertility/risk/toys baselines are seeded locally afterward.'
        : 'Use ontology starter keys when evidence supports them (sparse — omit unknowns). '
            'Modules: ${LoreOntology.allModules.join(', ')}. '
            'Starter keys: ${LoreOntology.starterParams(includeExplicit: false).map((p) => '${p.key}(${p.module})').join(', ')}.';

    final existingSlim = existingCharacters
        ?.map((c) => {
              'id': c.id,
              'name': c.name,
              'role': c.role,
              'isFocusDefault': c.isFocusDefault,
            })
        .toList();

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
Pin HUD defaults on arousal/horny/pleasure/affection/corruption/clothing_state/location when relevant.
$ontologyHint

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
${existingSlim != null ? 'Existing characters to refine: ${jsonEncode(existingSlim)}' : ''}
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
    bool includeSecrets = false,
    String priorContextBrief = '',
    bool isFirstTrack = true,
    LoreTrackPartialCallback? onTrackPartial,
  }) async {
    _throwIfCancelled(cancelToken);
    final hasSubs = track.hasSubtitles;
    final secretsBlock = includeSecrets
        ? '''
Also emit speculative=true events for secret modules (body, fluids, fertility, risk, toys, kink) when the scene implies them.
- Evidence-grounded story beats → speculative:false + evidenceQuote from subtitles.
- Inferred secret fills → speculative:true (quote optional).
- Do NOT dump every ontology key — only emit deltas you change. Baselines already seeded.
- 2–8 secret/story events total for this track is enough.
'''
        : '''
You MAY emit speculative=true events for body/fluids/fertility/risk/toys when clearly implied.
''';
    final charsSlim = characters
        .map((c) => {'id': c.id, 'name': c.name, 'role': c.role})
        .toList();
    final seedBlock = isFirstTrack && seedNotes.isNotEmpty
        ? 'Seed notes: ${jsonEncode(seedNotes.map((e) => e.toJson()).toList())}\n'
        : '';
    final priorBlock = priorContextBrief.isEmpty
        ? ''
        : 'Prior context:\n$priorContextBrief\n'
            'Continue state; do not reset clothing/relationship/body unless this track changes them. '
            'carryUpdates = end-of-this-track only.\n';
    final streaming = _settings.llmStreamingEnabled;

    final user = streaming
        ? '''
Analyze ONE track. Emit NDJSON — one JSON object per line (no array, no markdown fences), in order:
{"type":"summary","trackKey":"${track.trackKey}","trackTitle":"${track.title}","trackIndex":${track.index},"summary":"...","lowConfidence":${!hasSubs},"hasSubtitles":$hasSubs}
{"type":"event","id":"e1","trackKey":"${track.trackKey}","atMs":12000,"endMs":18000,"kind":"paramChange|beat|clothing|body|relationship|location|addition|other","title":"...","detail":"...","characterId":"c1","deltas":[{"key":"arousal","from":10,"to":40}],"evidenceQuote":"...","evidenceStartMs":11000,"evidenceEndMs":15000,"speculative":false,"confidence":0.8}
{"type":"carry","carryUpdates":{"c1":{"arousal":40,"clothing_state":"..."}}}
Use endMs so numeric gauges ramp from→to across the span (video-editor clip). Status/enum/text deltas hold from until endMs then snap to to.
$secretsBlock
If no subtitles, write a thin metadata-based summary, lowConfidence true, few or no events.
evidenceQuote must copy from the Subtitles block below (already in "$languageCode") — never original JP/CN script.
$priorBlock
Carry-in state: ${jsonEncode(carryState)}
Characters: ${jsonEncode(charsSlim)}
$seedBlock
Work: ${work.title} (${work.sourceId})
Track: ${track.title}
Subtitles (language $languageCode):
${hasSubs ? _clip(track.subtitleText!, 12000) : '(none)'}
'''
        : '''
Analyze ONE track. Return JSON:
{
  "summary": {"trackKey":"${track.trackKey}","trackTitle":"${track.title}","trackIndex":${track.index},"summary":"...","lowConfidence":${!hasSubs},"hasSubtitles":$hasSubs},
  "events": [
    {
      "id":"e1","trackKey":"${track.trackKey}","atMs":12000,"endMs":18000,"kind":"paramChange|beat|clothing|body|relationship|location|addition|other",
      "title":"...","detail":"...","characterId":"c1",
      "deltas":[{"key":"arousal","from":10,"to":40}],
      "evidenceQuote":"...","evidenceStartMs":11000,"evidenceEndMs":15000,
      "speculative":false,"confidence":0.8
    }
  ],
  "carryUpdates": {"c1": {"arousal": 40, "clothing_state": "..."}}
}
Use endMs so numeric gauges ramp from→to across the span (video-editor clip). Status/enum/text deltas hold from until endMs then snap to to.
$secretsBlock
If no subtitles, write a thin metadata-based summary, lowConfidence true, few or no events.
evidenceQuote must copy from the Subtitles block below (already in "$languageCode") — never original JP/CN script.
$priorBlock
Carry-in state: ${jsonEncode(carryState)}
Characters: ${jsonEncode(charsSlim)}
$seedBlock
Work: ${work.title} (${work.sourceId})
Track: ${track.title}
Subtitles (language $languageCode):
${hasSubs ? _clip(track.subtitleText!, 12000) : '(none)'}
''';

    return _withSoftTrackRetries(
      trackKey: track.trackKey,
      run: () async {
        final messages = [
          {
            'role': 'system',
            'content': _systemPrompt(languageCode, streamingNdjson: streaming),
          },
          {'role': 'user', 'content': user},
        ];
        if (streaming) {
          return _collectStreamedTrackPass(
            messages: messages,
            temperature: 0.3,
            track: track,
            hasSubs: hasSubs,
            cancelToken: cancelToken,
            onTrackPartial: onTrackPartial,
            forceSpeculative: false,
            idPrefix: 'e',
            requireSummary: true,
          );
        }

        final raw = await _llm.chatCompletion(
          messages: messages,
          temperature: 0.3,
          modelSlot: LlmModelSlot.lite,
        );
        final map = LoreJsonUtils.parseObject(raw) ?? {};
        final summaryJson = map['summary'];
        final summary = summaryJson is Map
            ? LoreTrackSummary.fromJson(
                Map<String, dynamic>.from(summaryJson),
              )
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

        return _TrackPassResult(
          summary: summary.copyWith(
            trackKey: track.trackKey,
            trackTitle: track.title,
            trackIndex: track.index,
            hasSubtitles: hasSubs,
            lowConfidence: summary.lowConfidence || !hasSubs,
          ),
          events: events,
          carryUpdates: _carryUpdatesFromRaw(map['carryUpdates']),
        );
      },
      onExhausted: () => _TrackPassResult(
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
      ),
    );
  }

  Future<_TrackPassResult> _collectStreamedTrackPass({
    required List<Map<String, String>> messages,
    required double temperature,
    required LoreTrackInput track,
    required bool hasSubs,
    required CancelToken? cancelToken,
    required LoreTrackPartialCallback? onTrackPartial,
    required bool forceSpeculative,
    required String idPrefix,
    required bool requireSummary,
  }) async {
    final parser = StreamingLoreTrackParser();
    LoreTrackSummary? summary;
    final events = <LoreTimelineEvent>[];
    var carryUpdates = <String, Map<String, dynamic>>{};
    String? lastEventTitle;

    void emitPartial() {
      onTrackPartial?.call(
        LoreTrackPartial(
          summary: summary?.summary,
          eventCount: events.length,
          lastEventTitle: lastEventTitle,
        ),
      );
    }

    void handleItems(List<LoreTrackStreamItem> items) {
      for (final item in items) {
        switch (item) {
          case LoreTrackStreamSummary(:final json):
            final merged = Map<String, dynamic>.from(json)
              ..remove('type')
              ..putIfAbsent('trackKey', () => track.trackKey)
              ..putIfAbsent('trackTitle', () => track.title)
              ..putIfAbsent('trackIndex', () => track.index)
              ..putIfAbsent('hasSubtitles', () => hasSubs);
            summary = LoreTrackSummary.fromJson(merged).copyWith(
              trackKey: track.trackKey,
              trackTitle: track.title,
              trackIndex: track.index,
              hasSubtitles: hasSubs,
              lowConfidence:
                  (merged['lowConfidence'] as bool? ?? false) || !hasSubs,
            );
            emitPartial();
          case LoreTrackStreamEvent(:final json):
            final event = loreEventFromStreamMap(
              json,
              trackKey: track.trackKey,
              newId: () => _newId(idPrefix),
              forceSpeculative: forceSpeculative,
            );
            events.add(event);
            lastEventTitle = event.title;
            emitPartial();
          case LoreTrackStreamCarry(carryUpdates: final incoming):
            final parsed = _carryUpdatesFromRaw(incoming);
            for (final e in parsed.entries) {
              carryUpdates[e.key] = {
                ...?carryUpdates[e.key],
                ...e.value,
              };
            }
        }
      }
    }

    await for (final chunk in _llm.chatCompletionStream(
      messages: messages,
      temperature: temperature,
      modelSlot: LlmModelSlot.lite,
    )) {
      _throwIfCancelled(cancelToken);
      handleItems(parser.feed(chunk));
    }
    handleItems(parser.flush());

    if (requireSummary && summary == null && events.isEmpty) {
      throw const LlmTranslationException(
        LlmTranslationErrorType.invalidResponse,
        'empty lore track stream',
      );
    }

    return _TrackPassResult(
      summary: (summary ??
              LoreTrackSummary(
                trackKey: track.trackKey,
                trackTitle: track.title,
                trackIndex: track.index,
                summary: hasSubs ? '' : 'No subtitles; thin lore.',
                lowConfidence: !hasSubs,
                hasSubtitles: hasSubs,
              ))
          .copyWith(
        trackKey: track.trackKey,
        trackTitle: track.title,
        trackIndex: track.index,
        hasSubtitles: hasSubs,
        lowConfidence: (summary?.lowConfidence ?? !hasSubs) || !hasSubs,
      ),
      events: events,
      carryUpdates: carryUpdates,
    );
  }

  Map<String, Map<String, dynamic>> _carryUpdatesFromRaw(dynamic carryRaw) {
    final carryUpdates = <String, Map<String, dynamic>>{};
    if (carryRaw is Map) {
      for (final entry in carryRaw.entries) {
        if (entry.value is Map) {
          carryUpdates[entry.key.toString()] =
              Map<String, dynamic>.from(entry.value as Map);
        }
      }
    }
    return carryUpdates;
  }

  Future<T> _withSoftTrackRetries<T>({
    required String trackKey,
    required Future<T> Function() run,
    required T Function() onExhausted,
  }) async {
    final maxAttempts = max(1, _settings.llmTranslateRetryCount);
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await run();
      } on LlmTranslationException catch (e) {
        if (loreIsHardLlmError(e)) rethrow;
        AppLogger.warning(
          'Lore soft fail $trackKey attempt $attempt/$maxAttempts: ${e.type}',
        );
        if (attempt >= maxAttempts) break;
        await Future<void>.delayed(loreSoftRetryDelay(attempt));
      } catch (e, st) {
        AppLogger.error(
          'Lore soft fail $trackKey attempt $attempt/$maxAttempts',
          e,
          st,
        );
        if (attempt >= maxAttempts) break;
        await Future<void>.delayed(loreSoftRetryDelay(attempt));
      }
    }
    AppLogger.error('Lore track exhausted soft retries: $trackKey');
    return onExhausted();
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
    final charsSlim = characters
        .map((c) => {
              'id': c.id,
              'name': c.name,
              'role': c.role,
              'isFocusDefault': c.isFocusDefault,
              'params': c.params
                  .where((p) => p.hudPinned || p.value != null)
                  .take(12)
                  .map((p) => {
                        'key': p.key,
                        'value': p.value,
                        'hudPinned': p.hudPinned,
                      })
                  .toList(),
            })
        .toList();
    final user = '''
Reconcile lore consistency. Fix name drift, ensure focus character exists, polish synopsis.
Return JSON: {"synopsis":"...","characters":[...same schema as cast, keep ids...]}
Current synopsis: $synopsis
Characters (slim): ${jsonEncode(charsSlim)}
Track summaries: ${jsonEncode(summaries.map((e) => {
          'trackKey': e.trackKey,
          'title': e.trackTitle,
          'summary': LoreTrackContextBrief.clip(e.summary, 300),
          'lowConfidence': e.lowConfidence,
        }).toList())}
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
