import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:xuro/utils/platform_capabilities.dart';

/// Selects the correct sqflite factory for web and desktop before any DB open.
Future<void> bootstrapDatabaseFactory() async {
  if (PlatformCapabilities.needsWebSqlite) {
    databaseFactory = databaseFactoryFfiWeb;
    return;
  }
  if (PlatformCapabilities.needsDesktopSqlite) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}
