import '../core/api_client.dart';
import '../core/api_response.dart';
import '../core/app_config.dart';
import '../models/booking.dart';
import 'mock_booking_service.dart';

/// Creating a reservation and sending its payment proof
/// (`POST /bookings` and `POST /bookings/{id}/payment-receipt`).
///
/// Both calls are authenticated: the Postman collection sends a bearer
/// token on each.
abstract class BookingService {
  /// Picked the same way as the venue service, so both sides of the flow
  /// are either live or mocked, never a mix.
  factory BookingService.create() =>
      AppConfig.useMockVenues ? MockBookingService() : ApiBookingService();

  /// `GET /bookings` — the player's own reservations, newest first.
  ///
  /// [sportType] narrows the list to one sport (SRS FR-14); null means all.
  Future<ApiResponse<List<Booking>>> myBookings({
    int page = 1,
    String? sportType,
  });

  /// Cancels a reservation and frees its slot.
  Future<ApiResponse<Booking>> cancel(int bookingId);

  /// SRS FR-13. Sends the player's rating for a finished booking.
  Future<ApiResponse<void>> rate({
    required int bookingId,
    required int stars,
    required List<String> tags,
    required String notes,
  });

  Future<ApiResponse<Booking>> createBooking({
    required int timeSlotId,
    required String captainName,
    required String captainRole,
    required String captainPhone,
  });

  /// Uploads the bank transfer receipt as multipart form data under the
  /// field name `receipt`.
  Future<ApiResponse<Booking>> uploadPaymentReceipt({
    required int bookingId,
    required String filePath,
  });
}

/// The real implementation, wired to the paths in the Postman collection.
class ApiBookingService implements BookingService {
  ApiBookingService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  @override
  Future<ApiResponse<List<Booking>>> myBookings({
    int page = 1,
    String? sportType,
  }) {
    return _client.get<List<Booking>>(
      '/bookings',
      authenticated: true,
      query: <String, String>{
        'page': '$page',
        if (sportType != null) 'sport_type': sportType,
      },
      parseData: (dynamic data) {
        // Laravel returns either a bare array or a paginated envelope.
        final List<dynamic> items = data is Map<String, dynamic>
            ? (data['data'] as List<dynamic>? ?? <dynamic>[])
            : (data as List<dynamic>);
        return items
            .map((dynamic b) => Booking.fromJson(b as Map<String, dynamic>))
            .toList();
      },
    );
  }

  /// TODO(api): no cancel endpoint appears in the Postman collection.
  /// Confirm the verb and path with the backend.
  @override
  Future<ApiResponse<Booking>> cancel(int bookingId) {
    return _client.post<Booking>(
      '/bookings/$bookingId/cancel',
      authenticated: true,
      parseData: (dynamic data) =>
          Booking.fromJson(data as Map<String, dynamic>),
    );
  }

  /// TODO(api): the body is a best guess — the endpoint is in the backend's
  /// list but its contract has not been shared. Confirm the field names
  /// (`stars`/`rating`, `tags`, `comment`/`notes`) before release; they are
  /// all in this one method.
  @override
  Future<ApiResponse<void>> rate({
    required int bookingId,
    required int stars,
    required List<String> tags,
    required String notes,
  }) {
    return _client.post<void>(
      '/bookings/$bookingId/rating',
      authenticated: true,
      body: <String, dynamic>{
        'rating': stars,
        'tags': tags,
        if (notes.isNotEmpty) 'comment': notes,
      },
    );
  }

  @override
  Future<ApiResponse<Booking>> createBooking({
    required int timeSlotId,
    required String captainName,
    required String captainRole,
    required String captainPhone,
  }) {
    return _client.post<Booking>(
      '/bookings',
      authenticated: true,
      body: <String, dynamic>{
        'time_slot_id': timeSlotId,
        'captain_name': captainName,
        'captain_role': captainRole,
        'captain_phone': captainPhone,
      },
      parseData: (dynamic data) =>
          Booking.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<ApiResponse<Booking>> uploadPaymentReceipt({
    required int bookingId,
    required String filePath,
  }) {
    return _client.postFile<Booking>(
      '/bookings/$bookingId/payment-receipt',
      field: 'receipt',
      filePath: filePath,
      parseData: (dynamic data) =>
          Booking.fromJson(data as Map<String, dynamic>),
    );
  }
}
