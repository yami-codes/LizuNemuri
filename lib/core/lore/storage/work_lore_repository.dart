import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:lizunemu/core/database/database_service.dart';
import 'package:lizunemu/core/lore/models/work_lore_pack.dart';

class WorkLoreRepository {
  static const _table = 'work_lore_packs';
  final DatabaseService _db;

  WorkLoreRepository(this._db);

  Future<WorkLorePack?> getByWorkId(String workId) async {
    final db = await _db.database;
    final rows = await db.query(
      _table,
      where: 'work_id = ?',
      whereArgs: [workId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final raw = rows.first['pack_json'] as String?;
    if (raw == null || raw.isEmpty) return null;
    return WorkLorePack.fromJson(
      Map<String, dynamic>.from(jsonDecode(raw) as Map),
    );
  }

  Future<void> upsert(WorkLorePack pack) async {
    final hashed = pack.loreHash.isEmpty ? pack.withRecomputedHash() : pack;
    final db = await _db.database;
    await db.insert(
      _table,
      {
        'work_id': hashed.workId,
        'pack_json': jsonEncode(hashed.toJson()),
        'lore_hash': hashed.loreHash,
        'updated_at': hashed.updatedAt.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String workId) async {
    final db = await _db.database;
    await db.delete(_table, where: 'work_id = ?', whereArgs: [workId]);
  }

  Future<List<String>> listAllWorkIds() async {
    final db = await _db.database;
    final rows = await db.query(_table, columns: ['work_id'], orderBy: 'updated_at DESC');
    return rows.map((r) => r['work_id'] as String).toList();
  }

  Future<bool> exists(String workId) async {
    final db = await _db.database;
    final rows = await db.query(
      _table,
      columns: ['work_id'],
      where: 'work_id = ?',
      whereArgs: [workId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }
}
