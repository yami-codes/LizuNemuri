import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:lizunemu/core/lore/ccv2_export_service.dart';
import 'package:lizunemu/core/lore/global_character_service.dart';
import 'package:lizunemu/core/lore/lore_pack_io.dart';
import 'package:lizunemu/core/lore/models/global_character.dart';
import 'package:lizunemu/core/lore/models/lore_character.dart';
import 'package:lizunemu/core/lore/models/lore_content_level.dart';
import 'package:lizunemu/core/lore/models/lore_ontology.dart';
import 'package:lizunemu/core/lore/models/lore_param.dart';
import 'package:lizunemu/core/lore/models/work_lore_pack.dart';
import 'package:lizunemu/core/lore/work_lore_service.dart';
import 'package:lizunemu/core/subtitle/subtitle_loader.dart';
import 'package:lizunemu/data/models/files/child.dart';
import 'package:lizunemu/data/models/files/files.dart';
import 'package:lizunemu/data/models/works/work.dart';
import 'package:lizunemu/data/repositories/llm_api_key_repository.dart';
import 'package:lizunemu/utils/logger.dart';
import 'package:universal_io/io.dart';

class WorkLoreViewModel extends ChangeNotifier {
  final Work work;
  final WorkLoreService _lore;
  final Ccv2ExportService _ccv2;
  final GlobalCharacterService _global;
  final SubtitleLoader _subtitleLoader;
  final LlmApiKeyRepository _apiKeyRepo;

  WorkLorePack? _pack;
  bool _loading = false;
  bool _generating = false;
  String? _error;
  String _progressStage = '';
  double _progress = 0;
  CancelToken? _cancelToken;

  WorkLoreViewModel({
    required this.work,
    required WorkLoreService lore,
    required Ccv2ExportService ccv2,
    required GlobalCharacterService global,
    required SubtitleLoader subtitleLoader,
    required LlmApiKeyRepository apiKeyRepo,
  })  : _lore = lore,
        _ccv2 = ccv2,
        _global = global,
        _subtitleLoader = subtitleLoader,
        _apiKeyRepo = apiKeyRepo;

  WorkLorePack? get pack => _pack;
  bool get loading => _loading;
  bool get generating => _generating;
  bool get hasLore => _pack?.hasLore == true;
  String? get error => _error;
  String get progressStage => _progressStage;
  double get progress => _progress;

