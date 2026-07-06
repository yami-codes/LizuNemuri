import 'package:flutter_test/flutter_test.dart';
import 'package:lizunemu/core/logging/app_log_entry.dart';
import 'package:lizunemu/core/logging/app_log_level.dart';
import 'package:lizunemu/core/logging/app_log_store.dart';

AppLogEntry _entry(
  AppLogLevel level,
  String message, {
  String? tag,
}) {
  return AppLogEntry(
    timestamp: DateTime(2026, 7, 6, 12, 0, 0),
    level: level,
    message: message,
    tag: tag,
  );
}

void main() {
  test('ring buffer drops oldest entries beyond maxEntries', () {
    final store = AppLogStore(maxEntries: 3);
    store.add(_entry(AppLogLevel.info, 'a'));
    store.add(_entry(AppLogLevel.info, 'b'));
    store.add(_entry(AppLogLevel.info, 'c'));
    store.add(_entry(AppLogLevel.info, 'd'));

    expect(store.count, 3);
    expect(store.entries.map((e) => e.message).toList(), ['b', 'c', 'd']);
  });

  test('filtered respects minimum level and query', () {
    final store = AppLogStore();
    store.add(_entry(AppLogLevel.debug, 'playback ok', tag: 'playback'));
    store.add(_entry(AppLogLevel.error, 'network fail', tag: 'network'));
    store.add(_entry(AppLogLevel.warning, 'subtitle missing', tag: 'subtitle'));

    expect(
      store.filtered(minimum: AppLogLevel.warning).map((e) => e.message),
      ['network fail', 'subtitle missing'],
    );

    expect(
      store.filtered(query: 'subtitle').map((e) => e.message),
      ['subtitle missing'],
    );

    expect(
      store.filtered(query: 'playback').map((e) => e.message),
      ['playback ok'],
    );
  });

  test('exportText formats visible entries', () {
    final store = AppLogStore();
    store.add(
      AppLogEntry(
        timestamp: DateTime.parse('2026-07-06T12:00:00.000'),
        level: AppLogLevel.error,
        message: 'play failed',
        tag: 'playback',
        errorText: 'SocketException',
        stackTraceText: '#0 main',
      ),
    );

    final text = store.exportText(minimum: AppLogLevel.verbose);
    expect(text, contains('[ERROR] [playback] play failed'));
    expect(text, contains('error: SocketException'));
    expect(text, contains('#0 main'));
  });

  test('clear removes all entries', () {
    final store = AppLogStore();
    store.add(_entry(AppLogLevel.info, 'one'));
    store.clear();
    expect(store.count, 0);
  });
}
