import 'dart:ffi';
import 'dart:io';

import 'package:sqlite3/open.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:lizunemu/utils/platform_capabilities.dart';

/// Selects the correct sqflite factory for web and desktop before any DB open.
Future<void> bootstrapDatabaseFactory() async {
  if (PlatformCapabilities.needsWebSqlite) {
    databaseFactory = databaseFactoryFfiWeb;
    return;
  }
  if (PlatformCapabilities.needsDesktopSqlite) {
    // createDatabaseFactoryFfi invokes [ffiInit] before opening sqlite3 — the
    // hook sqfliteFfiInit() alone does not apply open.overrideFor on Linux.
    databaseFactory = createDatabaseFactoryFfi(ffiInit: _configureDesktopSqliteOpen);
  }
}

/// Desktop distros often ship only `libsqlite3.so.0` (no unversioned `.so`
/// symlink). sqflite_common_ffi defaults to `libsqlite3.so` and fails to open.
void _configureDesktopSqliteOpen() {
  if (Platform.isLinux) {
    open.overrideFor(OperatingSystem.linux, _openSqliteOnLinux);
  } else if (Platform.isWindows) {
    open.overrideFor(OperatingSystem.windows, _openSqliteOnWindows);
  }
}

DynamicLibrary _openSqliteOnLinux() {
  const candidates = ['libsqlite3.so', 'libsqlite3.so.0'];
  Object? lastError;
  for (final name in candidates) {
    try {
      return DynamicLibrary.open(name);
    } on Object catch (e) {
      lastError = e;
    }
  }
  Error.throwWithStackTrace(
    ArgumentError('Could not open SQLite on Linux: $lastError'),
    StackTrace.current,
  );
}

DynamicLibrary _openSqliteOnWindows() {
  const candidates = ['sqlite3.dll', 'sqlite3'];
  Object? lastError;
  for (final name in candidates) {
    try {
      return DynamicLibrary.open(name);
    } on Object catch (e) {
      lastError = e;
    }
  }
  Error.throwWithStackTrace(
    ArgumentError('Could not open SQLite on Windows: $lastError'),
    StackTrace.current,
  );
}
