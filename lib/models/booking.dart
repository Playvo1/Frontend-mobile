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
    this.score,
    this.shareToken,
    this.isRated = false,
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

  /// "2 - 3" — the final score, when the owner recorded one.
  final String? score;

  /// Opaque token behind the public link (GET /bookings/share/{token}).
  final String? shareToken;

  /// True once the player has rated this booking, so the prompt is not
  /// shown again.
  final bool isRated;

  /// Whether the slot's end time has passed. A booking is rateable only
  /// after the game, per FR-13.
  bool get hasFinished {
    final DateTime? day = date;
    final String? end = slot?.endTime;
    if (day == null || end == null) {
      return status == BookingStatus.completed;
    }
    final List<String> endParts = end.split(':');
    final int endHour = int.tryParse(endParts.first) ?? 0;
    final int endMinute =
        endParts.length > 1 ? int.tryParse(endParts[1]) ?? 0 : 0;

    // A slot like 22:00 - 01:00 ends on the NEXT day. Without this the end
    // lands in the past the moment the booking is made, and the game counts
    // as finished before it has started.
    final int startHour =
        int.tryParse((slot?.startTime ?? '').split(':').first) ?? 0;
    final int dayOffset = endHour < startHour ? 1 : 0;

    final DateTime endsAt = DateTime(
      day.year,
      day.month,
      day.day + dayOffset,
      endHour,
      endMinute,
    );
    return DateTime.now().isAfter(endsAt);
  }

  /// The prompt is owed when the game is over, the booking was not
  /// cancelled, and no rating has been sent yet.
  bool get awaitsRating =>
      hasFinished && status != BookingStatus.cancelled && !isRated;

  bool get awaitsPaymentProof => status == BookingStatus.pending;

  bool get isUpcoming => status == BookingStatus.pending ||
      status == BookingStatus.confirmed;

  /// "PV258731" — the reference shown to the player.
  String get reference => 'PV${id.toString().padLeft(6, '0')}';

  /// Returns a copy with the given fields replaced. Used where a single
  /// field changes locally, such as marking a booking rated.
  Booking copyWith({String? status, bool? isRated}) {
    return Booking(
      id: id,
      status: status ?? this.status,
      venue: venue,
      slot: slot,
      date: date,
      totalPrice: totalPrice,
      score: score,
      shareToken: shareToken,
      isRated: isRated ?? this.isRated,
    );
  }

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
      score: json['score'] as String?,
      shareToken: json['share_token'] as String?,
      isRated: json['is_rated'] as bool? ?? false,
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
/// The backend accepts `captain_role` as free text (confirmed), so this
/// list is a convenience for the picker rather than a contract: adding a
/// role here needs no backend change.
class CaptainRole {
  CaptainRole._();

  static const String captain = 'Captain';
  static const String player = 'Player';
  static const String organizer = 'Organizer';

  static const List<String> all = <String>[captain, player, organizer];
}