  String get workId => '${work.id ?? work.sourceId ?? ''}';

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _pack = await _lore.load(workId);
    } catch (e, st) {
      AppLogger.error('Load work lore failed', e, st);
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> hasApiKey() async {
    final key = await _apiKeyRepo.getApiKey();
    return key != null && key.trim().isNotEmpty;
  }

  Future<void> generate({
    required List<Child> audioTracks,
    Files? files,
  }) async {
    if (_generating) return;
    _generating = true;
    _error = null;
    _progress = 0;
    _progressStage = 'cast';
    _cancelToken = CancelToken();
    notifyListeners();

    try {
      final baseTracks = WorkLoreService.tracksFromChildren(audioTracks);
      final withSubs = <LoreTrackInput>[];
      for (final t in baseTracks) {
        String? text;
        if (files != null) {
          Child? audio;
          for (var i = 0; i < audioTracks.length; i++) {
            final key = WorkLoreService.tracksFromChildren([audioTracks[i]])
                .first
                .trackKey;
            if (key == t.trackKey) {
              audio = audioTracks[i];
              break;
            }
          }
          if (audio != null) {
            final sub = _subtitleLoader.findSubtitleFile(audio, files);
            final url = sub?.mediaDownloadUrl;
            if (url != null && url.isNotEmpty) {
              try {
                text = await _subtitleLoader.loadRawContent(url: url);
              } catch (e) {
                AppLogger.debug('Lore subtitle load skipped: $e');
              }
            }
          }
        }
        withSubs.add(
          LoreTrackInput(
            trackKey: t.trackKey,
            title: t.title,
            index: t.index,
            subtitleText: text,
          ),
        );
      }

      _pack = await _lore.generate(
        work: work,
        tracks: withSubs,
        seedNotes: _pack?.seedNotes ?? const [],
        onProgress: (stage, p) {
          _progressStage = stage;
          _progress = p;
          notifyListeners();
        },
        cancelToken: _cancelToken,
      );
    } on DioException catch (e) {
      if (e.type != DioExceptionType.cancel) {
        _error = e.message ?? e.toString();
      }
    } catch (e, st) {
      AppLogger.error('Generate lore failed', e, st);
      _error = e.toString();
    } finally {
      _generating = false;
      _cancelToken = null;
      notifyListeners();
    }
  }

  void cancelGenerate() {
    _cancelToken?.cancel('user');
  }

  Future<void> regenerate({
    required LoreRegenSection section,
    String? trackKey,
    String? characterId,
    List<Child> audioTracks = const [],
    Files? files,
  }) async {
    if (_pack == null || _generating) return;
    _generating = true;
    _error = null;
    notifyListeners();
    try {
      final tracks = WorkLoreService.tracksFromChildren(audioTracks);
      // Attach subs for track regen when possible
      final enriched = <LoreTrackInput>[];
      for (final t in tracks) {
        String? text;
        if (files != null && section == LoreRegenSection.track) {
          for (var i = 0; i < audioTracks.length; i++) {
            final key = WorkLoreService.tracksFromChildren([audioTracks[i]])
                .first
                .trackKey;
            if (key == t.trackKey) {
              final sub =
                  _subtitleLoader.findSubtitleFile(audioTracks[i], files);
              final url = sub?.mediaDownloadUrl;
              if (url != null) {
                try {
                  text = await _subtitleLoader.loadRawContent(url: url);
                } catch (_) {}
              }
              break;
            }
          }
        }
        enriched.add(LoreTrackInput(
          trackKey: t.trackKey,
          title: t.title,
          index: t.index,
          subtitleText: text,
        ));
      }

      _pack = await _lore.regenerateSection(
        work: work,
        pack: _pack!,
        section: section,
        trackKey: trackKey,
        characterId: characterId,
        tracks: enriched,
        onProgress: (stage, p) {
          _progressStage = stage;
          _progress = p;
          notifyListeners();
        },
      );
    } catch (e, st) {
      AppLogger.error('Regen lore failed', e, st);
      _error = e.toString();
    } finally {
      _generating = false;
      notifyListeners();
    }
  }

  Future<void> generateSecrets() async {
    if (_pack == null || _generating) return;
    _generating = true;
    _error = null;
    notifyListeners();
    try {
      _pack = await _lore.generateSecrets(_pack!);
    } catch (e, st) {
      AppLogger.error('Generate secrets failed', e, st);
      _error = e.toString();
    } finally {
      _generating = false;
      notifyListeners();
    }
  }

  Future<void> savePack(WorkLorePack pack) async {
    _pack = await _lore.updatePack(pack);
    notifyListeners();
  }

  Future<void> setFocusCharacter(String id) async {
    if (_pack == null) return;
    await savePack(_pack!.copyWith(focusCharacterId: id));
  }

  Future<void> setExplicitRevealed(bool revealed) async {
    if (_pack == null) return;
    await savePack(_pack!.copyWith(explicitRevealed: revealed));
  }

  Future<void> setContentLevel(LoreContentLevel level) async {
    if (_pack == null) return;
    await savePack(_pack!.copyWith(contentLevel: level));
  }

  Future<void> updateCharacter(LoreCharacter character) async {
    if (_pack == null) return;
    final chars = _pack!.characters
        .map((c) => c.id == character.id ? character : c)
        .toList();
    await savePack(_pack!.copyWith(characters: chars));
  }

  Future<void> confirmVaLink(String characterId, {required bool confirm}) async {
    final c = _pack?.characterById(characterId);
    if (c == null) return;
    await updateCharacter(
      c.copyWith(vaLinkConfirmed: confirm, vaLinkProposed: !confirm ? false : c.vaLinkProposed),
    );
  }

  Future<void> setHudPins(String characterId, Set<String> pinnedKeys) async {
    final c = _pack?.characterById(characterId);
    if (c == null) return;
    final params = c.params
        .map((p) => p.copyWith(hudPinned: pinnedKeys.contains(p.key)))
        .toList();
    await updateCharacter(c.copyWith(params: params));
  }

  Future<void> upsertSeedNote(LoreSeedNote note) async {
    if (_pack == null) return;
    final notes = _pack!.seedNotes.where((n) => n.id != note.id).toList()
      ..add(note);
    await savePack(_pack!.copyWith(seedNotes: notes));
  }

  Future<void> deleteSeedNote(String id) async {
    if (_pack == null) return;
    await savePack(
      _pack!.copyWith(
        seedNotes: _pack!.seedNotes.where((n) => n.id != id).toList(),
      ),
    );
  }

  Future<String> exportPackJson() async {
    if (_pack == null) throw StateError('no pack');
    return LorePackIo.exportPackJson(_pack!);
  }

  Future<void> importPackJson(String raw, {bool merge = true}) async {
    final incoming = LorePackIo.importPackJson(raw);
    final next = _pack == null || !merge
        ? incoming.copyWith(workId: workId)
        : LorePackIo.mergePacks(_pack!, incoming.copyWith(workId: workId));
    await savePack(next.withRecomputedHash());
  }

  Future<String> exportCcv2Json(
    LoreCharacter character, {
    bool includeSpeculative = false,
    bool forceRewrite = false,
  }) async {
    if (_pack == null) throw StateError('no pack');
    return _ccv2.exportCharacterCardJson(
      pack: _pack!,
      character: character,
      includeSpeculative: includeSpeculative,
      forceRewrite: forceRewrite,
    );
  }

  Future<Uint8List> exportCcv2BatchZip({
    bool includeSpeculative = false,
  }) async {
    if (_pack == null) throw StateError('no pack');
    return _ccv2.exportBatchZip(
      pack: _pack!,
      includeSpeculative: includeSpeculative,
    );
  }

  Future<({GlobalCharacter global, WorkLorePack pack})> promoteCharacter({
    required String localCharacterId,
    String? existingGlobalId,
    List<LoreFieldMergeChoice>? choices,
  }) async {
    if (_pack == null) throw StateError('no pack');
    final result = await _global.promote(
      pack: _pack!,
      localCharacterId: localCharacterId,
      existingGlobalId: existingGlobalId,
      choices: choices,
    );
    _pack = result.pack;
    notifyListeners();
    return result;
  }

  Future<void> deleteLore() async {
    await _lore.delete(workId);
    _pack = null;
    notifyListeners();
  }

  Future<File> writeExportToTemp(String filename, String contents) async {
    final dir = Directory.systemTemp;
    final file = File('${dir.path}${Platform.pathSeparator}$filename');
    await file.writeAsString(contents, flush: true);
    return file;
  }

  Future<File> writeBytesToTemp(String filename, Uint8List bytes) async {
    final dir = Directory.systemTemp;
    final file = File('${dir.path}${Platform.pathSeparator}$filename');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Visible params for UI given contentLevel + reveal.
  static List<LoreParam> visibleParams(
    LoreCharacter character,
    WorkLorePack pack,
  ) {
    final showExplicit =
        pack.explicitRevealed || pack.contentLevel.showsExplicitBlocks;
    if (showExplicit) return character.params;
    return character.params
        .where((p) => !LoreOntology.explicitModules.contains(p.module))
        .toList();
  }
}
