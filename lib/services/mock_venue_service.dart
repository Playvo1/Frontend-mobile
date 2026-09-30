import '../core/api_response.dart';
import '../models/amenity.dart';
import '../models/time_slot.dart';
import '../models/venue.dart';
import '../models/venue_details.dart';
import '../models/venue_filters.dart';
import 'venue_service.dart';

/// Sample venues used while the venue endpoints are being finished — the
/// SRS plans for exactly this (1.4: "the prototype relies entirely on mock
/// data during development and testing").
///
/// Selected by `AppConfig.useMockVenues`. Delete this file, and that flag,
/// once the real endpoints return data.
class MockVenueService implements VenueService {
  MockVenueService();

  /// The three facilities the result card shows for every mock venue.
  static const List<Amenity> _listAmenities = <Amenity>[
    Amenity(id: 4, name: 'إضاءة', icon: 'lighting'),
    Amenity(id: 1, name: 'موقف سيارات', icon: 'parking'),
    Amenity(id: 3, name: 'غرف تبديل', icon: 'lockers'),
  ];

  final List<Venue> _venues = <Venue>[
    const Venue(
      id: 1,
      name: 'ملعب الوحدة',
      city: 'غزة',
      area: 'الرمال',
      sportType: SportType.football,
      rating: 4.8,
      reviewCount: 128,
      hourlyPrice: 50,
      photos: <String>['assets/venues/venue_5.jpg'],
      isAvailableNow: true,
      amenities: _listAmenities,
    ),
    const Venue(
      id: 2,
      name: 'ملعب فلسطين',
      city: 'غزة',
      area: 'النصر',
      sportType: SportType.football,
      rating: 4.6,
      reviewCount: 89,
      hourlyPrice: 60,
      photos: <String>['assets/venues/venue_3.jpg'],
      isAvailableNow: true,
      amenities: _listAmenities,
    ),
    const Venue(
      id: 3,
      name: 'ملعب الشباب',
      city: 'غزة',
      area: 'الشيخ رضوان',
      sportType: SportType.football,
      rating: 4.5,
      reviewCount: 74,
      hourlyPrice: 70,
      photos: <String>['assets/venues/venue_4.jpg'],
      isAvailableNow: true,
      amenities: _listAmenities,
    ),
    const Venue(
      id: 4,
      name: 'ملعب المينا الرياضي',
      city: 'غزة',
      area: 'المينا',
      sportType: SportType.football,
      rating: 4.8,
      reviewCount: 120,
      hourlyPrice: 50,
      photos: <String>['assets/venues/venue_1.jpg'],
      isAvailableNow: true,
      amenities: _listAmenities,
    ),
    const Venue(
      id: 5,
      name: 'ملعب اليرموك',
      city: 'غزة',
      area: 'اليرموك',
      sportType: SportType.football,
      rating: 4.5,
      reviewCount: 56,
      hourlyPrice: 40,
      photos: <String>['assets/venues/venue_2.jpg'],
      isAvailableNow: true,
      amenities: _listAmenities,
    ),
  ];

  @override
  Future<ApiResponse<List<Venue>>> search(
    VenueFilters filters, {
    int page = 1,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return ApiResponse<List<Venue>>(
      success: true,
      message: '',
      data: _venues.where(filters.matches).toList(growable: false),
    );
  }

  @override
  Future<ApiResponse<VenueDetails>> details(int venueId, {DateTime? date}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final Venue venue = _venues.firstWhere((Venue v) => v.id == venueId);

    return ApiResponse<VenueDetails>(
      success: true,
      message: '',
      data: VenueDetails(
        venue: venue,
        photos: <String>[
          'assets/venues/venue_1.jpg',
          'assets/venues/venue_2.jpg',
          'assets/venues/venue_3.jpg',
          'assets/venues/venue_4.jpg',
          'assets/venues/venue_5.jpg',
        ],
        description:
            'ملعب عشب صناعي بمواصفات عالية، مناسب للمباريات الودية والتدريبات، '
            'مع إضاءة ليلية ومرافق مريحة.',
        amenities: const <Amenity>[
          Amenity(id: 1, name: 'موقف سيارات', icon: 'parking'),
          Amenity(id: 2, name: 'دورات مياه', icon: 'wc'),
          Amenity(id: 3, name: 'غرف تبديل', icon: 'lockers'),
          Amenity(id: 4, name: 'إضاءة ليلية', icon: 'lighting'),
          Amenity(id: 5, name: 'أرضية عشبية', icon: 'turf'),
        ],
        timeSlots: _slotsFor(venue),
      ),
    );
  }

  /// A plausible day: hourly slots with one already taken, so the booked
  /// state can be seen without a backend.
  List<TimeSlot> _slotsFor(Venue venue) {
    const List<String> hours = <String>[
      '09:00',
      '10:00',
      '11:00',
      '13:00',
      '14:00',
      '15:00',
      '16:00',
      '18:00',
    ];

    return List<TimeSlot>.generate(hours.length, (int index) {
      final int hour = int.parse(hours[index].substring(0, 2));
      return TimeSlot(
        id: venue.id * 100 + index,
        startTime: hours[index],
        endTime: '${(hour + 1).toString().padLeft(2, '0')}:00',
        isAvailable: hours[index] != '14:00',
        price: venue.hourlyPrice,
      );
    });
  }

  @override
  Future<ApiResponse<List<Venue>>> favorites() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    // Four are hearted by default so the screen has something to show.
    final List<Venue> favourites = _venues
        .take(4)
        .map((Venue v) => v.copyWith(isFavorite: true))
        .toList();
    return ApiResponse<List<Venue>>(
      success: true,
      message: '',
      data: favourites,
    );
  }

  @override
  Future<ApiResponse<Venue>> toggleFavorite(
    int venueId, {
    required bool isFavorite,
  }) async {
    final int index = _venues.indexWhere((Venue v) => v.id == venueId);
    _venues[index] = _venues[index].copyWith(isFavorite: isFavorite);
    return ApiResponse<Venue>(success: true, message: '', data: _venues[index]);
  }
}
