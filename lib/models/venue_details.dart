import 'amenity.dart';
import 'time_slot.dart';
import 'venue.dart';

/// Everything the venue page shows: the summary card's data plus the
/// description, the amenity tiles, the photo gallery and the slots for the
/// chosen day.
///
/// Reads the shape the backend returns for one venue: the venue's own
/// fields plus `images` and `time_slots`. Descriptions are bilingual like
/// the rest of the text columns.
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

  /// Returns a copy with the slots replaced, used when availability is
  /// refreshed from its own endpoint without refetching the venue.
  VenueDetails copyWith({List<TimeSlot>? timeSlots}) {
    return VenueDetails(
      venue: venue,
      photos: photos,
      description: description,
      amenities: amenities,
      timeSlots: timeSlots ?? this.timeSlots,
    );
  }

  /// Flattens back into the shape [VenueDetails.fromJson] reads, so the
  /// cache stores one payload per venue and day.
  Map<String, dynamic> toJson() => <String, dynamic>{
        ...venue.toJson(),
        'photos': photos,
        'description': description,
        'amenities': amenities.map((Amenity a) => a.toJson()).toList(),
        'time_slots': timeSlots.map((TimeSlot s) => s.toJson()).toList(),
      };

  /// The backend has no description column yet; the bilingual `area`
  /// text is the closest thing the venue page can show.
  static String _description(Map<String, dynamic> json) {
    final Object? raw = json['description_ar'] ??
        json['description_en'] ??
        json['description'];
    return raw?.toString() ?? '';
  }

  factory VenueDetails.fromJson(Map<String, dynamic> json) {
    // The venue parser already resolves `images[].image_url` against the
    // API host, so the gallery reuses that rather than parsing twice.
    final Venue venue = Venue.fromJson(json);

    return VenueDetails(
      venue: venue,
      photos: venue.photos,
      description: _description(json),
      amenities: (json['amenities'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic a) => Amenity.fromJson(a as Map<String, dynamic>))
          .toList(),
      timeSlots: (json['time_slots'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic s) => TimeSlot.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}
