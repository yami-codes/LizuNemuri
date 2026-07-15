import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:lizunemu/core/lore/lore_generate_queue_models.dart';
import 'package:lizunemu/utils/logger.dart';

class LoreGenerateQueueStore {
  static const _key = 'lore_generate_queue_v1';

  final SharedPreferences _prefs;

  LoreGenerateQueueStore(this._prefs);

  List<LoreGenerateQueueJob> load() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .map((e) => LoreGenerateQueueJob.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList();
    } catch (e) {
      AppLogger.warning('LoreGenerateQueueStore load failed: $e');
      return [];
    }
  }

  Future<void> save(List<LoreGenerateQueueJob> jobs) async {
    try {
      final payload = jsonEncode(jobs.map((j) => j.toJson()).toList());
      await _prefs.setString(_key, payload);
    } catch (e) {
      AppLogger.warning('LoreGenerateQueueStore save failed: $e');
    }
  }

  Future<void> clear() async {
    await _prefs.remove(_key);
  }
}
