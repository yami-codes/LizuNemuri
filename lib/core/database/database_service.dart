import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:lizunemu/utils/logger.dart';
import 'package:lizunemu/common/constants/log_strings.dart';

class DatabaseService {
  static const _databaseName = 'lizunemu.db';
  static const _databaseVersion = 3;

  // Schema DDL in one place shared by `_onCreate` (fresh install) and `_migrations` (upgrades).
  static const _createUserSubtitlesTable = '''
      CREATE TABLE user_subtitles (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        work_id       TEXT    NOT NULL,
        file_name     TEXT    NOT NULL,
        subtitle_path TEXT    NOT NULL,
        original_name TEXT,
        format        TEXT    NOT NULL,
        created_at    INTEGER NOT NULL,
        UNIQUE(work_id, file_name)
      )
    ''';

  // file_key = stable identity digest. UNIQUE on file_key, not display file_name.
  static const _createDownloadsTable = '''
      CREATE TABLE downloads (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        work_id     TEXT    NOT NULL,
        file_key    TEXT    NOT NULL,
        file_name   TEXT    NOT NULL,
        file_path   TEXT    NOT NULL,
        media_type  TEXT    NOT NULL,
        source_url  TEXT    NOT NULL,
        size        INTEGER NOT NULL DEFAULT 0,
        created_at  INTEGER NOT NULL,
        UNIQUE(work_id, file_key)
      )
    ''';

  static const _createLocalAlbumsTable = '''
      CREATE TABLE local_albums (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        album_key    TEXT    NOT NULL UNIQUE,
        title        TEXT    NOT NULL,
        artist       TEXT,
        folder_path  TEXT    NOT NULL,
        track_count  INTEGER NOT NULL DEFAULT 0,
        scanned_at   INTEGER NOT NULL
      )
    ''';

  static const _createLocalTracksTable = '''
      CREATE TABLE local_tracks (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        album_id     INTEGER NOT NULL,
        title        TEXT    NOT NULL,
        file_path    TEXT    NOT NULL UNIQUE,
        track_order  INTEGER NOT NULL DEFAULT 0,
        scanned_at   INTEGER NOT NULL,
        FOREIGN KEY(album_id) REFERENCES local_albums(id) ON DELETE CASCADE
      )
    ''';

  // Cache Future<Database>, not Database: concurrent first access shares one in-flight _open().
  Future<Database>? _databaseFuture;

  Future<Database> get database => _databaseFuture ??= _open();

  Future<Database> _open() async {
    try {
      return await _initDatabase();
    } catch (e) {
      // Clear cache on open failure so the next access can retry.
      _databaseFuture = null;
      rethrow;
    }
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);
    AppLogger.debug(LogStrings.logInitDatabasePath557d5(path));

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Fresh install: sqflite calls onCreate only — build the full current schema here.
  /// New tables go in both `_onCreate` and `_migrations`.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute(_createUserSubtitlesTable);
    await db.execute(_createDownloadsTable);
    await db.execute(_createLocalAlbumsTable);
    await db.execute(_createLocalTracksTable);
    AppLogger.debug(LogStrings.logDatabaseTablesCreatedVVersiofa44c(version));
  }

  /// Ordered migrations map: version → upgrade step from (version-1). Bump [_databaseVersion],
  /// update `_onCreate`, and add a migration entry for existing installs.
  static final Map<int, Future<void> Function(Database db)> _migrations = {
    // v1 created by _onCreate; no migration.
    // v2: add downloads table. v1 DBs migrate here; fresh installs get it from _onCreate.
    2: (db) async {
      await db.execute(_createDownloadsTable);
    },
    3: (db) async {
      await db.execute(_createLocalAlbumsTable);
      await db.execute(_createLocalTracksTable);
    },
  };

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    AppLogger.debug(LogStrings.logDatabaseUpgradeOldversionNe5cef7(oldVersion, newVersion));
    for (var v = oldVersion + 1; v <= newVersion; v++) {
      final migration = _migrations[v];
      if (migration != null) {
        AppLogger.debug(LogStrings.logApplyDbMigrationVV368dc(v));
        await migration(db);
      }
    }
  }

  Future<void> close() async {
    final future = _databaseFuture;
    _databaseFuture = null;
    if (future == null) return;
    try {
      final db = await future;
      await db.close();
    } catch (e) {
      AppLogger.error(LogStrings.logCloseDatabaseFailed3f1be, e);
    }
  }
}
