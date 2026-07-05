import 'package:flutter/foundation.dart';

/// Runtime platform feature gates for web / mobile / desktop targets.
class PlatformCapabilities {
  PlatformCapabilities._();

  static bool get isWeb => kIsWeb;

  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static bool get isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  static bool get isLinux =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;

  static bool get isMacOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  static bool get isDesktop => isWindows || isLinux || isMacOS;

  /// Android-only floating lyric overlay.
  static bool get supportsFloatingLyrics => isAndroid;

  /// File-system backed offline downloads (not available in browser).
  static bool get supportsLocalDownloads => !isWeb;

  /// Lock-screen / notification-bar media controls.
  static bool get supportsMediaNotification => isAndroid || isIOS;

  /// Desktop SQLite via sqflite_common_ffi (Windows/Linux).
  static bool get needsDesktopSqlite => isWindows || isLinux;

  /// Browser SQLite via sqflite_common_ffi_web.
  static bool get needsWebSqlite => isWeb;

  /// just_audio AndroidEqualizer (Milestone H).
  static bool get supportsAndroidEqualizer => isAndroid;
}
