/// One bookable hour on a venue's calendar (the TIME_SLOT entity).
///
/// `POST /bookings` takes only [id], so this is the object the whole
/// booking flow is built around.
class TimeSlot {
  const TimeSlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
    this.price,
    this.slotDate,
    this.venueId,
    this.sportId,
  });

  final int id;

  /// The venue this hour belongs to. A booking does not nest its venue,
  /// only its slot, so this is the only link back to the venue there.
  final int? venueId;

  final int? sportId;

  /// "2026-10-11" as the server stores it. Needed because the venue list
  /// returns every slot the venue has, not just the requested day's.
  final String? slotDate;

  /// "09:00" as the API returns it, ready to display.
  final String startTime;
  final String endTime;

  /// False for a slot someone already booked — shown greyed as "محجوز".
  final bool isAvailable;

  /// Price for this hour when it differs from the venue's base rate.
  final int? price;

  /// "10:00 - 11:00", the range shown on the summary card.
  String get range => '$startTime - $endTime';

  /// "09:00 AM" — the 12-hour label the slot grid shows.
  String get displayTime {
    final int hour = int.tryParse(startTime.split(':').first) ?? 0;
    final String suffix = hour < 12 ? 'AM' : 'PM';
    final int shown = hour % 12 == 0 ? 12 : hour % 12;
    final String minutes = startTime.split(':').last;
    return '${shown.toString().padLeft(2, '0')}:$minutes $suffix';
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'start_time': startTime,
        'end_time': endTime,
        'is_available': isAvailable,
        'price': price,
        'slot_date': slotDate,
        'venue_id': venueId,
        'sport_id': sportId,
      };

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    // Confirmed against a live response: availability is a `status`
    // string, the price is a decimal string, and times carry seconds.
    final dynamic rawPrice = json['hourly_price'] ?? json['price'];
    final String? status = json['status'] as String?;

    return TimeSlot(
      id: json['id'] as int,
      startTime: _hhmm(json['start_time'] as String? ?? ''),
      endTime: _hhmm(json['end_time'] as String? ?? ''),
      isAvailable: json['is_available'] as bool? ?? status == 'available',
      slotDate: (json['slot_date'] as String?)?.split('T').first,
      venueId: json['venue_id'] as int?,
      sportId: json['sport_id'] as int?,
      price: rawPrice is num
          ? rawPrice.round()
          : double.tryParse(rawPrice?.toString() ?? '')?.round(),
    );
  }

  /// Trims "09:00:00" to "09:00"; leaves an already-short value alone.
  static String _hhmm(String raw) =>
      raw.length >= 5 ? raw.substring(0, 5) : raw;
}
