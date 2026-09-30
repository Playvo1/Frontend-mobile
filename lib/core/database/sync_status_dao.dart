import 'package:sqflite/sqflite.dart';

import 'app_database.dart';

/// The resources the app caches, used as keys in the sync table.
class SyncResource {
  SyncResource._();

  static const String venues = 'venues';
  static const String cities = 'cities';
  static const String sports = 'sports';
}

/// Reads and writes the last-refreshed timestamp per resource
/// (SRS FR-35, which requires that time to be visible to the player).
class SyncStatusDao {
  const SyncStatusDao();

  Future<void> markSynced(String resource, {DateTime? at}) async {
    final Database db = await AppDatabase.open();
    await db.insert(
      AppDatabase.tableSyncStatus,
      <String, Object?>{
        'resource': resource,
        'last_synced_at': (at ?? DateTime.now()).toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<DateTime?> lastSyncedAt(String resource) async {
    final Database db = await AppDatabase.open();
    final List<Map<String, Object?>> rows = await db.query(
      AppDatabase.tableSyncStatus,
      where: 'resource = ?',
      whereArgs: <Object?>[resource],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return DateTime.tryParse(rows.first['last_synced_at']! as String);
  }

  /// The newest timestamp across every resource — what the offline screen
  /// shows as "آخر تحديث".
  Future<DateTime?> lastSyncedAtAny() async {
    final Database db = await AppDatabase.open();
    final List<Map<String, Object?>> rows = await db.query(
      AppDatabase.tableSyncStatus,
      orderBy: 'last_synced_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return DateTime.tryParse(rows.first['last_synced_at']! as String);
  }
}
