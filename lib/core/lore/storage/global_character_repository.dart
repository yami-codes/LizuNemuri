import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:lizunemu/core/database/database_service.dart';
import 'package:lizunemu/core/lore/models/global_character.dart';

class GlobalCharacterRepository {
  static const _table = 'global_characters';
  final DatabaseService _db;

  GlobalCharacterRepository(this._db);

  Future<GlobalCharacter?> get(String id) async {
    final db = await _db.database;
    final rows = await db.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  Future<void> upsert(GlobalCharacter character) async {
    final db = await _db.database;
    await db.insert(
      _table,
      {
        'id': character.id,
        'name': character.name,
        'sheet_json': jsonEncode(character.toJson()),
        'updated_at': character.updatedAt.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<GlobalCharacter>> listAll() async {
    final db = await _db.database;
    final rows = await db.query(_table, orderBy: 'name COLLATE NOCASE ASC');
    return rows.map(_fromRow).toList();
  }

  Future<List<GlobalCharacter>> searchByName(String query) async {
    final q = query.trim();
    if (q.isEmpty) return listAll();
    final db = await _db.database;
    final rows = await db.query(
      _table,
      where: 'name LIKE ?',
      whereArgs: ['%$q%'],
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(_fromRow).toList();
  }

  GlobalCharacter _fromRow(Map<String, Object?> row) {
    final raw = row['sheet_json'] as String? ?? '{}';
    return GlobalCharacter.fromJson(
      Map<String, dynamic>.from(jsonDecode(raw) as Map),
    );
  }
}
