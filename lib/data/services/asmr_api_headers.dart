/// Browser-like HTTP headers for asmr.one API and CDN fetches.
///
/// Mirrors gate traffic on `Accept-Language` only — a zh-heavy value passes
/// without VPN even when the app UI is English/Thai.
abstract final class AsmrApiHeaders {
  /// Same shape as a Chinese Chrome `Accept-Language` (also used by DLsite client).
  static const acceptLanguage = 'zh-CN,zh;q=0.9,en;q=0.8,ja;q=0.7';

  static const Map<String, String> defaultHeaders = {
    'Accept-Language': acceptLanguage,
  };
}
