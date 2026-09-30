import '../core/api_client.dart';
import '../core/api_response.dart';
import '../core/app_config.dart';
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

  /// TODO(api): the collection lists `GET /api/v1/venues/1?city_id=...`,
  /// which mixes a path segment with list-style filters. This assumes the
  /// list lives at `/venues` and `/venues/{id}` returns one venue; confirm
  /// with the backend and change these two constants if not.
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
  Future<ApiResponse<List<Venue>>> favorites() {
    return _client.get<List<Venue>>(
      '/venues/favorites',
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
