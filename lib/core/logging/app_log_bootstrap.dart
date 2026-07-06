import 'package:flutter/foundation.dart';
import 'package:lizunemu/core/logging/app_log_tags.dart';
import 'package:lizunemu/utils/logger.dart';

/// Installs global Flutter / platform error hooks into [AppLogger].
void installAppLogHooks() {
  final previousFlutterError = FlutterError.onError;
  FlutterError.onError = (details) {
    AppLogger.error(
      details.exceptionAsString(),
      details.exception,
      details.stack,
      AppLogTags.flutter,
    );
    previousFlutterError?.call(details);
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
  };

  final previousPlatformError = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error(
      'Uncaught platform error',
      error,
      stack,
      AppLogTags.flutter,
    );
    return previousPlatformError?.call(error, stack) ?? false;
  };
}
