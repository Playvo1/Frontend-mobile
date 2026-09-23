import '../core/api_client.dart';
import '../core/api_response.dart';
import '../core/app_config.dart';
import '../models/venue.dart';
import '../models/venue_filters.dart';
import 'mock_venue_service.dart';

/// Reads venues for the home and search screens.
///
/// Abstract so the screens can be driven by the mock implementation while
/// the venue endpoints are still being built, and so they stay testable
/// without a network (Guidelines 2.5).
abstract class VenueService {
  /// The implementation the app should use, decided by
  /// [AppConfig.useMockVenues] so screens never choose for themselves.
  factory VenueService.create() =>
      AppConfig.useMockVenues ? MockVenueService() : ApiVenueService();

  /// Venues matching [filters], nearest first.
  Future<ApiResponse<List<Venue>>> search(VenueFilters filters);

  /// SRS FR-17. Returns the venue as the server now holds it.
  Future<ApiResponse<Venue>> toggleFavorite(int venueId, {required bool isFavorite});
}

/// The real implementation.
///
/// TODO(api): the venue endpoints are not in the Guidelines yet. Confirm
/// the path, the query parameter names in [VenueFilters.toQueryParameters],
/// and the venue JSON keys in [Venue.fromJson] with the backend before
/// switching the home screen over from the mock.
class ApiVenueService implements VenueService {
  ApiVenueService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  @override
  Future<ApiResponse<List<Venue>>> search(VenueFilters filters) {
    return _client.get<List<Venue>>(
      '/venues',
      query: filters.toQueryParameters(),
      authenticated: true,
      parseData: (dynamic data) => (data as List<dynamic>)
          .map((dynamic item) => Venue.fromJson(item as Map<String, dynamic>))
          .toList(),
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
}
