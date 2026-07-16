import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Runtime platform feature gates for web / mobile / desktop targets.
class PlatformCapabilities {
  PlatformCapabilities._();

  static const _channel = MethodChannel('moe.lizu.nemu/platform');

  /// Injected for tests; null = query native.
  static int? debugAndroidSdkIntOverride;

  static int? _cachedAndroidSdkInt;
  static Future<int?>? _sdkLoad;

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

  /// Cached Android SDK_INT (null on non-Android or before [ensureAndroidSdkInt]).
  static int? get androidSdkInt =>
      debugAndroidSdkIntOverride ?? _cachedAndroidSdkInt;

  /// Android 14+ (API 34) typed dataSync foreground service for LLM queues.
  static bool get supportsLlmDataSyncForegroundService {
    if (!isAndroid) return false;
    final sdk = androidSdkInt;
    return sdk != null && sdk >= 34;
  }

  /// Load SDK_INT once (call early from queue notification init).
  static Future<int?> ensureAndroidSdkInt() async {
    if (debugAndroidSdkIntOverride != null) {
      return debugAndroidSdkIntOverride;
    }
    if (!isAndroid) return null;
    if (_cachedAndroidSdkInt != null) return _cachedAndroidSdkInt;
    _sdkLoad ??= () async {
      try {
        final v = await _channel.invokeMethod<int>('getSdkInt');
        _cachedAndroidSdkInt = v;
        return v;
      } catch (_) {
        _cachedAndroidSdkInt = null;
        return null;
      }
    }();
    return _sdkLoad;
  }
}
