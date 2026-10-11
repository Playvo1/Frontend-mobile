import '../core/api_client.dart';
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

  /// GET /venues/{id}/time-slots
  /// Returns the available hours for one venue, date and sport.
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
  }) {
    return _client.get<List<TimeSlot>>(
      '/venues/$venueId/time-slots',
      query: <String, String>{
        'date': VenueFilters.formatDate(date),
        'sport_id': sportId.toString(),
      },
      parseData: (dynamic data) {
        final List<dynamic> items = data is Map<String, dynamic>
            ? (data['data'] as List<dynamic>? ?? <dynamic>[])
            : (data as List<dynamic>);

        return items
            .map(
              (dynamic slot) =>
                  TimeSlot.fromJson(slot as Map<String, dynamic>),
            )
            .toList();
      },
    );
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