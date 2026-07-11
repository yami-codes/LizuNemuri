import 'package:sqflite/sqflite.dart';
import 'package:lizunemu/core/database/database_service.dart';

class Ccv2CachedCard {
  final String cacheKey;
  final String loreHash;
  final String cardJson;
  final int updatedAt;

  const Ccv2CachedCard({
    required this.cacheKey,
    required this.loreHash,
    required this.cardJson,
    required this.updatedAt,
  });
}

class Ccv2CardCacheRepository {
  static const _table = 'ccv2_card_cache';
  final DatabaseService _db;

  Ccv2CardCacheRepository(this._db);

  Future<Ccv2CachedCard?> get(String cacheKey) async {
    final db = await _db.database;
    final rows = await db.query(
      _table,
      where: 'cache_key = ?',
      whereArgs: [cacheKey],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    return Ccv2CachedCard(
      cacheKey: row['cache_key'] as String,
      loreHash: row['lore_hash'] as String,
      cardJson: row['card_json'] as String,
      updatedAt: row['updated_at'] as int,
    );
  }

  /// Returns cached card only when [loreHash] still matches.
  Future<String?> getValidCardJson(String cacheKey, String loreHash) async {
    final cached = await get(cacheKey);
    if (cached == null) return null;
    if (cached.loreHash != loreHash) return null;
    return cached.cardJson;
  }

  Future<void> upsert({
    required String cacheKey,
    required String loreHash,
    required String cardJson,
  }) async {
    final db = await _db.database;
    await db.insert(
      _table,
      {
        'cache_key': cacheKey,
        'lore_hash': loreHash,
        'card_json': cardJson,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String cacheKey) async {
    final db = await _db.database;
    await db.delete(_table, where: 'cache_key = ?', whereArgs: [cacheKey]);
  }

  Future<void> deleteByPrefix(String prefix) async {
    final db = await _db.database;
    await db.delete(
      _table,
      where: 'cache_key LIKE ?',
      whereArgs: ['$prefix%'],
    );
  }
}
