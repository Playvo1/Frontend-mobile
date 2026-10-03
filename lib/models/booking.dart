import 'time_slot.dart';
import 'venue.dart';

/// A reservation, as the bookings endpoints return it.
class Booking {
  const Booking({
    required this.id,
    required this.status,
    this.venue,
    this.slot,
    this.date,
    this.totalPrice,
  });

  final int id;

  /// One of [BookingStatus].
  final String status;

  /// The venue, when the endpoint nests it — the bookings list does, the
  /// create response does not.
  final Venue? venue;

  final TimeSlot? slot;
  final DateTime? date;
  final int? totalPrice;

  bool get awaitsPaymentProof => status == BookingStatus.pending;

  bool get isUpcoming => status == BookingStatus.pending ||
      status == BookingStatus.confirmed;

  /// "PV258731" — the reference shown to the player.
  String get reference => 'PV${id.toString().padLeft(6, '0')}';

  factory Booking.fromJson(Map<String, dynamic> json) {
    final String? rawDate = json['date'] as String?;
    final Map<String, dynamic>? venueJson =
        json['venue'] as Map<String, dynamic>?;
    final Map<String, dynamic>? slotJson =
        json['time_slot'] as Map<String, dynamic>?;

    return Booking(
      id: json['id'] as int,
      status: json['status'] as String? ?? BookingStatus.pending,
      venue: venueJson == null ? null : Venue.fromJson(venueJson),
      slot: slotJson == null ? null : TimeSlot.fromJson(slotJson),
      date: rawDate == null ? null : DateTime.tryParse(rawDate),
      totalPrice: (json['total_price'] as num?)?.round(),
    );
  }
}

/// The fixed BOOKING.status values from the Guidelines (3.1).
class BookingStatus {
  BookingStatus._();

  static const String pending = 'pending';
  static const String confirmed = 'confirmed';
  static const String cancelled = 'cancelled';
  static const String completed = 'completed';
}

/// What the captain is to the team, sent as `captain_role`.
///
/// TODO(api): the Postman example sends the free string "Captain". Confirm
/// whether the backend validates against a fixed list; if it does, these
/// values must match it exactly.
class CaptainRole {
  CaptainRole._();

  static const String captain = 'Captain';
  static const String player = 'Player';
  static const String organizer = 'Organizer';

  static const List<String> all = <String>[captain, player, organizer];
}
