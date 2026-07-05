import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lizunemu/utils/logger.dart';

/// Stores the LLM API key in secure storage with prefs fallback.
class LlmApiKeyRepository {
  static const _key = 'llm_api_key';

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secure;

  String? _cached;
  bool _loaded = false;
  Future<String?>? _loadFuture;
  Future<void> _writeLock = Future<void>.value();

  LlmApiKeyRepository(this._prefs, {FlutterSecureStorage? secureStorage})
      : _secure = secureStorage ?? const FlutterSecureStorage();

  Future<R> _serialize<R>(Future<R> Function() action) {
    final run = _writeLock.then((_) => action());
    _writeLock = run.then<void>((_) {}, onError: (_) {});
    return run;
  }

  Future<String?> getApiKey() async {
    if (_loaded) return _cached;
    return _loadFuture ??= _load();
  }

  Future<String?> _load() async {
    try {
      String? value;
      try {
        value = await _secure.read(key: _key);
      } catch (e) {
        AppLogger.warning('LlmApiKeyRepository secure read failed: $e');
      }
      if (_loaded) return _cached;
      value ??= _prefs.getString(_key);
      _cached = value;
      _loaded = true;
      return _cached;
    } finally {
      _loadFuture = null;
    }
  }

  Future<void> saveApiKey(String key) async {
    await _serialize<void>(() async {
      _cached = key;
      _loaded = true;
      try {
        await _secure.write(key: _key, value: key);
      } catch (e) {
        AppLogger.warning('LlmApiKeyRepository secure write failed: $e');
      }
      await _prefs.setString(_key, key);
    });
  }

  Future<void> clearApiKey() async {
    await _serialize<void>(() async {
      _cached = null;
      _loaded = true;
      try {
        await _secure.delete(key: _key);
      } catch (_) {}
      await _prefs.remove(_key);
    });
  }
}
