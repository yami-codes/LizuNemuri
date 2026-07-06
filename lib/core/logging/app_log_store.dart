import 'package:flutter/foundation.dart';
import 'package:lizunemu/core/logging/app_log_entry.dart';
import 'package:lizunemu/core/logging/app_log_level.dart';

/// Ring buffer of recent logs for Settings → Diagnostic logs.
class AppLogStore extends ChangeNotifier {
  static const defaultMaxEntries = 2500;

  final int maxEntries;
  final List<AppLogEntry> _entries = [];

  AppLogStore({this.maxEntries = defaultMaxEntries});

  int get count => _entries.length;

  List<AppLogEntry> get entries => List.unmodifiable(_entries);

  void add(AppLogEntry entry) {
    _entries.add(entry);
    if (_entries.length > maxEntries) {
      _entries.removeRange(0, _entries.length - maxEntries);
    }
    notifyListeners();
  }

  List<AppLogEntry> filtered({
    AppLogLevel minimum = AppLogLevel.verbose,
    String? query,
  }) {
    final q = query?.trim().toLowerCase();
    return [
      for (final entry in _entries)
        if (entry.level.isAtLeast(minimum) &&
            (q == null ||
                q.isEmpty ||
                entry.message.toLowerCase().contains(q) ||
                (entry.tag?.toLowerCase().contains(q) ?? false) ||
                (entry.errorText?.toLowerCase().contains(q) ?? false)))
          entry,
    ];
  }

  /// Newest first.
  List<AppLogEntry> filteredNewestFirst({
    AppLogLevel minimum = AppLogLevel.verbose,
    String? query,
  }) {
    return filtered(minimum: minimum, query: query).reversed.toList();
  }

  String exportText({
    AppLogLevel minimum = AppLogLevel.verbose,
    String? query,
    bool includeStack = true,
  }) {
    final visible = filtered(minimum: minimum, query: query);
    if (visible.isEmpty) return '';
    final buffer = StringBuffer();
    for (final entry in visible) {
      buffer.writeln(entry.formatLine(includeStack: includeStack));
      buffer.writeln();
    }
    return buffer.toString().trimRight();
  }

  void clear() {
    if (_entries.isEmpty) return;
    _entries.clear();
    notifyListeners();
  }
}
