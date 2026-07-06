import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:lizunemu/data/models/update_info.dart';
import 'package:lizunemu/data/services/exceptions/update_exception.dart';
import 'package:lizunemu/utils/logger.dart';
import 'package:lizunemu/common/constants/log_strings.dart';

class UpdateCheckResult {
  final UpdateInfo latest;
  final String currentVersion;
  final bool hasUpdate;

  UpdateCheckResult({
    required this.latest,
    required this.currentVersion,
    required this.hasUpdate,
  });
}

/// Reads this repo's GitHub Releases and compares to the current app version.
///
/// Standalone Dio to api.github.com — **does not follow `AppSettingsService`** or `AuthInterceptor`.
class UpdateService {
  static const String _owner = 'yami-codes';
  static const String _repo = 'LizuNemu';

  /// CI publishes with `prerelease: true`, so `/releases/latest` is unusable — use list endpoint.
  static const String _releasesPath = '/repos/$_owner/$_repo/releases';

  /// Accepts only `vX.Y.Z` tags (`$` anchor rejects suffix tags).
  static final RegExp _tagRe = RegExp(r'^v?\d+\.\d+\.\d+$');

  final Dio _dio;

  UpdateService()
      : _dio = Dio(BaseOptions(
          baseUrl: 'https://api.github.com',
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
          headers: const {
            'Accept': 'application/vnd.github+json',
            'X-GitHub-Api-Version': '2022-11-28',
          },
        ));

  Future<UpdateCheckResult> checkForUpdate() async {
    try {
      final resp = await _dio.get(
        _releasesPath,
        queryParameters: const {'per_page': 10},
      );
      final data = resp.data;
      if (data is! List) {
        throw UpdateException(
          type: UpdateErrorType.invalidPayload,
          message: LogStrings.logReleasesResponseIsNotAnArray69be5(data.runtimeType),
        );
      }

      final latest = selectLatestRelease(data);
      if (latest == null) {
        throw UpdateException(
          type: UpdateErrorType.noRelease,
          message: LogStrings.logNoValidReleaseEmptyOrNoSemveee981,
        );
      }

      final current = (await PackageInfo.fromPlatform()).version;
      final hasUpdate = compareSemver(latest.version, current) > 0;
      AppLogger.info(
        LogStrings.logUpdateCheckRemoteLatestVersi710ef(latest.version, current, hasUpdate),
      );
      return UpdateCheckResult(
        latest: latest,
        currentVersion: current,
        hasUpdate: hasUpdate,
      );
    } on UpdateException {
      rethrow;
    } on DioException catch (e, st) {
      AppLogger.error(LogStrings.logUpdateCheckNetworkFailed7aa8a, e, st);
      throw UpdateException.fromDioException(e);
    } catch (e, st) {
      AppLogger.error(LogStrings.logUpdateCheckParseFailed537cd, e, st);
      throw UpdateException(
        type: UpdateErrorType.invalidPayload,
        message: LogStrings.logParseFailedEe96d4(e),
        originalError: e,
      );
    }
  }

  /// Pick the **max semver** valid release from the list.
  ///
  /// Do not use `[0]` — GitHub does not guarantee list order is newest.
  /// One bad release is skipped instead of failing the whole check.
  /// Returns `null` when none are valid → caller maps to `noRelease`.
  static UpdateInfo? selectLatestRelease(List<dynamic> releases) {
    UpdateInfo? best;
    for (final r in releases) {
      if (r is! Map) continue;
      final map = Map<String, dynamic>.from(r);
      final tag = map['tag_name'];
      if (tag is! String || !_tagRe.hasMatch(tag)) continue;
      UpdateInfo info;
      try {
        info = UpdateInfo.fromReleaseJson(map);
      } on FormatException {
        continue;
      }
      if (best == null || compareSemver(info.version, best.version) > 0) {
        best = info;
      }
    }
    return best;
  }

  /// Pure semver compare: `>0` newer, `0` equal, `<0` older.
  ///
  /// Tolerant: strip `v`, pad segments with 0 (`1.2` == `1.2.0`), non-numeric → 0.
  static int compareSemver(String a, String b) {
    List<int> parts(String v) {
      var s = v.trim();
      if (s.startsWith('v') || s.startsWith('V')) s = s.substring(1);
      final segs = s.split('.');
      return List<int>.generate(
        3,
        (i) => i < segs.length ? (int.tryParse(segs[i].trim()) ?? 0) : 0,
      );
    }

    final pa = parts(a);
    final pb = parts(b);
    for (var i = 0; i < 3; i++) {
      if (pa[i] != pb[i]) return pa[i] > pb[i] ? 1 : -1;
    }
    return 0;
  }
}
