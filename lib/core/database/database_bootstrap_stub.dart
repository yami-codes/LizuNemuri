import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart';

/// Web / WASM sqlite factory (no dart:io / dart:ffi).
Future<void> bootstrapDatabaseFactory() async {
  databaseFactory = databaseFactoryFfiWeb;
}
