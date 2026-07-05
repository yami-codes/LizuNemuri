import 'database_bootstrap_stub.dart'
    if (dart.library.io) 'database_bootstrap_io.dart' as impl;

/// Selects the correct sqflite factory for web and desktop before any DB open.
Future<void> bootstrapDatabaseFactory() => impl.bootstrapDatabaseFactory();
