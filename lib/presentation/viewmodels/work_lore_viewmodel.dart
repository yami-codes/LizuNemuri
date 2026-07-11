import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:lizunemu/core/download/download_service.dart';
import 'package:lizunemu/core/lore/ccv2_export_service.dart';
import 'package:lizunemu/core/lore/global_character_service.dart';
import 'package:lizunemu/core/lore/lore_json_utils.dart';
import 'package:lizunemu/core/lore/lore_pack_io.dart';
import 'package:lizunemu/core/lore/lore_subtitle_resolver.dart';
import 'package:lizunemu/core/lore/models/global_character.dart';
import 'package:lizunemu/core/lore/models/lore_character.dart';
import 'package:lizunemu/core/lore/models/lore_content_level.dart';
import 'package:lizunemu/core/lore/models/lore_ontology.dart';
import 'package:lizunemu/core/lore/models/lore_param.dart';
import 'package:lizunemu/core/lore/models/work_lore_pack.dart';
import 'package:lizunemu/core/lore/work_lore_service.dart';
import 'package:lizunemu/core/media/work_media_url_refresher.dart';
import 'package:lizunemu/core/subtitle/subtitle_import_service.dart';
import 'package:lizunemu/core/subtitle/subtitle_loader.dart';
import 'package:lizunemu/data/models/files/files.dart';
import 'package:lizunemu/data/models/works/work.dart';
import 'package:lizunemu/data/repositories/llm_api_key_repository.dart';
import 'package:lizunemu/data/services/exceptions/llm_translation_exception.dart';
import 'package:lizunemu/presentation/viewmodels/detail_viewmodel.dart';
import 'package:lizunemu/utils/logger.dart';
import 'package:universal_io/io.dart';

class WorkLoreViewModel extends ChangeNotifier {
  final Work work;
  final WorkLoreService _lore;
  final Ccv2ExportService _ccv2;
  final GlobalCharacterService _global;
  final LoreSubtitleResolver _subtitleResolver;
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
    required LoreSubtitleResolver subtitleResolver,
    required LlmApiKeyRepository apiKeyRepo,
  })  : _lore = lore,
        _ccv2 = ccv2,
        _global = global,
        _subtitleResolver = subtitleResolver,
        _apiKeyRepo = apiKeyRepo;

  /// Convenience constructor wiring GetIt-style deps used by DetailScreen.
  factory WorkLoreViewModel.create({
    required Work work,
    required WorkLoreService lore,
    required Ccv2ExportService ccv2,
    required GlobalCharacterService global,
    required SubtitleLoader subtitleLoader,
    required DownloadService downloads,
    required WorkMediaUrlRefresher urlRefresher,
    required SubtitleImportService imports,
    required LlmApiKeyRepository apiKeyRepo,
  }) {
    return WorkLoreViewModel(
      work: work,
      lore: lore,
      ccv2: ccv2,
      global: global,
      subtitleResolver: LoreSubtitleResolver(
        loader: subtitleLoader,
        downloads: downloads,
        urlRefresher: urlRefresher,
        imports: imports,
      ),
      apiKeyRepo: apiKeyRepo,
    );
  }

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
    required List<DownloadPair> pairs,
    Files? files,
    bool includeSecrets = true,
  }) async {
    if (_generating) return;
    _generating = true;
    _error = null;
    _progress = 0;
    _progressStage = 'cast';
    _cancelToken = CancelToken();
    notifyListeners();

    try {
      final workId = '${work.id ?? work.sourceId ?? ''}';
      final withSubs = <LoreTrackInput>[];
      for (var i = 0; i < pairs.length; i++) {
        final pair = pairs[i];
        final audio = pair.audio;
        final trackKey = LoreJsonUtils.trackKeyFor(
          index: i,
          hash: audio.hash,
          mediaDownloadUrl: audio.mediaDownloadUrl,
          title: audio.title,
        );
        final text = await _subtitleResolver.resolveText(
          workId: workId,
          audio: audio,
          matchedSubtitle: pair.subtitle,
          files: files,
        );
        withSubs.add(
          LoreTrackInput(
            trackKey: trackKey,
            title: audio.title ?? 'Track ${i + 1}',
            index: i,
            subtitleText: text,
          ),
        );
      }

      final withText = withSubs.where((t) => t.hasSubtitles).length;
      AppLogger.debug(
        'Lore generate: $withText/${withSubs.length} tracks have subtitle text'
        '${includeSecrets ? ' (+secrets)' : ''}',
      );

      _pack = await _lore.generate(
        work: work,
        tracks: withSubs,
        seedNotes: _pack?.seedNotes ?? const [],
        includeSecrets: includeSecrets,
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
    } on LlmTranslationException catch (e) {
      _error = e.userMessage;
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
    List<DownloadPair> pairs = const [],
    Files? files,
  }) async {
    if (_pack == null || _generating) return;
    _generating = true;
    _error = null;
    notifyListeners();
    try {
      final workId = '${work.id ?? work.sourceId ?? ''}';
      final enriched = <LoreTrackInput>[];
      for (var i = 0; i < pairs.length; i++) {
        final pair = pairs[i];
        final audio = pair.audio;
        final key = LoreJsonUtils.trackKeyFor(
          index: i,
          hash: audio.hash,
          mediaDownloadUrl: audio.mediaDownloadUrl,
          title: audio.title,
        );
        String? text;
        if (section == LoreRegenSection.track &&
            (trackKey == null || trackKey == key)) {
          text = await _subtitleResolver.resolveText(
            workId: workId,
            audio: audio,
            matchedSubtitle: pair.subtitle,
            files: files,
          );
        }
        enriched.add(
          LoreTrackInput(
            trackKey: key,
            title: audio.title ?? 'Track ${i + 1}',
            index: i,
            subtitleText: text,
          ),
        );
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
    } on LlmTranslationException catch (e) {
      _error = e.userMessage;
    } catch (e, st) {
      AppLogger.error('Regen lore failed', e, st);
      _error = e.toString();
    } finally {
      _generating = false;
      notifyListeners();
    }
  }

  Future<void> generateSecrets({
    List<DownloadPair> pairs = const [],
    Files? files,
  }) async {
    if (_pack == null || _generating) return;
    _generating = true;
    _error = null;
    _progress = 0;
    _progressStage = 'secrets:seed';
    _cancelToken = CancelToken();
    notifyListeners();
    try {
      final workId = '${work.id ?? work.sourceId ?? ''}';
      final enriched = <LoreTrackInput>[];
      for (var i = 0; i < pairs.length; i++) {
        final pair = pairs[i];
        final audio = pair.audio;
        final trackKey = LoreJsonUtils.trackKeyFor(
          index: i,
          hash: audio.hash,
          mediaDownloadUrl: audio.mediaDownloadUrl,
          title: audio.title,
        );
        final text = await _subtitleResolver.resolveText(
          workId: workId,
          audio: audio,
          matchedSubtitle: pair.subtitle,
          files: files,
        );
        enriched.add(
          LoreTrackInput(
            trackKey: trackKey,
            title: audio.title ?? 'Track ${i + 1}',
            index: i,
            subtitleText: text,
          ),
        );
      }

      _pack = await _lore.generateSecrets(
        _pack!,
        work: work,
        tracks: enriched,
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
    } on LlmTranslationException catch (e) {
      _error = e.userMessage;
    } catch (e, st) {
      AppLogger.error('Generate secrets failed', e, st);
      _error = e.toString();
    } finally {
      _generating = false;
      _cancelToken = null;
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
