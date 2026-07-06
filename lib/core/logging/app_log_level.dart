import 'package:logger/logger.dart';

/// In-app log severity (lowest → highest).
enum AppLogLevel {
  verbose,
  debug,
  info,
  warning,
  error,
}

extension AppLogLevelX on AppLogLevel {
  int get priority => index;

  bool isAtLeast(AppLogLevel minimum) => priority >= minimum.priority;

  Level get loggerLevel => switch (this) {
        AppLogLevel.verbose => Level.trace,
        AppLogLevel.debug => Level.debug,
        AppLogLevel.info => Level.info,
        AppLogLevel.warning => Level.warning,
        AppLogLevel.error => Level.error,
      };

  static AppLogLevel fromName(String? raw, {AppLogLevel fallback = AppLogLevel.debug}) {
    if (raw == null) return fallback;
    for (final level in AppLogLevel.values) {
      if (level.name == raw) return level;
    }
    return fallback;
  }
}
