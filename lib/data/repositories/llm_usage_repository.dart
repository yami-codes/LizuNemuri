import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:xuro/core/llm/llm_usage.dart';
import 'package:xuro/data/models/llm/llm_usage_record.dart';

/// Persists LLM token/cost history locally (newest first).
class LlmUsageRepository {
  static const _historyKey = 'llm_usage_history';
  static const _maxEntries = 300;

  final SharedPreferences _prefs;

  LlmUsageRepository(this._prefs);

  Future<List<LlmUsageRecord>> listHistory({int limit = 100}) async {
    final all = await _loadAll();
    if (limit >= all.length) return all;
    return all.sublist(0, limit);
  }

  Future<void> record({
    required String model,
    required String operation,
    required LlmUsage usage,
    String? workId,
    String? trackName,
  }) async {
    final entry = LlmUsageRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      model: model,
      operation: operation,
      promptTokens: usage.promptTokens,
      completionTokens: usage.completionTokens,
      totalTokens: usage.totalTokens,
      totalCostUsd: usage.totalCostUsd,
      workId: workId,
      trackName: trackName,
    );

    final all = await _loadAll();
    all.insert(0, entry);
    while (all.length > _maxEntries) {
      all.removeLast();
    }
    await _saveAll(all);
  }

  Future<void> clearHistory() async {
    await _prefs.remove(_historyKey);
  }

  Future<({int totalTokens, double totalCostUsd, int requestCount})> totals() async {
    final all = await _loadAll();
    var tokens = 0;
    var cost = 0.0;
    var hasCost = false;
    for (final e in all) {
      tokens += e.totalTokens;
      if (e.totalCostUsd != null) {
        cost += e.totalCostUsd!;
        hasCost = true;
      }
    }
    return (
      totalTokens: tokens,
      totalCostUsd: hasCost ? cost : 0.0,
      requestCount: all.length,
    );
  }

  Future<List<LlmUsageRecord>> _loadAll() async {
    final raw = _prefs.getString(_historyKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((e) => LlmUsageRecord.fromJson(
                e.map((k, v) => MapEntry(k.toString(), v)),
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveAll(List<LlmUsageRecord> entries) async {
    final encoded = jsonEncode(entries.map((e) => e.toJson()).toList());
    await _prefs.setString(_historyKey, encoded);
  }
}
