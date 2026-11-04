
import '../core/api_response.dart';
import '../models/time_slot.dart';
import '../models/venue.dart';
import '../models/venue_details.dart';
import '../models/venue_filters.dart';
import '../services/venue_service.dart';

/// DEV ONLY: Sample venues for local development and UI review.
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

  final Set<int> _favoriteIds = <int>{};

  @override
  Future<ApiResponse<List<Venue>>> search(
    VenueFilters filters, {
    int page = 1,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final List<Venue> matching = _venues
        .where(filters.matches)
        .map(
          (Venue venue) =>
              venue.copyWith(isFavorite: _favoriteIds.contains(venue.id)),
        )
        .toList(growable: false);

    return ApiResponse<List<Venue>>(
      success: true,
      message: 'Venues retrieved successfully',
      data: matching,
    );
  }

  @override
  Future<ApiResponse<VenueDetails>> details(
    int venueId, {
    DateTime? date,
  }) async {
    final int index = _venues.indexWhere((Venue venue) => venue.id == venueId);

    if (index == -1) {
      return ApiResponse<VenueDetails>.failure('Venue not found');
    }

    // The mock venue details model may contain fields not represented by
    // the Venue model. Keep this method aligned with VenueDetails.fromJson.
    return ApiResponse<VenueDetails>.failure(
      'Venue details are not configured in mock mode',
    );
  }

  @override
  Future<ApiResponse<List<TimeSlot>>> timeSlots(
    int venueId, {
    required DateTime date,
    required int sportId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final bool venueExists = _venues.any((Venue venue) => venue.id == venueId);

    if (!venueExists) {
      return ApiResponse<List<TimeSlot>>.failure('Venue not found');
    }

    return ApiResponse<List<TimeSlot>>(
      success: true,
      message: 'Time slots retrieved successfully',
      data: <TimeSlot>[
        const TimeSlot(
          id: 1,
          startTime: '17:00',
          endTime: '18:00',
          isAvailable: true,
          price: 50,
        ),
        const TimeSlot(
          id: 2,
          startTime: '18:00',
          endTime: '19:00',
          isAvailable: true,
          price: 50,
        ),
        const TimeSlot(
          id: 3,
          startTime: '19:00',
          endTime: '20:00',
          isAvailable: false,
          price: 50,
        ),
      ],
    );
  }

  @override
  Future<ApiResponse<List<Venue>>> favorites() async {
    final List<Venue> matching = _venues
        .where((Venue venue) => _favoriteIds.contains(venue.id))
        .map((Venue venue) => venue.copyWith(isFavorite: true))
        .toList(growable: false);

    return ApiResponse<List<Venue>>(
      success: true,
      message: 'Favorites retrieved successfully',
      data: matching,
    );
  }

  @override
  Future<ApiResponse<Venue>> toggleFavorite(
    int venueId, {
    required bool isFavorite,
  }) async {
    final int index = _venues.indexWhere((Venue venue) => venue.id == venueId);

    if (index == -1) {
      return ApiResponse<Venue>.failure('Venue not found');
    }

    if (isFavorite) {
      _favoriteIds.add(venueId);
    } else {
      _favoriteIds.remove(venueId);
    }

    return ApiResponse<Venue>(
      success: true,
      message: 'Favorite updated successfully',
      data: _venues[index].copyWith(isFavorite: isFavorite),
    );
  }
}
