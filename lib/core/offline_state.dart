import 'package:flutter/foundation.dart';

import 'database/sync_status_dao.dart';

/// Whether the app is currently serving cached data, and when that cache
/// was last refreshed (SRS FR-35).
///
/// It is driven by whether requests actually succeed rather than by a
/// connectivity plugin: a phone can be on Wi-Fi and still not reach the
/// API, and what the player needs to know is whether the data is live.
class OfflineState {
  OfflineState._();

  /// True once a request has failed and the screen fell back to the cache.
  static final ValueNotifier<bool> isOffline = ValueNotifier<bool>(false);

  /// When any resource was last refreshed from the server.
  static final ValueNotifier<DateTime?> lastSyncedAt =
      ValueNotifier<DateTime?>(null);

  static const SyncStatusDao _syncStatus = SyncStatusDao();

  /// Called on launch so the banner and the offline screen have a time to
  /// show before the first request finishes.
  static Future<void> load() async {
    lastSyncedAt.value = await _syncStatus.lastSyncedAtAny();
  }

  static void markOnline(DateTime syncedAt) {
    isOffline.value = false;
    lastSyncedAt.value = syncedAt;
  }

  static void markOffline() {
    isOffline.value = true;
  }
}
