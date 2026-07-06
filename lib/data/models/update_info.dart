import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:lizunemu/common/constants/log_strings.dart';

part 'update_info.freezed.dart';

/// Slim view of one GitHub Release.
///
/// Fields are **derived** from GitHub Release JSON (version strips `v`, apk from first `.apk` asset);
/// custom [UpdateInfo.fromReleaseJson] with Freezed only, no json_serializable.
@freezed
class UpdateInfo with _$UpdateInfo {
  const factory UpdateInfo({
    required String tagName,
    required String version,
    required String releaseNotes,
    required String htmlUrl,
    String? apkDownloadUrl,
    required String publishedAt,
  }) = _UpdateInfo;

  /// Builds from one GitHub Release JSON object.
  ///
  /// Throws [FormatException] if `tag_name` or `html_url` is missing;
  /// UpdateService maps to `UpdateException(invalidPayload)`.
  factory UpdateInfo.fromReleaseJson(Map<String, dynamic> json) {
    final tag = json['tag_name'];
    final html = json['html_url'];
    if (tag is! String || tag.isEmpty || html is! String || html.isEmpty) {
      throw FormatException(LogStrings.logGithubReleaseMissingFields);
    }

    String? apkUrl;
    final assets = json['assets'];
    if (assets is List) {
      for (final a in assets) {
        if (a is Map &&
            a['name'] is String &&
            (a['name'] as String).toLowerCase().endsWith('.apk') &&
            a['browser_download_url'] is String) {
          apkUrl = a['browser_download_url'] as String;
          break;
        }
      }
    }

    final version =
        (tag.startsWith('v') || tag.startsWith('V')) ? tag.substring(1) : tag;
    final body = (json['body'] as String?)?.trim() ?? '';

    return UpdateInfo(
      tagName: tag,
      version: version,
      releaseNotes: body,
      htmlUrl: html,
      apkDownloadUrl: apkUrl,
      publishedAt: json['published_at'] as String? ?? '',
    );
  }
}
