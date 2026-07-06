import 'package:lizunemu/core/logging/app_log_level.dart';

/// One captured log line for the in-app viewer.
class AppLogEntry {
  final DateTime timestamp;
  final AppLogLevel level;
  final String message;
  final String? tag;
  final String? errorText;
  final String? stackTraceText;

  const AppLogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.tag,
    this.errorText,
    this.stackTraceText,
  });

  String formatLine({bool includeStack = true}) {
    final buffer = StringBuffer();
    final ts = timestamp.toIso8601String();
    final tagPart = tag != null && tag!.isNotEmpty ? ' [$tag]' : '';
    buffer.writeln('[$ts] [${level.name.toUpperCase()}]$tagPart $message');
    if (errorText != null && errorText!.trim().isNotEmpty) {
      buffer.writeln('  error: ${errorText!.trim()}');
    }
    if (includeStack &&
        stackTraceText != null &&
        stackTraceText!.trim().isNotEmpty) {
      buffer.writeln('  stack:');
      for (final line in stackTraceText!.trim().split('\n')) {
        buffer.writeln('    $line');
      }
    }
    return buffer.toString().trimRight();
  }
}
