import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:lizunemu/core/logging/app_log_entry.dart';
import 'package:lizunemu/core/logging/app_log_level.dart';
import 'package:lizunemu/core/logging/app_log_store.dart';

class AppLogger {
  static AppLogStore? _store;
  static AppLogLevel _captureMin = AppLogLevel.debug;
  static bool _consoleEnabled = kDebugMode;

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    level: Level.trace,
  );

  static void configure({
    required AppLogStore store,
    AppLogLevel captureMinLevel = AppLogLevel.debug,
    bool consoleEnabled = true,
  }) {
    _store = store;
    _captureMin = captureMinLevel;
    _consoleEnabled = consoleEnabled && kDebugMode;
    Logger.level = Level.trace;
  }

  static void setCaptureMinLevel(AppLogLevel level) {
    _captureMin = level;
  }

  static void setConsoleEnabled(bool enabled) {
    _consoleEnabled = enabled && kDebugMode;
  }

  static void verbose(String message, {String? tag}) =>
      _log(AppLogLevel.verbose, message, tag: tag);

  static void debug(String message, {String? tag}) =>
      _log(AppLogLevel.debug, message, tag: tag);

  static void info(String message, {String? tag}) =>
      _log(AppLogLevel.info, message, tag: tag);

  static void warning(String message, {Object? error, String? tag}) =>
      _log(AppLogLevel.warning, message, error: error, tag: tag);

  static void error(
    String message, [
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  ]) =>
      _log(
        AppLogLevel.error,
        message,
        error: error,
        stackTrace: stackTrace,
        tag: tag,
      );

  static void _log(
    AppLogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    if (_consoleEnabled) {
      switch (level) {
        case AppLogLevel.verbose:
          _logger.t(_formatConsole(message, tag));
          break;
        case AppLogLevel.debug:
          _logger.d(_formatConsole(message, tag));
          break;
        case AppLogLevel.info:
          _logger.i(_formatConsole(message, tag));
          break;
        case AppLogLevel.warning:
          _logger.w(_formatConsole(message, tag), error: error);
          break;
        case AppLogLevel.error:
          _logger.e(
            _formatConsole(message, tag),
            error: error,
            stackTrace: stackTrace,
          );
          break;
      }
    }

    if (!level.isAtLeast(_captureMin)) return;
    final store = _store;
    if (store == null) return;

    store.add(
      AppLogEntry(
        timestamp: DateTime.now(),
        level: level,
        message: message,
        tag: tag,
        errorText: error?.toString(),
        stackTraceText: stackTrace?.toString(),
      ),
    );
  }

  static String _formatConsole(String message, String? tag) {
    if (tag == null || tag.isEmpty) return message;
    return '[$tag] $message';
  }
}
