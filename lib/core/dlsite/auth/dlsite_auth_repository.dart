import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage for play.dlsite.com session cookie.
class DlsiteAuthRepository {
  DlsiteAuthRepository({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _cookieKey = 'dlsite_play_cookie';

  final FlutterSecureStorage _storage;
  String? _cached;

  Future<bool> hasCredentials() async {
    final c = await getPlayCookie();
    return c.trim().isNotEmpty;
  }

  Future<String> getPlayCookie() async {
    if (_cached != null) return _cached!;
    _cached = await _storage.read(key: _cookieKey) ?? '';
    return _cached!;
  }

  Future<void> savePlayCookie(String cookie) async {
    final trimmed = cookie.trim();
    _cached = trimmed;
    await _storage.write(key: _cookieKey, value: trimmed);
  }

  Future<void> clear() async {
    _cached = '';
    await _storage.delete(key: _cookieKey);
  }
}
