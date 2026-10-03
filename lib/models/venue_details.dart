import 'amenity.dart';
import 'time_slot.dart';
import 'venue.dart';

/// Everything the venue page shows: the summary card's data plus the
/// description, the amenity tiles, the photo gallery and the slots for the
/// chosen day.
///
/// TODO(api): `GET /venues/{id}` is in the Postman collection with
/// `date`/`hour` query parameters but no documented response body yet.
/// Confirm these keys with the backend; they are read in one place so a
/// rename is a single edit.
class VenueDetails {
  const VenueDetails({
    required this.venue,
    required this.photos,
    required this.amenities,
    required this.timeSlots,
    this.description = '',
  });

  final Venue venue;
  final List<String> photos;
  final List<Amenity> amenities;

  /// The slots for the date that was requested, in order.
  final List<TimeSlot> timeSlots;

  final String description;

  /// Flattens back into the shape [VenueDetails.fromJson] reads, so the
  /// cache stores one payload per venue and day.
  Map<String, dynamic> toJson() => <String, dynamic>{
        ...venue.toJson(),
        'photos': photos,
        'description': description,
        'amenities': amenities.map((Amenity a) => a.toJson()).toList(),
        'time_slots': timeSlots.map((TimeSlot s) => s.toJson()).toList(),
      };

  factory VenueDetails.fromJson(Map<String, dynamic> json) {
    final List<String> photos = (json['photos'] as List<dynamic>? ?? <dynamic>[])
        .map((dynamic p) => p is String ? p : (p as Map<String, dynamic>)['url'].toString())
        .toList();

    return VenueDetails(
      venue: Venue.fromJson(json),
      photos: photos,
      description: json['description'] as String? ?? '',
      amenities: (json['amenities'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic a) => Amenity.fromJson(a as Map<String, dynamic>))
          .toList(),
      timeSlots: (json['time_slots'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic s) => TimeSlot.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}
