import '../core/api_client.dart';
import '../core/api_response.dart';
import '../core/diagnostics.dart';
import '../core/app_config.dart';
import '../models/booking.dart';
import '../models/venue.dart';
import 'mock_booking_service.dart';
import 'venue_service.dart';

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

  /// TODO(api): the player-side list is not in the Postman collection —
  /// only `/venue_owner/owner/bookings` is. The path and the envelope below
  /// follow the owner endpoint, which nests its rows under `data.bookings`.
  /// Confirm `/bookings` with the backend.
  @override
  Future<ApiResponse<List<Booking>>> myBookings({
    int page = 1,
    String? sportType,
  }) async {
    final ApiResponse<List<Booking>> response =
        await _client.get<List<Booking>>(
      '/bookings',
      authenticated: true,
      query: <String, String>{
        'page': '$page',
        if (sportType != null) 'sport_type': sportType,
      },
      parseData: (dynamic data) => _parseBookingList(data),
    );

    Diagnostics.add(
      'GET /bookings p$page -> ${response.statusCode} '
      'success=${response.success} more=${response.hasMorePages} '
      'msg="${response.message}"',
    );

    final List<Booking>? bookings = response.data;
    if (!response.success || bookings == null || bookings.isEmpty) {
      return response;
    }

    return ApiResponse<List<Booking>>(
      success: response.success,
      message: response.message,
      statusCode: response.statusCode,
      hasMorePages: response.hasMorePages,
      data: await _withVenues(bookings),
    );
  }

  /// Finds the rows wherever this deployment put them.
  ///
  /// A list has arrived under four shapes so far — a bare array,
  /// `{data: [...]}`, a paginated `{data: {data: [...]}}`, and the owner
  /// endpoint's `{bookings: {data: [...]}}` — so rather than assume one,
  /// the first list under a known key wins.
  static List<Booking> _parseBookingList(dynamic data) {
    final List<dynamic>? items = _findList(data);

    if (items == null) {
      // An unrecognised shape must not read as "you have no bookings".
      // The console names what actually arrived, so the fix is one line
      // in [_listKeys] rather than an afternoon of guessing.
      Diagnostics.add(
        'bookings: NO LIST FOUND. '
        '${data is Map<String, dynamic> ? 'keys=${data.keys.toList()}' : '${data.runtimeType}'}',
      );
      return <Booking>[];
    }

    final List<Booking> bookings = items
        .map((dynamic b) => Booking.fromJson(b as Map<String, dynamic>))
        .toList();

    // Prints what the server actually sent, so "my booking is missing" can
    // be settled by reading one line instead of guessing between the app,
    // the pagination and the backend.
    Diagnostics.add(
      'bookings parsed: ${bookings.length} '
      'ids=${bookings.map((Booking b) => b.id).toList()}',
    );

    return bookings;
  }

  /// The keys a list has been nested under, in the order they are tried.
  static const List<String> _listKeys = <String>[
    'data',
    'bookings',
    'items',
    'results',
  ];

  static List<dynamic>? _findList(dynamic node, [int depth = 0]) {
    if (node is List) {
      return node;
    }
    // Three levels covers `{data: {bookings: {data: [...]}}}`; deeper than
    // that is a shape worth questioning rather than guessing at.
    if (node is! Map<String, dynamic> || depth >= 3) {
      return null;
    }
    for (final String key in _listKeys) {
      final List<dynamic>? found = _findList(node[key], depth + 1);
      if (found != null) {
        return found;
      }
    }
    return null;
  }

  /// A booking nests its slot but never its venue, so "حجوزاتي" would show
  /// a blank name. The venues are fetched once for the whole page and
  /// matched by `time_slot.venue_id`. A failure here leaves the names
  /// blank rather than failing the list — the booking itself is the point.
  Future<List<Booking>> _withVenues(List<Booking> bookings) async {
    final Set<int> wanted = bookings
        .where((Booking b) => b.venue == null && b.venueId != null)
        .map((Booking b) => b.venueId!)
        .toSet();
    if (wanted.isEmpty) {
      return bookings;
    }

    final Map<int, Venue> byId = await _venuesById(wanted);
    if (byId.isEmpty) {
      return bookings;
    }

    return bookings.map((Booking b) {
      final Venue? venue = b.venue ?? byId[b.venueId];
      return venue == null ? b : b.copyWith(venue: venue);
    }).toList();
  }

  /// Reuses the venue list the slot lookup already caches, so opening
  /// "حجوزاتي" does not page the whole list again on every visit.
  Future<Map<int, Venue>> _venuesById(Set<int> wanted) async {
    final Map<int, Venue> found = <int, Venue>{};

    try {
      final List<Map<String, dynamic>>? venues =
          await ApiVenueService().allVenuesRaw();

      for (final Map<String, dynamic> raw in venues ?? <Map<String, dynamic>>[]) {
        final Object? id = raw['id'];
        if (id is int && wanted.contains(id)) {
          found[id] = Venue.fromJson(raw);
        }
      }
    } on Object {
      // Names are a nicety here; the bookings still render without them.
    }
    return found;
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

  /// `POST /bookings/{id}/rating`, confirmed against the Postman
  /// collection: the body is `{"rating": 5, "comment": "..."}`.
  ///
  /// `tags` is this app's own addition and is not in the contract. Laravel
  /// ignores unvalidated keys, so it is sent and simply dropped until the
  /// backend stores it; nothing in the flow depends on it coming back.
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
  }) async {
    final ApiResponse<Booking> response = await _client.post<Booking>(
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

    // The id created here is what should appear at the top of "حجوزاتي".
    // Printing it next to the ids the list receives turns "my booking is
    // missing" into a comparison instead of a hunt.
    Diagnostics.add(
      'POST /bookings -> ${response.statusCode} success=${response.success} '
      'CREATED id=${response.data?.id} status=${response.data?.status} '
      'msg="${response.message}"',
    );

    if (response.success) {
      // The hour just taken must not keep showing as available to this
      // player, so the cached venue list goes rather than ages out.
      ApiVenueService.invalidateVenueCache();
    }
    return response;
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
