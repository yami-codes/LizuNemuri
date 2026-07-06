import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lizunemu/data/models/auth/auth_resp/auth_resp.dart';
import 'package:lizunemu/utils/logger.dart';
import 'package:lizunemu/common/constants/log_strings.dart';

/// Authentication data repository.
///
/// - [AuthResp] JSON blob (bearer token) in [FlutterSecureStorage], not plaintext prefs.
/// - In-memory cache ([_cached]/[_loaded]): zero storage/JSON work per request after first load.
/// - One-time legacy plaintext migration; defensive fallback to prefs on secure-storage failure.
class AuthRepository {
  static const _authDataKey = 'auth_data';

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secure;

  AuthResp? _cached;
  bool _loaded = false;
  Future<AuthResp?>? _loadFuture;

  // Serialize all secure/prefs writes so issue order == persist order; guards prevent stale token resurrection.
  Future<void> _writeLock = Future<void>.value();

  AuthRepository(this._prefs, {FlutterSecureStorage? secureStorage})
      : _secure = secureStorage ?? const FlutterSecureStorage();

  Future<R> _serialize<R>(Future<R> Function() action) {
    final run = _writeLock.then((_) => action());
    // Chain continues regardless of success (swallow errors to avoid blocking).
    _writeLock = run.then<void>((_) {}, onError: (_) {});
    return run;
  }

  Future<AuthResp?> getAuthData() async {
    if (_loaded) return _cached;
    // `??=` with no await: concurrent first access shares one in-flight load/migrate.
    return _loadFuture ??= _loadAndMigrate();
  }

  Future<AuthResp?> _loadAndMigrate() async {
    try {
      // 1. Secure storage first.
      String? jsonStr;
      try {
        jsonStr = await _secure.read(key: _authDataKey);
      } catch (e) {
        AppLogger.warning(LogStrings.logSecureStorageReadFailedFallb4e79f(e));
      }
      // If save/clear ran during load, in-memory state is authoritative — discard load result.
      if (_loaded) return _cached;
      if (jsonStr != null) {
        _cached = _decode(jsonStr);
        _loaded = true;
        return _cached;
      }

      // 2. Migrate legacy plaintext prefs.auth_data.
      final legacy = _prefs.getString(_authDataKey);
      if (legacy != null) {
        // Authoritative memory state during in-flight save/clear — skip migration to avoid overwriting new token.
        if (_loaded) return _cached;
        await _serialize<void>(() async {
          try {
            await _secure.write(key: _authDataKey, value: legacy);
          } catch (e) {
            AppLogger.warning(LogStrings.logAuthMigrationFailedKeepPrefs5e139(e));
            return;
          }
          // Clear plaintext only after successful migration.
          try {
            await _prefs.remove(_authDataKey);
          } catch (_) {}
          AppLogger.info(LogStrings.logAuthDataMigratedToSecureStor5b637);
        });
        // Backfill memory from legacy whether migration succeeded (failure = degrade, not logout).
        if (_loaded) return _cached;
        _cached = _decode(legacy);
        _loaded = true;
        return _cached;
      }

      // 3. Not logged in.
      if (_loaded) return _cached;
      _cached = null;
      _loaded = true;
      return null;
    } finally {
      _loadFuture = null;
    }
  }

  AuthResp? _decode(String jsonStr) {
    try {
      return AuthResp.fromJson(json.decode(jsonStr) as Map<String, dynamic>);
    } catch (e) {
      AppLogger.error(LogStrings.logParseAuthDataFailed, e);
      return null;
    }
  }

  Future<void> saveAuthData(AuthResp authData) async {
    final jsonStr = json.encode(authData.toJson());
    _cached = authData;
    _loaded = true;
    // Enqueue entire write on serial chain for correct order vs migration/clear.
    await _serialize<void>(() async {
      try {
        await _secure.write(key: _authDataKey, value: jsonStr);
        // Secure write OK → remove any leftover plaintext.
        try {
          await _prefs.remove(_authDataKey);
        } catch (_) {}
        AppLogger.info(LogStrings.logAuthDataSavedSecureStoragef9d9f);
      } catch (e) {
        // Degrade to prefs when secure storage unavailable.
        AppLogger.warning(LogStrings.logSecureStorageWriteFailedFallfdfba(e));
        try {
          await _prefs.setString(_authDataKey, jsonStr);
        } catch (e2) {
          AppLogger.error(LogStrings.logPrefsFallbackWriteAlsoFailed1252d, e2);
          rethrow;
        }
      }
    });
  }

  Future<void> clearAuthData() async {
    _cached = null;
    _loaded = true;
    await _serialize<void>(() async {
      try {
        await _secure.delete(key: _authDataKey);
      } catch (e) {
        AppLogger.warning(LogStrings.logClearAuthDatafailedEac5db(e));
      }
      try {
        await _prefs.remove(_authDataKey);
      } catch (e) {
        AppLogger.warning(LogStrings.logClearPrefsAuthDatafailedE0d083(e));
      }
      AppLogger.info(LogStrings.logAuthDataCleared160e7);
    });
  }
}
