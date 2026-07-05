import 'package:dio/dio.dart';
import 'package:xuro/core/dlsite/auth/dlsite_auth_repository.dart';
import 'package:xuro/core/dlsite/dlsite_constants.dart';
import 'package:xuro/core/dlsite/dlsite_json_utils.dart';
import 'package:xuro/core/dlsite/models/dlsite_album.dart';
import 'package:xuro/common/constants/strings.dart';

/// Resolves DLsite Play stream URLs for a purchased work (Eara port, audio-only).
class DlsitePlayWorkService {
  DlsitePlayWorkService(this._auth);

  final DlsiteAuthRepository _auth;
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 45),
      headers: {'User-Agent': DlsiteConstants.userAgent},
    ),
  );

  static const _audioExts = {
    'mp3',
    'wav',
    'flac',
    'm4a',
    'ogg',
    'aac',
    'opus',
  };

  Future<List<DlsiteAudioTrack>> fetchAudioTracks(String workno) async {
    final clean = dlsiteExtractRj(workno);
    if (clean.isEmpty) return [];

    final cookie = (await _auth.getPlayCookie()).trim();
    if (cookie.isEmpty) throw StateError(Strings.dlsiteLoginRequired);

    final sign = await _fetchDownloadSign(clean, cookie);
    final ziptree = await _fetchZiptree(sign.baseUrl, sign.params, cookie);
    final tree = (ziptree['tree'] as List?)
            ?.whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList() ??
        [];
    final playfile = (ziptree['playfile'] as Map?)?.cast<String, dynamic>();
    final revision = dlsitePickString(ziptree['revision']).isNotEmpty
        ? dlsitePickString(ziptree['revision'])
        : sign.revision;

    final fileToDisplay = <String, String>{};
    void walk(List<Map<String, dynamic>> nodes, String parentPath) {
      for (final n in nodes) {
        final type = dlsitePickString(n['type']);
        if (type == 'folder') {
          final pth = dlsitePickString(n['path']).isNotEmpty
              ? dlsitePickString(n['path'])
              : parentPath;
          final children = (n['children'] as List?)
                  ?.whereType<Map>()
                  .map((e) => e.cast<String, dynamic>())
                  .toList() ??
              [];
          walk(children, pth.trim());
        } else if (type == 'file') {
          final hn = dlsitePickString(n['hashname']).trim();
          final nm = dlsitePickString(n['name']).trim();
          if (hn.isEmpty) continue;
          final display = parentPath.isNotEmpty
              ? (nm.isNotEmpty ? '$parentPath/$nm' : parentPath)
              : (nm.isNotEmpty ? nm : hn);
          fileToDisplay[hn] = display;
        }
      }
    }

    walk(tree, '');

    final q = dlsiteBuildQuery({'v': revision, ...sign.params});
    final tracks = <DlsiteAudioTrack>[];

    if (playfile == null) return tracks;

    for (final entry in playfile.entries) {
      final hash = entry.key.trim();
      if (hash.isEmpty) continue;
      final meta = entry.value;
      if (meta is! Map) continue;
      final map = meta.cast<String, dynamic>();
      if (dlsitePickString(map['type']) != 'audio') continue;
      final audio = map['audio'] as Map?;
      final optimized = audio?['optimized'] as Map?;
      if (optimized == null) continue;
      final optName = dlsitePickString(optimized['name']).trim();
      if (optName.isEmpty) continue;
      final streamUrl = '${sign.baseUrl}optimized/$optName?$q';
      final display = fileToDisplay[hash] ?? hash;
      final ext = display.split('.').last.toLowerCase();
      if (!_audioExts.contains(ext) && !display.toLowerCase().contains('.')) {
        // DLsite optimized audio may omit ext in display — still allow.
      }
      final duration = _parseDouble(optimized['duration']);
      tracks.add(
        DlsiteAudioTrack(
          displayPath: display,
          streamUrl: streamUrl,
          durationSeconds: duration,
        ),
      );
    }

    tracks.sort((a, b) => a.displayPath.compareTo(b.displayPath));
    return tracks;
  }

  double? _parseDouble(Object? v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  Future<_SignResult> _fetchDownloadSign(String workno, String cookie) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '${DlsiteConstants.playOrigin}/api/v3/download/sign/url',
      queryParameters: {'workno': workno},
      options: Options(
        headers: {
          'Cookie': cookie,
          'Referer': '${DlsiteConstants.playOrigin}/',
          'Accept': 'application/json, text/plain, */*',
        },
        responseType: ResponseType.json,
        validateStatus: (s) => s != null && s < 500,
      ),
    );
    if (resp.statusCode != 200) {
      throw StateError('DLsite sign failed (${resp.statusCode})');
    }
    final data = resp.data ?? {};
    final baseUrl = dlsitePickString(data['url']).trim();
    final paramsAny = data['params'] as Map?;
    final params = <String, String>{};
    paramsAny?.forEach((k, v) {
      final key = dlsitePickString(k).trim();
      final value = dlsitePickString(v).trim();
      if (key.isNotEmpty && value.isNotEmpty) params[key] = value;
    });
    if (baseUrl.isEmpty || params.isEmpty) {
      throw StateError('DLsite sign missing url/params');
    }
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final ziptreeV = (nowSec - (nowSec % 60)).toString();
    return _SignResult(baseUrl: baseUrl, params: params, revision: ziptreeV);
  }

  Future<Map<String, dynamic>> _fetchZiptree(
    String baseUrl,
    Map<String, String> params,
    String cookie,
  ) async {
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final ziptreeV = (nowSec - (nowSec % 60)).toString();
    final q = dlsiteBuildQuery({'v': ziptreeV, ...params});
    final url = '${baseUrl}ziptree.json?$q';
    final resp = await _dio.get<Map<String, dynamic>>(
      url,
      options: Options(
        headers: {
          'Cookie': cookie,
          'Referer': '${DlsiteConstants.playOrigin}/',
          'Accept': 'application/json, text/plain, */*',
        },
        responseType: ResponseType.json,
        validateStatus: (s) => s != null && s < 500,
      ),
    );
    if (resp.statusCode != 200) {
      throw StateError('DLsite ziptree failed (${resp.statusCode})');
    }
    return resp.data ?? {};
  }
}

class _SignResult {
  const _SignResult({
    required this.baseUrl,
    required this.params,
    required this.revision,
  });

  final String baseUrl;
  final Map<String, String> params;
  final String revision;
}
