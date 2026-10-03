import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../models/venue.dart';
import '../../models/venue_details.dart';
import '../../models/venue_filters.dart';
import 'app_database.dart';

/// Stores and reads the venue data the app shows offline.
///
/// The cached list is the last successful search, kept in the order the
/// server returned, because "nearest first" is decided server-side and the
/// device cannot recompute it.
class VenueCache {
  const VenueCache();

  Future<void> saveVenues(List<Venue> venues) async {
    final Database db = await AppDatabase.open();
    await db.transaction((Transaction txn) async {
      await txn.delete(AppDatabase.tableVenues);
      for (int i = 0; i < venues.length; i++) {
        await txn.insert(
          AppDatabase.tableVenues,
          <String, Object?>{
            'id': venues[i].id,
            'payload': jsonEncode(venues[i].toJson()),
            'position': i,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// The cached list, narrowed by [filters] locally so the filter sheet
  /// still does something without a connection.
  Future<List<Venue>> readVenues(VenueFilters filters) async {
    final Database db = await AppDatabase.open();
    final List<Map<String, Object?>> rows = await db.query(
      AppDatabase.tableVenues,
      orderBy: 'position ASC',
    );

    return rows
        .map(
          (Map<String, Object?> row) => Venue.fromJson(
            jsonDecode(row['payload']! as String) as Map<String, dynamic>,
          ),
        )
        .where(filters.matches)
        .toList();
  }

  Future<void> saveVenueDetails(VenueDetails details, DateTime date) async {
    final Database db = await AppDatabase.open();
    await db.insert(
      AppDatabase.tableVenueDetails,
      <String, Object?>{
        'venue_id': details.venue.id,
        'date': VenueFilters.formatDate(date),
        'payload': jsonEncode(details.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Details for one venue on one day, or null when that day was never
  /// fetched — slot availability is per day, so yesterday's copy would be
  /// wrong rather than merely stale.
  Future<VenueDetails?> readVenueDetails(int venueId, DateTime date) async {
    final Database db = await AppDatabase.open();
    final List<Map<String, Object?>> rows = await db.query(
      AppDatabase.tableVenueDetails,
      where: 'venue_id = ? AND date = ?',
      whereArgs: <Object?>[venueId, VenueFilters.formatDate(date)],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return VenueDetails.fromJson(
      jsonDecode(rows.first['payload']! as String) as Map<String, dynamic>,
    );
  }

  /// Cities, sports and anything else that is a plain list of strings.
  Future<void> saveReferenceList(String key, List<String> values) async {
    final Database db = await AppDatabase.open();
    await db.insert(
      AppDatabase.tableReference,
      <String, Object?>{'key': key, 'payload': jsonEncode(values)},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<String>?> readReferenceList(String key) async {
    final Database db = await AppDatabase.open();
    final List<Map<String, Object?>> rows = await db.query(
      AppDatabase.tableReference,
      where: 'key = ?',
      whereArgs: <Object?>[key],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return (jsonDecode(rows.first['payload']! as String) as List<dynamic>)
        .map((dynamic v) => v.toString())
        .toList();
  }
}
