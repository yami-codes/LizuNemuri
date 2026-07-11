import 'package:lizunemu/core/lore/models/global_character.dart';
import 'package:lizunemu/core/lore/models/lore_character.dart';
import 'package:lizunemu/core/lore/models/work_lore_pack.dart';
import 'package:lizunemu/core/lore/storage/global_character_repository.dart';
import 'package:lizunemu/core/lore/work_lore_service.dart';

/// Promote / link work-local characters to the global bible with field merges.
class GlobalCharacterService {
  final GlobalCharacterRepository _repo;
  final WorkLoreService _loreService;

  GlobalCharacterService({
    required GlobalCharacterRepository repo,
    required WorkLoreService loreService,
  })  : _repo = repo,
        _loreService = loreService;

  Future<List<GlobalCharacter>> listAll() => _repo.listAll();

  Future<List<GlobalCharacter>> search(String query) =>
      _repo.searchByName(query);

  Future<GlobalCharacter?> get(String id) => _repo.get(id);

  Future<void> delete(String id) => _repo.delete(id);

  static List<LoreFieldMergeChoice> defaultMergeChoices({
    required LoreCharacter local,
    GlobalCharacter? global,
  }) {
    return [
      LoreFieldMergeChoice(
        fieldKey: 'name',
        localValue: local.name,
        globalValue: global?.name,
        preferLocal: true,
      ),
      LoreFieldMergeChoice(
        fieldKey: 'appearance',
        localValue: local.appearance,
        globalValue: global?.appearance,
        preferLocal: true,
      ),
      LoreFieldMergeChoice(
        fieldKey: 'personality',
        localValue: local.personality,
        globalValue: global?.personality,
        preferLocal: true,
      ),
      LoreFieldMergeChoice(
        fieldKey: 'notes',
        localValue: local.notes,
        globalValue: global?.notes,
        preferLocal: true,
      ),
      LoreFieldMergeChoice(
        fieldKey: 'kinks',
        localValue: local.kinks,
        globalValue: global?.kinks,
        preferLocal: true,
      ),
      LoreFieldMergeChoice(
        fieldKey: 'params',
        localValue: local.params,
        globalValue: global?.baselineParams,
        preferLocal: true,
      ),
      LoreFieldMergeChoice(
        fieldKey: 'aliases',
        localValue: local.aliases,
        globalValue: global?.aliases,
        preferLocal: true,
      ),
    ];
  }

  Future<({GlobalCharacter global, WorkLorePack pack})> promote({
    required WorkLorePack pack,
    required String localCharacterId,
    String? existingGlobalId,
    List<LoreFieldMergeChoice>? choices,
  }) async {
    final local = pack.characterById(localCharacterId);
    if (local == null) {
      throw StateError('local character not found: $localCharacterId');
    }

    GlobalCharacter? existing;
    if (existingGlobalId != null) {
      existing = await _repo.get(existingGlobalId);
    }

    final merge =
        choices ?? defaultMergeChoices(local: local, global: existing);
    final merged = _applyMerge(
      local: local,
      global: existing,
      choices: merge,
      workId: pack.workId,
      globalId: existing?.id ??
          'g_${DateTime.now().millisecondsSinceEpoch}_$localCharacterId',
    );

    await _repo.upsert(merged);

    final updatedLocal = local.copyWith(globalCharacterId: merged.id);
    final characters = pack.characters
        .map((c) => c.id == localCharacterId ? updatedLocal : c)
        .toList();
    final next = await _loreService.updatePack(
      pack.copyWith(characters: characters),
    );
    return (global: merged, pack: next);
  }

  Future<WorkLorePack> linkExisting({
    required WorkLorePack pack,
    required String localCharacterId,
    required String globalId,
  }) async {
    final global = await _repo.get(globalId);
    if (global == null) {
      throw StateError('global character not found: $globalId');
    }
    final local = pack.characterById(localCharacterId);
    if (local == null) {
      throw StateError('local character not found: $localCharacterId');
    }

    final linkedWorks = {
      ...global.linkedWorkIds,
      pack.workId,
    }.toList();
    await _repo.upsert(global.copyWith(
      linkedWorkIds: linkedWorks,
      updatedAt: DateTime.now().toUtc(),
    ));

    final characters = pack.characters
        .map(
          (c) => c.id == localCharacterId
              ? c.copyWith(globalCharacterId: globalId)
              : c,
        )
        .toList();
    return _loreService.updatePack(pack.copyWith(characters: characters));
  }

  GlobalCharacter _applyMerge({
    required LoreCharacter local,
    required GlobalCharacter? global,
    required List<LoreFieldMergeChoice> choices,
    required String workId,
    required String globalId,
  }) {
    bool preferLocal(String key) {
      for (final c in choices) {
        if (c.fieldKey == key) return c.preferLocal;
      }
      return true;
    }

    T pick<T>(String key, T localVal, T? globalVal) {
      if (preferLocal(key)) return localVal;
      return globalVal ?? localVal;
    }

    final linked = {
      ...?global?.linkedWorkIds,
      workId,
    }.toList();

    return GlobalCharacter(
      id: globalId,
      name: pick('name', local.name, global?.name),
      aliases: pick('aliases', local.aliases, global?.aliases),
      appearance: pick('appearance', local.appearance, global?.appearance),
      personality: pick('personality', local.personality, global?.personality),
      kinks: pick('kinks', local.kinks, global?.kinks),
      baselineParams: pick('params', local.params, global?.baselineParams),
      notes: pick('notes', local.notes, global?.notes),
      updatedAt: DateTime.now().toUtc(),
      linkedWorkIds: linked,
    );
  }
}
