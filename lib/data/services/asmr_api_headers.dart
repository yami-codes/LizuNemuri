/// Browser-like HTTP headers for asmr.one API and CDN fetches.
///
/// Mirrors gate on `Accept-Language` only. **English is banned** — never emit
/// `en`. All asmr API and CDN traffic uses Chinese (`zh-CN`) regardless of UI
/// language.
abstract final class AsmrApiHeaders {
  /// Chinese-primary; no `en` (banned). Used for every asmr request.
  static const acceptLanguage = 'zh-CN,zh;q=0.9,ja;q=0.7';

  /// @deprecated Use [acceptLanguage].
  static const zhAcceptLanguage = acceptLanguage;

  static const _userAgent =
      'Mozilla/5.0 (compatible; Lizunemu/2.0; +https://github.com/yami-codes/LizuNemu)';

  /// Browser-like headers for presigned CDN URLs (no auth token).
  static Map<String, String> get cdnFetchHeaders => {
        'User-Agent': _userAgent,
        'Accept': '*/*',
        'Accept-Language': acceptLanguage,
      };
}
