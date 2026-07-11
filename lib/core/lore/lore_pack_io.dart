import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:lizunemu/core/lore/models/work_lore_pack.dart';
import 'package:lizunemu/core/lore/lore_json_utils.dart';
import 'package:universal_io/io.dart';

/// Lizunemu lore pack export/import (JSON + optional zip of many packs).
class LorePackIo {
  static const String packFileExtension = 'lizulore.json';

  static Map<String, dynamic> exportPackMap(WorkLorePack pack) {
    final hashed = pack.withRecomputedHash();
    return {
      'format': 'lizunemu_lore_pack',
      'schema_version': WorkLorePack.currentSchemaVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'pack': hashed.toJson(),
    };
  }

  static String exportPackJson(WorkLorePack pack, {bool pretty = true}) {
    final map = exportPackMap(pack);
    return pretty
        ? const JsonEncoder.withIndent('  ').convert(map)
        : jsonEncode(map);
  }

  static WorkLorePack importPackJson(String raw) {
    final map = LoreJsonUtils.parseObject(raw) ??
        Map<String, dynamic>.from(jsonDecode(raw) as Map);
    final packJson = map['pack'] is Map
        ? Map<String, dynamic>.from(map['pack'] as Map)
        : map;
    final pack = WorkLorePack.fromJson(packJson);
    if (pack.schemaVersion > WorkLorePack.currentSchemaVersion) {
      throw FormatException(
        'Unsupported lore pack schema_version ${pack.schemaVersion}',
      );
    }
    return pack.withRecomputedHash();
  }

  /// Additive merge: keep existing seed notes / focus unless [preferIncoming].
  static WorkLorePack mergePacks(
    WorkLorePack existing,
    WorkLorePack incoming, {
    bool preferIncoming = true,
  }) {
    if (preferIncoming) {
      final seedList = <LoreSeedNote>[
        ...existing.seedNotes,
      ];
      final seen = seedList.map((s) => s.id).toSet();
      for (final s in incoming.seedNotes) {
        if (seen.add(s.id)) seedList.add(s);
      }
      return incoming
          .copyWith(
            seedNotes: seedList,
            updatedAt: DateTime.now().toUtc(),
          )
          .withRecomputedHash();
    }
    return existing;
  }

  static Future<File> writePackFile(WorkLorePack pack, String path) async {
    final file = File(path);
    await file.writeAsString(exportPackJson(pack), flush: true);
    return file;
  }

  static Future<WorkLorePack> readPackFile(String path) async {
    final raw = await File(path).readAsString();
    return importPackJson(raw);
  }

  static Uint8List exportBatchZip(List<WorkLorePack> packs) {
    final archive = Archive();
    for (final pack in packs) {
      final name =
          '${_safeFileStem(pack.sourceId ?? pack.workId)}.$packFileExtension';
      final bytes = utf8.encode(exportPackJson(pack));
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    }
    return Uint8List.fromList(ZipEncoder().encode(archive)!);
  }

  static List<WorkLorePack> importBatchZip(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final packs = <WorkLorePack>[];
    for (final file in archive.files) {
      if (!file.isFile) continue;
      if (!file.name.endsWith('.json')) continue;
      final content = utf8.decode(file.content as List<int>);
      packs.add(importPackJson(content));
    }
    return packs;
  }

  static String _safeFileStem(String raw) {
    return raw.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }
}
