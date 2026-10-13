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
///
/// Abstract so the screens can run on mock data while the backend is being
/// finished, and so they stay testable without a network (Guidelines 2.5).
abstract class VenueService {
  /// The implementation the app should use. Whichever source is active,
  /// it is wrapped in [CachedVenueService] so every screen gets the
  /// offline fallback without knowing about it.
  factory VenueService.create() => CachedVenueService(
        AppConfig.useMockVenues ? MockVenueService() : ApiVenueService(),
      );

  /// Venues matching [filters].
  Future<ApiResponse<List<Venue>>> search(VenueFilters filters, {int page = 1});

  /// One venue with its photos, amenities and the slots for [date].
  Future<ApiResponse<VenueDetails>> details(int venueId, {DateTime? date});

  /// The bookable hours for one day.
  ///
  /// There is no player-side slots endpoint: the collection has only
  /// `/venue_owner/owner/venues/{id}/time-slots` (POST) and
  /// `/venue_owner/owner/time-slots/{id}` (PUT). What the player can read
  /// is the venue list, where every venue carries its full `time_slots`
  /// array — so the implementation below filters that by date.
  Future<ApiResponse<List<TimeSlot>>> timeSlots(
    int venueId, {
    required DateTime date,
  });

  /// SRS FR-17. The venues the player has hearted.
  Future<ApiResponse<List<Venue>>> favorites();

  /// SRS FR-17. Returns the venue as the server now holds it.
  Future<ApiResponse<Venue>> toggleFavorite(
    int venueId, {
    required bool isFavorite,
  });
}

/// The real implementation, wired to the paths in the Postman collection.
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
      parseData: _parseVenueList,
    );
  }

  @override
  Future<ApiResponse<VenueDetails>> details(int venueId, {DateTime? date}) {
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
  }) async {
    final String wanted = VenueFilters.formatDate(date);

    // Preferred path, kept in case the backend adds it: the collection
    // has no player-side route for slots, only the owner's. It is tried
    // first and falls through quietly while it is missing.
    try {
      final ApiResponse<List<TimeSlot>> response =
          await _client.get<List<TimeSlot>>(
        '/venues/$venueId/time-slots',
        query: <String, String>{'date': wanted},
        parseData: (dynamic data) {
          // Laravel returns either a bare array or a paginated envelope.
          final List<dynamic> items = data is Map<String, dynamic>
              ? (data['data'] as List<dynamic>? ?? <dynamic>[])
              : (data as List<dynamic>);
          return _slotsForDate(items, wanted);
        },
      );
      if (response.success && (response.data?.isNotEmpty ?? false)) {
        return response;
      }
    } on ApiException {
      // Route missing on this deployment; the list below still has them.
    }

    return _slotsFromVenueList(venueId, wanted);
  }

  /// Fallback for deployments where `GET /venues/{id}` omits `time_slots`
  /// but `GET /venues` includes every slot the venue has. The list is read
  /// page by page until the venue turns up, then its slots are filtered
  /// down to the requested day.
  Future<ApiResponse<List<TimeSlot>>> _slotsFromVenueList(
    int venueId,
    String wanted,
  ) async {
    const int maxPages = 5;

    for (int page = 1; page <= maxPages; page++) {
      final ApiResponse<List<TimeSlot>?> response =
          await _client.get<List<TimeSlot>?>(
        _listPath,
        query: <String, String>{'page': page.toString()},
        parseData: (dynamic data) {
          final List<dynamic> venues = data is Map<String, dynamic>
              ? (data['data'] as List<dynamic>? ?? <dynamic>[])
              : (data as List<dynamic>);
          for (final dynamic entry in venues) {
            final Map<String, dynamic> venue = entry as Map<String, dynamic>;
            if (venue['id'] != venueId) {
              continue;
            }
            return _slotsForDate(
              venue['time_slots'] as List<dynamic>? ?? <dynamic>[],
              wanted,
            );
          }
          return null; // Not on this page.
        },
      );

      if (!response.success) {
        return ApiResponse<List<TimeSlot>>(
          success: false,
          message: response.message,
          statusCode: response.statusCode,
        );
      }
      final List<TimeSlot>? found = response.data;
      if (found != null) {
        return ApiResponse<List<TimeSlot>>(
          success: true,
          message: '',
          data: found,
        );
      }
      if (response.hasMorePages != true) {
        break;
      }
    }

    return const ApiResponse<List<TimeSlot>>(
      success: true,
      message: '',
      data: <TimeSlot>[],
    );
  }

  /// Parses raw slot maps and keeps only those on [wanted] (yyyy-MM-dd).
  /// A slot with no `slot_date` is kept, since the endpoint that returns
  /// it was already asked for one day.
  static List<TimeSlot> _slotsForDate(List<dynamic> items, String wanted) {
    final List<TimeSlot> slots = items
        .map((dynamic s) => TimeSlot.fromJson(s as Map<String, dynamic>))
        .where((TimeSlot s) => s.slotDate == null || s.slotDate == wanted)
        .toList();
    slots.sort((TimeSlot a, TimeSlot b) => a.startTime.compareTo(b.startTime));
    return slots;
  }

  @override
  Future<ApiResponse<List<Venue>>> favorites() {
    return _client.get<List<Venue>>(
      // Confirmed by the backend: the list lives at /favorites, not under
      // /venues. Adding and removing still go through the venue.
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
      body: <String, dynamic>{'is_favorite': isFavorite},
      authenticated: true,
      parseData: (dynamic data) => Venue.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Accepts both a bare array and a paginated `{ "data": [...] }` body,
  /// because Laravel resources return one or the other depending on whether
  /// the endpoint paginates.
  static List<Venue> _parseVenueList(dynamic data) {
    final List<dynamic> items = data is Map<String, dynamic>
        ? (data['data'] as List<dynamic>? ?? <dynamic>[])
        : (data as List<dynamic>);
    return items
        .map((dynamic item) => Venue.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
