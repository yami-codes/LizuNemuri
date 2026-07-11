import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:lizunemu/core/llm/translation_queue_models.dart';
import 'package:lizunemu/utils/logger.dart';

/// Persists the translation queue so cold starts can resume unfinished work.
class TranslationQueueStore {
  static const _key = 'translation_queue_v1';

  final SharedPreferences _prefs;

  TranslationQueueStore(this._prefs);

  List<TranslationQueueJob> load() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .map((e) => TranslationQueueJob.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList();
    } catch (e) {
      AppLogger.warning('TranslationQueueStore load failed: $e');
      return [];
    }
  }

  Future<void> save(List<TranslationQueueJob> jobs) async {
    try {
      final payload = jsonEncode(jobs.map((j) => j.toJson()).toList());
      await _prefs.setString(_key, payload);
    } catch (e) {
      AppLogger.warning('TranslationQueueStore save failed: $e');
    }
  }

  Future<void> clear() async {
    await _prefs.remove(_key);
  }
}
