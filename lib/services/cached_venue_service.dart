import '../core/api_exception.dart';
import '../core/api_response.dart';
import '../core/database/sync_status_dao.dart';
import '../core/database/venue_cache.dart';
import '../core/offline_state.dart';
import '../models/time_slot.dart';
import '../models/venue.dart';
import '../models/venue_details.dart';
import '../models/venue_filters.dart';
import 'venue_service.dart';

/// Wraps another VenueService with the on-device cache (SRS FR-34).
///
/// Network first: a successful response is returned and written to the
/// cache. When the request fails, the cached copy is served instead and
/// the app is flagged offline.
class CachedVenueService implements VenueService {
  CachedVenueService(
    this._remote, {
    VenueCache? cache,
    SyncStatusDao? syncStatus,
  })  : _cache = cache ?? const VenueCache(),
        _syncStatus = syncStatus ?? const SyncStatusDao();

  final VenueService _remote;
  final VenueCache _cache;
  final SyncStatusDao _syncStatus;

  @override
  Future<ApiResponse<List<Venue>>> search(
    VenueFilters filters, {
    int page = 1,
  }) async {
    try {
      final ApiResponse<List<Venue>> response =
          await _remote.search(filters, page: page);

      final List<Venue>? venues = response.data;

      // Only the first page is cached.
      if (response.success && venues != null && page == 1) {
        await _cache.saveVenues(venues);
        await _syncStatus.markSynced(SyncResource.venues);
        OfflineState.markOnline(DateTime.now());
      }

      return response;
    } on ApiException {
      final List<Venue> cached = await _cache.readVenues(filters);

      if (cached.isEmpty) {
        rethrow;
      }

      OfflineState.markOffline();

      return ApiResponse<List<Venue>>(
        success: true,
        message: '',
        data: cached,
      );
    }
  }

  @override
  Future<ApiResponse<VenueDetails>> details(
    int venueId, {
    DateTime? date,
  }) async {
    final DateTime day = date ?? DateTime.now();

    try {
      final ApiResponse<VenueDetails> response =
          await _remote.details(venueId, date: day);

      final VenueDetails? venueDetails = response.data;

      if (response.success && venueDetails != null) {
        await _cache.saveVenueDetails(venueDetails, day);
        OfflineState.markOnline(DateTime.now());
      }

      return response;
    } on ApiException {
      final VenueDetails? cached =
          await _cache.readVenueDetails(venueId, day);

      if (cached == null) {
        rethrow;
      }

      OfflineState.markOffline();

      return ApiResponse<VenueDetails>(
        success: true,
        message: '',
        data: cached,
      );
    }
  }

  /// Availability must be fetched from the server because a slot
  /// may already have been booked.
  @override
  Future<ApiResponse<List<TimeSlot>>> timeSlots(
    int venueId, {
    required DateTime date,
    required int sportId,
  }) {
    return _remote.timeSlots(
      venueId,
      date: date,
      sportId: sportId,
    );
  }

  @override
  Future<ApiResponse<List<Venue>>> favorites() async {
    // Favourites are personal and are not cached.
    final ApiResponse<List<Venue>> response =
        await _remote.favorites();

    if (response.success) {
      OfflineState.markOnline(DateTime.now());
    }

    return response;
  }

  @override
  Future<ApiResponse<Venue>> toggleFavorite(
    int venueId, {
    required bool isFavorite,
  }) {
    // Writes cannot be served from the cache.
    return _remote.toggleFavorite(
      venueId,
      isFavorite: isFavorite,
    );
  }
}
