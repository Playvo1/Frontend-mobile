import '../core/api_response.dart';
import '../models/booking.dart';
import '../models/time_slot.dart';
import '../models/venue.dart';
import 'booking_service.dart';

/// Stands in for `/bookings` while the endpoint is being finished, so the
/// booking flow can be walked end to end without a backend.
///
/// Selected by `AppConfig.useMockVenues`, alongside [MockVenueService].
class MockBookingService implements BookingService {
  MockBookingService();

  int _nextId = 18;

  /// One booking per status, so all three card states can be reviewed.
  late final List<Booking> _bookings = <Booking>[
    Booking(
      id: 258731,
      status: BookingStatus.confirmed,
      venue: _venue('ملعب الوحدة', 'الرمال', 'assets/venues/venue_5.jpg'),
      slot: const TimeSlot(
        id: 1,
        startTime: '10:00',
        endTime: '11:00',
        isAvailable: false,
        price: 50,
      ),
      date: DateTime.now().add(const Duration(days: 3)),
      totalPrice: 50,
    ),
    Booking(
      id: 245890,
      status: BookingStatus.completed,
      venue: _venue('ملعب فلسطين', 'الرمال', 'assets/venues/venue_3.jpg'),
      slot: const TimeSlot(
        id: 2,
        startTime: '20:00',
        endTime: '21:00',
        isAvailable: false,
        price: 50,
      ),
      date: DateTime.now().subtract(const Duration(days: 9)),
      totalPrice: 50,
    ),
    Booking(
      id: 240112,
      status: BookingStatus.cancelled,
      venue: _venue('ملعب الشباب', 'الرمال', 'assets/venues/venue_4.jpg'),
      slot: const TimeSlot(
        id: 3,
        startTime: '19:00',
        endTime: '20:00',
        isAvailable: true,
        price: 50,
      ),
      date: DateTime.now().subtract(const Duration(days: 13)),
      totalPrice: 50,
    ),
  ];

  static Venue _venue(String name, String area, String photo) {
    return Venue(
      id: name.hashCode,
      name: name,
      city: 'غزة',
      area: area,
      sportType: SportType.football,
      rating: 4.8,
      reviewCount: 128,
      hourlyPrice: 50,
      photos: <String>[photo],
    );
  }

  @override
  Future<ApiResponse<List<Booking>>> myBookings() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return ApiResponse<List<Booking>>(
      success: true,
      message: '',
      data: List<Booking>.of(_bookings),
    );
  }

  @override
  Future<ApiResponse<Booking>> cancel(int bookingId) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final int index = _bookings.indexWhere((Booking b) => b.id == bookingId);
    final Booking original = _bookings[index];
    final Booking cancelled = Booking(
      id: original.id,
      status: BookingStatus.cancelled,
      venue: original.venue,
      slot: original.slot,
      date: original.date,
      totalPrice: original.totalPrice,
    );
    _bookings[index] = cancelled;
    return ApiResponse<Booking>(success: true, message: '', data: cancelled);
  }

  @override
  Future<ApiResponse<Booking>> createBooking({
    required int timeSlotId,
    required String captainName,
    required String captainRole,
    required String captainPhone,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return ApiResponse<Booking>(
      success: true,
      message: '',
      data: Booking(id: _nextId++, status: BookingStatus.pending),
    );
  }

  @override
  Future<ApiResponse<Booking>> uploadPaymentReceipt({
    required int bookingId,
    required String filePath,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return ApiResponse<Booking>(
      success: true,
      message: '',
      data: Booking(id: bookingId, status: BookingStatus.pending),
    );
  }
}

/// Answers with no bookings at all, so the empty state of "حجوزاتي" can be
/// reviewed without emptying the sample data.
class EmptyBookingService extends MockBookingService {
  EmptyBookingService();

  @override
  Future<ApiResponse<List<Booking>>> myBookings() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return const ApiResponse<List<Booking>>(
      success: true,
      message: '',
      data: <Booking>[],
    );
  }
}
