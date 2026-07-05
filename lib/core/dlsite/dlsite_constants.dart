/// Shared HTTP headers for DLsite Play API (Eara-compatible).
abstract final class DlsiteConstants {
  static const userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  static const acceptLanguage = 'zh-CN,zh;q=0.9,en;q=0.8,ja;q=0.7';

  static const playOrigin = 'https://play.dlsite.com';
  static const libraryReferer = 'https://play.dlsite.com/library';
}
