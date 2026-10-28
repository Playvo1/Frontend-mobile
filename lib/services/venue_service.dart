import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../core/api_response.dart';
import '../core/app_config.dart';
import '../models/time_slot.dart';
import '../models/venue.dart';
import '../models/venue_details.dart';
import '../models/venue_filters.dart';
import 'cached_venue_service.dart';
import 'mock_venue_service.dart';

/// Reads venues for the home, search and details screens.
abstract class VenueService {
  /// The implementation the app should use.
  factory VenueService.create() => CachedVenueService(
        AppConfig.useMockVenues ? MockVenueService() : ApiVenueService(),
      );

  /// Venues matching [filters].
  Future<ApiResponse<List<Venue>>> search(
    VenueFilters filters, {
    int page = 1,
  });

  /// One venue with its photos, amenities and the slots for [date].
  Future<ApiResponse<VenueDetails>> details(
    int venueId, {
    DateTime? date,
  });

  /// `GET /venues/{id}/time-slots` — the available hours for one venue,
  /// date and sport.
  ///
  /// The implementation falls back to reading the hours off the venue list
  /// when that route is not deployed: the Postman collection documents only
  /// the owner-side `/venue_owner/owner/venues/{id}/time-slots`, while every
  /// venue in `GET /venues` already carries its full `time_slots` array.
  Future<ApiResponse<List<TimeSlot>>> timeSlots(
    int venueId, {
    required DateTime date,
    required int sportId,
  });

  /// Returns the venues the player has favorited.
  Future<ApiResponse<List<Venue>>> favorites();

  /// Updates the favorite status of a venue.
  Future<ApiResponse<Venue>> toggleFavorite(
    int venueId, {
    required bool isFavorite,
  });
}

/// Real API implementation.
class ApiVenueService implements VenueService {
  ApiVenueService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// Confirmed. The collection saves this request as
  /// `GET /api/v1/venues/1?city_id=...`, but the response is a paginated
  /// LIST whose own `path` field reads `http://.../api/v1/venues` — so the
  /// trailing `1` is a stray segment in the saved request, not a venue id,
  /// and the list route is `/venues`.
  static const String _listPath = '/venues';

  static String _detailsPath(int id) => '/venues/$id';

  /// The venue list, kept for a few minutes.
  ///
  /// The slot fallback below reads every venue to find one venue's hours,
  /// and the player changes date several times on one screen. Without this
  /// each tap paged the whole list again — the single slowest thing in the
  /// app. The window is short because availability changes, and anything
  /// that books a slot clears it outright.
  static List<Map<String, dynamic>>? _venueCache;
  static DateTime? _venueCachedAt;
  static const Duration _venueCacheTtl = Duration(minutes: 3);

  /// Called after a booking, since a taken hour must not stay "available".
  static void invalidateVenueCache() {
    _venueCache = null;
    _venueCachedAt = null;
  }

  static bool get _isCacheFresh {
    final DateTime? at = _venueCachedAt;
    return _venueCache != null &&
        at != null &&
        DateTime.now().difference(at) < _venueCacheTtl;
  }

  /// The same list the bookings service needs to put a venue name on each
  /// reservation. Sharing it means one fetch serves both.
  Future<List<Map<String, dynamic>>?> allVenuesRaw() => _allVenues();

  /// Every venue, from the cache when it is fresh and from the server
  /// otherwise. Returns null when the list could not be read at all.
  Future<List<Map<String, dynamic>>?> _allVenues() async {
    if (_isCacheFresh) {
      return _venueCache;
    }

    const int maxPages = 5;
    final List<Map<String, dynamic>> collected = <Map<String, dynamic>>[];

    for (int page = 1; page <= maxPages; page++) {
      final ApiResponse<List<Map<String, dynamic>>> response =
          await _client.get<List<Map<String, dynamic>>>(
        _listPath,
        query: <String, String>{'page': page.toString()},
        parseData: (dynamic data) {
          final List<dynamic> venues = data is Map<String, dynamic>
              ? (data['data'] as List<dynamic>? ?? <dynamic>[])
              : (data as List<dynamic>);
          return venues.cast<Map<String, dynamic>>();
        },
      );

      if (!response.success) {
        return null;
      }
      collected.addAll(response.data ?? <Map<String, dynamic>>[]);
      if (response.hasMorePages != true) {
        break;
      }
    }

    _venueCache = collected;
    _venueCachedAt = DateTime.now();
    return collected;
  }

