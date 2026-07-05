/// JSON helpers for DLsite Play localized fields (ported from Eara).
String dlsitePickString(Object? value) {
  if (value == null) return '';
  if (value is String) return value;
  return value.toString();
}

String dlsitePickLocalized(Object? value) {
  if (value is String) return value.trim();
  if (value is! Map) return dlsitePickString(value).trim();
  const keys = [
    'zh_CN',
    'zh_TW',
    'zh_HK',
    'CHI_HANS',
    'CHI_HANT',
    'ja_JP',
    'en_US',
  ];
  for (final k in keys) {
    final v = value[k];
    if (v is String && v.isNotEmpty) return v.trim();
  }
  for (final v in value.values) {
    if (v is String && v.isNotEmpty) return v.trim();
  }
  return '';
}

String dlsiteNormalizeCoverUrl(String url) {
  final trimmed = url.trim();
  if (trimmed.startsWith('//')) return 'https:$trimmed';
  return trimmed;
}

String dlsiteExtractRj(String input) {
  final match = RegExp(r'\bRJ\d{6,10}\b', caseSensitive: false).firstMatch(input);
  return match?.group(0)?.toUpperCase() ?? '';
}

Map<String, String> dlsiteParseCookieHeader(String cookieHeader) {
  final out = <String, String>{};
  for (final part in cookieHeader.split(';')) {
    final p = part.trim();
    if (p.isEmpty) continue;
    final idx = p.indexOf('=');
    if (idx <= 0) continue;
    final name = p.substring(0, idx).trim();
    final value = p.substring(idx + 1).trim();
    if (name.isNotEmpty) out[name] = value;
  }
  return out;
}

String dlsiteMergeCookies(String base, List<String> setCookies) {
  if (setCookies.isEmpty) return base.trim();
  final map = dlsiteParseCookieHeader(base);
  for (final sc in setCookies) {
    final pair = sc.split(';').first.trim();
    final idx = pair.indexOf('=');
    if (idx <= 0) continue;
    final name = pair.substring(0, idx).trim();
    final value = pair.substring(idx + 1).trim();
    if (name.isNotEmpty) map[name] = value;
  }
  return map.entries.map((e) => '${e.key}=${e.value}').join('; ');
}

String dlsiteBuildQuery(Map<String, String> params) {
  return params.entries
      .map((e) =>
          '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
      .join('&');
}
