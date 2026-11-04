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
    this.holdExpiresAt,
    this.venueId,
    this.captainName,
    this.captainPhone,
  });

  final int id;

  /// The slot is held until this moment while the player uploads the
  /// transfer receipt; after it passes the server releases the hour.
  final DateTime? holdExpiresAt;

  /// Read off the slot, since a booking never nests its venue.
  final int? venueId;

  final String? captainName;
  final String? captainPhone;

  /// True while the hold is still running, so the payment screen can show
  /// the player how long is left.
  bool get isHoldActive =>
      holdExpiresAt != null && DateTime.now().isBefore(holdExpiresAt!);

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
  Booking copyWith({String? status, bool? isRated, Venue? venue}) {
    return Booking(
      id: id,
      status: status ?? this.status,
      venue: venue ?? this.venue,
      slot: slot,
      date: date,
      totalPrice: totalPrice,
      score: score,
      shareToken: shareToken,
      isRated: isRated ?? this.isRated,
      holdExpiresAt: holdExpiresAt,
      venueId: venueId,
      captainName: captainName,
      captainPhone: captainPhone,
    );
  }

  /// Reads both shapes the backend returns for a booking, confirmed
  /// against the Postman collection:
  ///
  /// * `POST /bookings` answers with `{booking_id, total_price, status}`.
  /// * The bookings list answers with the full row: `id`, `time_slot`,
  ///   `captain`, `result`, `hold_expires_at`, `share_token`.
  ///
  /// Neither nests a venue and neither carries a `date` of its own, so the
  /// day is read off the slot.
  factory Booking.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? venueJson =
        json['venue'] as Map<String, dynamic>?;
    final Map<String, dynamic>? slotJson =
        json['time_slot'] as Map<String, dynamic>?;
    final TimeSlot? slot =
        slotJson == null ? null : TimeSlot.fromJson(slotJson);

    // The create response names the key `booking_id`, the list names it
    // `id`. Reading both keeps one model for the whole flow.
    final Object? rawId = json['id'] ?? json['booking_id'];
    final String? rawDate = (json['date'] ?? slot?.slotDate) as String?;

    return Booking(
      id: rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '') ?? 0,
      status: BookingStatus.normalise(json['status'] as String?),
      venue: venueJson == null ? null : Venue.fromJson(venueJson),
      slot: slot,
      date: rawDate == null ? null : DateTime.tryParse(rawDate),
      // A decimal column, so it arrives as the string "500.00".
      totalPrice: _money(json['total_price']),
      // The owner records the final score in `result`.
      score: (json['result'] ?? json['score'])?.toString(),
      shareToken: json['share_token'] as String?,
      isRated: json['is_rated'] as bool? ?? json['rating'] != null,
      holdExpiresAt:
          DateTime.tryParse(json['hold_expires_at']?.toString() ?? ''),
      venueId: slot?.venueId ?? json['venue_id'] as int?,
      captainName: json['captain_name'] as String?,
      captainPhone: json['captain_phone'] as String?,
    );
  }

  /// Money comes back as a decimal string ("500.00") on every endpoint,
  /// and as a number only in the mock data.
  static int? _money(dynamic raw) {
    if (raw is num) {
      return raw.round();
    }
    return double.tryParse(raw?.toString() ?? '')?.round();
  }
}

/// The fixed BOOKING.status values from the Guidelines (3.1).
class BookingStatus {
  BookingStatus._();

  static const String pending = 'pending';
  static const String confirmed = 'confirmed';
  static const String cancelled = 'cancelled';
  static const String completed = 'completed';

  /// What the server actually sends for a booking whose receipt has not
  /// been verified yet. It means the same as [pending] to every screen.
  static const String pendingPayment = 'pending_payment';

  /// Maps the server's wording onto the four values the screens switch on,
  /// in one place — so a new server spelling is a line here, not a hunt
  /// through the UI. An unknown value is passed through rather than
  /// forced, so it shows up instead of silently reading as "pending".
  static String normalise(String? raw) {
    final String value = (raw ?? '').trim();
    if (value.isEmpty) {
      return pending;
    }
    if (value == pendingPayment || value == 'awaiting_payment') {
      return pending;
    }
    return value;
  }
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
