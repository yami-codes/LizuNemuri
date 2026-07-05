import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:lizunemu/core/dlsite/auth/dlsite_auth_repository.dart';
import 'package:lizunemu/core/dlsite/dlsite_constants.dart';
import 'package:lizunemu/core/dlsite/dlsite_json_utils.dart';
import 'package:lizunemu/core/dlsite/models/dlsite_album.dart';
import 'package:lizunemu/common/constants/strings.dart';

/// Fetches purchased works from DLsite Play API (Eara port).
class DlsitePlayLibraryService {
  DlsitePlayLibraryService(this._auth);

  final DlsiteAuthRepository _auth;
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'User-Agent': DlsiteConstants.userAgent,
        'Accept': 'application/json, text/plain, */*',
        'Accept-Language': DlsiteConstants.acceptLanguage,
      },
    ),
  );

  List<DlsiteAlbum>? _cache;
  int _cacheTs = 0;
  static const _cacheTtlMs = 5 * 60 * 1000;

  void clearCache() {
    _cache = null;
    _cacheTs = 0;
  }

  Future<List<DlsiteAlbum>> listLibrary({bool forceRefresh = false}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (!forceRefresh &&
        _cache != null &&
        now - _cacheTs < _cacheTtlMs) {
      return _cache!;
    }

    var cookie = (await _auth.getPlayCookie()).trim();
    if (cookie.isEmpty) {
      throw StateError(Strings.dlsiteLoginRequired);
    }

    cookie = await _ensurePlayAuthorized(cookie);
    if (cookie != (await _auth.getPlayCookie())) {
      await _auth.savePlayCookie(cookie);
    }

    final sales = await _fetchSales(cookie);
    final works = await _fetchWorks(cookie, sales.keys.toList());
    final albums = <DlsiteAlbum>[];

    for (final w in works) {
      final workno = dlsitePickString(w['workno']).toUpperCase().trim();
      if (workno.isEmpty) continue;
      final title = dlsitePickLocalized(w['name']);
      final makerObj = w['maker'];
      final circle = makerObj is Map
          ? dlsitePickLocalized(makerObj['name'])
          : dlsitePickLocalized(makerObj);
      final cover = _coverFromWork(w);
      final tagObjects = (w['tags'] as List?)
              ?.whereType<Map>()
              .map((e) => e.cast<String, dynamic>())
              .toList() ??
          [];
      final tags = tagObjects
          .where((t) => dlsitePickString(t['class']) != 'voice_by')
          .map((t) => dlsitePickLocalized(t['name']))
          .where((s) => s.isNotEmpty)
          .toList();
      final cv = tagObjects
          .where((t) => dlsitePickString(t['class']) == 'voice_by')
          .map((t) => dlsitePickLocalized(t['name']))
          .where((s) => s.isNotEmpty)
          .join(', ');

      albums.add(
        DlsiteAlbum(
          workno: workno,
          title: title.isEmpty ? workno : title,
          circle: circle.isEmpty ? null : circle,
          cv: cv.isEmpty ? null : cv,
          tags: tags,
          coverUrl: cover.isEmpty ? null : cover,
          purchaseDate: sales[workno],
        ),
      );
    }

    albums.sort(
      (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );
    _cache = albums;
    _cacheTs = now;
    return albums;
  }

  List<DlsiteAlbum> filter(List<DlsiteAlbum> all, String keyword) {
    final kw = keyword.trim();
    if (kw.isEmpty) return all;
    final rj = dlsiteExtractRj(kw);
    if (rj.isNotEmpty) {
      return all
          .where((a) => a.workno.toUpperCase() == rj)
          .toList(growable: false);
    }
    final tokens = kw
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .map((t) => t.toLowerCase())
        .toList();
    if (tokens.isEmpty) return all;
    return all.where((album) {
      final hay =
          '${album.workno} ${album.title} ${album.circle ?? ''}'.toLowerCase();
      return tokens.every(hay.contains);
    }).toList(growable: false);
  }

  String _coverFromWork(Map<String, dynamic> w) {
    final main = dlsitePickLocalized(w['image_main']);
    if (main.isNotEmpty) return dlsiteNormalizeCoverUrl(main);
    final wf = w['work_files'];
    if (wf is Map) {
      final v = dlsitePickLocalized(wf['main']);
      if (v.isNotEmpty) return dlsiteNormalizeCoverUrl(v);
      final sam = dlsitePickLocalized(wf['sam']);
      if (sam.isNotEmpty) return dlsiteNormalizeCoverUrl(sam);
    }
    return '';
  }

  Future<Map<String, String>> _fetchSales(String cookie) async {
    final nowSec = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final resp = await _dio.get<List<dynamic>>(
      '${DlsiteConstants.playOrigin}/api/v3/content/sales',
      queryParameters: {'query[last]': nowSec},
      options: Options(
        headers: _playHeaders(cookie),
        responseType: ResponseType.json,
        validateStatus: (s) => s != null && s < 500,
      ),
    );
    if (resp.statusCode == 401) {
      throw StateError(Strings.dlsiteLoginRequired);
    }
    if (resp.statusCode != 200) {
      throw StateError('DLsite sales failed (${resp.statusCode})');
    }
    final list = resp.data ?? [];
    final out = <String, String>{};
    for (final item in list) {
      if (item is! Map) continue;
      final map = item.cast<String, dynamic>();
      final workno = dlsitePickString(map['workno']).toUpperCase().trim();
      if (workno.isEmpty) continue;
      out[workno] = dlsitePickString(map['sales_date']).trim();
    }
    return out;
  }

  Future<List<Map<String, dynamic>>> _fetchWorks(
    String cookie,
    List<String> worknos,
  ) async {
    if (worknos.isEmpty) return [];
    final out = <Map<String, dynamic>>[];
    const chunkSize = 100;
    for (var i = 0; i < worknos.length; i += chunkSize) {
      final chunk = worknos.sublist(
        i,
        (i + chunkSize).clamp(0, worknos.length),
      );
      final resp = await _dio.post<Map<String, dynamic>>(
        '${DlsiteConstants.playOrigin}/api/v3/content/works',
        data: jsonEncode(chunk),
        options: Options(
          headers: {
            ..._playHeaders(cookie),
            'Content-Type': 'application/json',
          },
          responseType: ResponseType.json,
          validateStatus: (s) => s != null && s < 500,
        ),
      );
      if (resp.statusCode == 401) {
        throw StateError(Strings.dlsiteLoginRequired);
      }
      if (resp.statusCode != 200) continue;
      final works = resp.data?['works'];
      if (works is List) {
        for (final w in works) {
          if (w is Map) out.add(w.cast<String, dynamic>());
        }
      }
    }
    return out;
  }

  Map<String, String> _playHeaders(String cookie) => {
        'Cookie': cookie,
        'Referer': DlsiteConstants.libraryReferer,
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
      };

  Future<String> _ensurePlayAuthorized(String cookie) async {
    var current = cookie.trim();
    if (current.isEmpty) return '';

    final (c1, ok1) = await _fetchAuthorize(current);
    if (ok1) return c1;

    final c2 = await _fetchLoginSetCookies(c1);
    final merged = dlsiteMergeCookies(c1, c2);
    final (c3, ok3) = await _fetchAuthorize(merged);
    return ok3 ? c3 : c3;
  }

  Future<(String, bool)> _fetchAuthorize(String cookie) async {
    final resp = await _dio.get<String>(
      '${DlsiteConstants.playOrigin}/api/authorize',
      options: Options(
        headers: _playHeaders(cookie),
        responseType: ResponseType.plain,
        validateStatus: (_) => true,
      ),
    );
    final setCookies = resp.headers['set-cookie'] ?? [];
    final merged = dlsiteMergeCookies(cookie, setCookies);
    final body = resp.data ?? '';
    final ok = resp.statusCode == 200 &&
        body.isNotEmpty &&
        body != 'null' &&
        body != '{}';
    return (merged, ok);
  }

  Future<List<String>> _fetchLoginSetCookies(String cookie) async {
    final resp = await _dio.get<String>(
      '${DlsiteConstants.playOrigin}/login/',
      options: Options(
        headers: {
          'Cookie': cookie,
          'Referer': '${DlsiteConstants.playOrigin}/',
          'User-Agent': DlsiteConstants.userAgent,
          'Accept-Language': DlsiteConstants.acceptLanguage,
        },
        responseType: ResponseType.plain,
        validateStatus: (_) => true,
      ),
    );
    return resp.headers['set-cookie'] ?? [];
  }
}
