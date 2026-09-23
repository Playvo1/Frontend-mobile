import '../core/api_response.dart';
import '../models/venue.dart';
import '../models/venue_filters.dart';
import '../services/venue_service.dart';

/// Sample venues so the home and filter screens can be built and reviewed
/// before the venue endpoints exist — the SRS plans for exactly this
/// (1.4: "the prototype relies entirely on mock data during development").
///
/// DEV ONLY. Delete `lib/dev/` once the real endpoints are connected.
class MockVenueService implements VenueService {
  MockVenueService();

  final List<Venue> _venues = <Venue>[
    const Venue(
      id: 1,
      name: 'ملعب المينا الرياضي',
      city: 'غزة',
      area: 'المينا',
      sportType: SportType.football,
      rating: 4.8,
      reviewCount: 120,
      hourlyPrice: 50,
      photos: <String>['assets/venues/venue_1.jpg'],
      isAvailableNow: true,
    ),
    const Venue(
      id: 2,
      name: 'ملعب اليرموك',
      city: 'غزة',
      area: 'الرمال',
      sportType: SportType.football,
      rating: 4.5,
      reviewCount: 89,
      hourlyPrice: 40,
      photos: <String>['assets/venues/venue_2.jpg'],
      isAvailableNow: true,
    ),
    const Venue(
      id: 3,
      name: 'ملعب فلسطين',
      city: 'غزة',
      area: 'النصر',
      sportType: SportType.football,
      rating: 4.6,
      reviewCount: 74,
      hourlyPrice: 60,
      photos: <String>['assets/venues/venue_3.jpg'],
    ),
    const Venue(
      id: 4,
      name: 'ملعب الشباب',
      city: 'غزة',
      area: 'الشيخ رضوان',
      sportType: SportType.football,
      rating: 4.5,
      reviewCount: 56,
      hourlyPrice: 70,
      photos: <String>['assets/venues/venue_4.jpg'],
      isAvailableNow: true,
    ),
    const Venue(
      id: 5,
      name: 'ملعب الوحدة',
      city: 'غزة',
      area: 'الرمال',
      sportType: SportType.football,
      rating: 4.8,
      reviewCount: 128,
      hourlyPrice: 50,
      photos: <String>['assets/venues/venue_5.jpg'],
    ),
  ];

  @override
  Future<ApiResponse<List<Venue>>> search(VenueFilters filters) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final List<Venue> matching =
        _venues.where(filters.matches).toList(growable: false);
    return ApiResponse<List<Venue>>(
      success: true,
      message: '',
      data: matching,
    );
  }

  @override
  Future<ApiResponse<Venue>> toggleFavorite(
    int venueId, {
    required bool isFavorite,
  }) async {
    final int index = _venues.indexWhere((Venue v) => v.id == venueId);
    _venues[index] = _venues[index].copyWith(isFavorite: isFavorite);
    return ApiResponse<Venue>(
      success: true,
      message: '',
      data: _venues[index],
    );
  }
}
