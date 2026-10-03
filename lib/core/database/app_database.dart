import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// The on-device database behind the offline cache (SRS FR-34).
///
/// Reference data is stored as a JSON blob per row rather than a column per
/// field. The venue contract is not final yet, so a normalised schema would
/// need a migration every time the backend renames something; a blob only
/// needs the model's fromJson to change, which is where that knowledge
/// already lives.
class AppDatabase {
  AppDatabase._();

  static const String _fileName = 'playvo.db';
  static const int _version = 1;

  /// Cached reference data, keyed by row id.
  static const String tableVenues = 'venues';

  /// One row per venue id holding its full details payload.
  static const String tableVenueDetails = 'venue_details';

  /// Lists that are not per-venue: cities, sports.
  static const String tableReference = 'reference_data';

  /// SRS FR-35: when each resource was last refreshed.
  static const String tableSyncStatus = 'sync_status';

  static Database? _database;

  static Future<Database> open() async {
    final Database? existing = _database;
    if (existing != null) {
      return existing;
    }

    final String path = p.join(await getDatabasesPath(), _fileName);
    final Database database = await openDatabase(
      path,
      version: _version,
      onCreate: _createSchema,
    );
    _database = database;
    return database;
  }

  static Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableVenues (
        id INTEGER PRIMARY KEY,
        payload TEXT NOT NULL,
        position INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE $tableVenueDetails (
        venue_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        payload TEXT NOT NULL,
        PRIMARY KEY (venue_id, date)
      )
    ''');
    await db.execute('''
      CREATE TABLE $tableReference (
        key TEXT PRIMARY KEY,
        payload TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE $tableSyncStatus (
        resource TEXT PRIMARY KEY,
        last_synced_at TEXT NOT NULL
      )
    ''');
  }

  /// Used by tests and by "clear cache" in settings.
  static Future<void> wipe() async {
    final Database db = await open();
    await db.delete(tableVenues);
    await db.delete(tableVenueDetails);
    await db.delete(tableReference);
    await db.delete(tableSyncStatus);
  }

  static Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