  /// The filters are sent to the server AND applied again here.
  ///
  /// Tested directly against the deployment: `?city_id=999&min_price=99999`
  /// returns exactly the same venues as no filter at all, so the backend
  /// ignores every filter parameter. They are still sent, so the moment it
  /// starts honouring them the server does the narrowing and this pass
  /// simply has nothing left to remove.
  @override
  Future<ApiResponse<List<Venue>>> search(
    VenueFilters filters, {
    int page = 1,
  }) {
    return _client.get<List<Venue>>(
      _listPath,
      query: <String, String>{
        ...filters.toQueryParameters(),
        'page': page.toString(),
      },
      parseData: (dynamic data) => _parseVenueList(data)
          .where((Venue venue) => filters.matches(venue))
          .toList(),
    );
  }

  @override
  Future<ApiResponse<VenueDetails>> details(
    int venueId, {
    DateTime? date,
  }) {
    return _client.get<VenueDetails>(
      _detailsPath(venueId),
      query: <String, String>{
        if (date != null) 'date': VenueFilters.formatDate(date),
      },
      parseData: (dynamic data) =>
          VenueDetails.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<ApiResponse<List<TimeSlot>>> timeSlots(
    int venueId, {
    required DateTime date,
    required int sportId,
  }) async {
    final String wanted = VenueFilters.formatDate(date);

    // The documented path, tried first. On a deployment that does not serve
    // it the call 404s and the venue list below answers instead, so the slot
    // grid fills either way.
    try {
      final ApiResponse<List<TimeSlot>> response =
          await _client.get<List<TimeSlot>>(
        '/venues/$venueId/time-slots',
        query: <String, String>{
          'date': wanted,
          'sport_id': sportId.toString(),
        },
        parseData: (dynamic data) {
          // Laravel returns either a bare array or a paginated envelope.
          final List<dynamic> items = data is Map<String, dynamic>
              ? (data['data'] as List<dynamic>? ?? <dynamic>[])
              : (data as List<dynamic>);
          return _slotsForDate(items, wanted, sportId);
        },
      );
      if (response.success && (response.data?.isNotEmpty ?? false)) {
        return response;
      }
    } on ApiException {
      // Route missing on this deployment; the list below still has them.
    }

    return _slotsFromVenueList(venueId, wanted, sportId);
  }

  /// Fallback for deployments where `GET /venues/{id}` omits `time_slots`
  /// but `GET /venues` includes every slot the venue has. The list is read
  /// page by page until the venue turns up, then its slots are filtered
  /// down to the requested day and sport.
  Future<ApiResponse<List<TimeSlot>>> _slotsFromVenueList(
    int venueId,
    String wanted,
    int sportId,
  ) async {
    final List<Map<String, dynamic>>? venues = await _allVenues();

    if (venues == null) {
      return const ApiResponse<List<TimeSlot>>(
        success: false,
        message: '',
      );
    }

    for (final Map<String, dynamic> venue in venues) {
      if (venue['id'] != venueId) {
        continue;
      }
      return ApiResponse<List<TimeSlot>>(
        success: true,
        message: '',
        data: _slotsForDate(
          venue['time_slots'] as List<dynamic>? ?? <dynamic>[],
          wanted,
          sportId,
        ),
      );
    }

    return const ApiResponse<List<TimeSlot>>(
      success: true,
      message: '',
      data: <TimeSlot>[],
    );
  }

  /// Parses raw slot maps and keeps only those on [wanted] (yyyy-MM-dd) for
  /// [sportId]. A slot missing either field is kept, since the endpoint that
  /// returned it was already asked for one day and one sport.
  static List<TimeSlot> _slotsForDate(
    List<dynamic> items,
    String wanted,
    int sportId,
  ) {
    final List<TimeSlot> slots = items
        .map((dynamic s) => TimeSlot.fromJson(s as Map<String, dynamic>))
        .where((TimeSlot s) => s.slotDate == null || s.slotDate == wanted)
        .where((TimeSlot s) => s.sportId == null || s.sportId == sportId)
        .toList();
    slots.sort((TimeSlot a, TimeSlot b) => a.startTime.compareTo(b.startTime));
    return slots;
  }

  @override
  Future<ApiResponse<List<Venue>>> favorites() {
    return _client.get<List<Venue>>(
      '/favorites',
      authenticated: true,
      parseData: _parseVenueList,
    );
  }

  @override
  Future<ApiResponse<Venue>> toggleFavorite(
    int venueId, {
    required bool isFavorite,
  }) {
    return _client.post<Venue>(
      '/venues/$venueId/favorite',
      body: <String, dynamic>{
        'is_favorite': isFavorite,
      },
      authenticated: true,
      parseData: (dynamic data) =>
          Venue.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Accepts both a bare array and a paginated { "data": [...] } response.
  static List<Venue> _parseVenueList(dynamic data) {
    final List<dynamic> items = data is Map<String, dynamic>
        ? (data['data'] as List<dynamic>? ?? <dynamic>[])
        : (data as List<dynamic>);

    return items
        .map(
          (dynamic item) => Venue.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }
}
