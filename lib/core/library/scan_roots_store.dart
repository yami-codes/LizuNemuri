import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persisted folder paths for local library scanning.
class ScanRootsStore {
  ScanRootsStore(this._prefs);

  static const _key = 'local_scan_roots';

  final SharedPreferences _prefs;

  List<String> get roots {
    final raw = _prefs.getStringList(_key);
    if (raw == null || raw.isEmpty) return const [];
    return List.unmodifiable(raw);
  }

  Future<void> addRoot(String path) async {
    final normalized = _normalize(path);
    if (normalized.isEmpty) return;
    final next = [...roots];
    if (next.contains(normalized)) return;
    next.add(normalized);
    await _prefs.setStringList(_key, next);
  }

  Future<void> removeRoot(String path) async {
    final normalized = _normalize(path);
    final next = roots.where((r) => r != normalized).toList();
    await _prefs.setStringList(_key, next);
  }

  String _normalize(String path) {
    var p = path.trim();
    if (p.endsWith('/')) p = p.substring(0, p.length - 1);
    return p;
  }

  String encodeForDebug() => jsonEncode(roots);
}
