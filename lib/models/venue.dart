import 'amenity.dart';

/// A bookable sports facility, as shown on the home and search screens
/// (SRS FR-05: address, photos, rating, hourly price).
///
/// The JSON keys follow the VENUE entity in the Guidelines. The venue
/// endpoints are not final yet, so [fromJson] is the single place to adjust
/// once the backend publishes the contract.
class Venue {
  const Venue({
    required this.id,
    required this.name,
    required this.city,
    required this.area,
    required this.sportType,
    required this.rating,
    required this.reviewCount,
    required this.hourlyPrice,
    this.photos = const <String>[],
    this.isAvailableNow = false,
    this.isFavorite = false,
    this.cityId,
    this.sportId,
    this.amenities = const <Amenity>[],
  });

  final int id;
  final String name;

  /// e.g. "غزة".
  final String city;

  /// The neighbourhood, e.g. "المينا".
  final String area;

  /// One of [SportType].
  final String sportType;

  final double rating;
  final int reviewCount;

  /// Price per hour in shekels (VENUE.min_hourly_price).
  final int hourlyPrice;

  final List<String> photos;

  /// True when the venue has a free slot in the current hour.
  final bool isAvailableNow;

  /// SRS FR-17. Kept on the model so a card can render without a second
  /// lookup; the server remains the source of truth.
  final bool isFavorite;

  /// The ids the venue endpoint filters by (`city_id`, `sport_id`).
  final int? cityId;
  final int? sportId;

  /// Shown as the small icon row on the search result card. The list
  /// endpoint sends only the first few; the venue page has them all.
  final List<Amenity> amenities;

  /// "غزة - الرمال" — the one-line address shown under the name.
  String get shortAddress => '$city - $area';

  String? get coverPhoto => photos.isEmpty ? null : photos.first;

  Venue copyWith({bool? isFavorite}) {
    return Venue(
      id: id,
      name: name,
      city: city,
      area: area,
      sportType: sportType,
      rating: rating,
      reviewCount: reviewCount,
      hourlyPrice: hourlyPrice,
      photos: photos,
      isAvailableNow: isAvailableNow,
      isFavorite: isFavorite ?? this.isFavorite,
      cityId: cityId,
      sportId: sportId,
      amenities: amenities,
    );
  }

  /// The shape [Venue.fromJson] reads back, used by the offline cache.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'city': city,
        'area': area,
        'sport_type': sportType,
        'rating': rating,
        'review_count': reviewCount,
        'min_hourly_price': hourlyPrice,
        'photos': photos,
        'is_available_now': isAvailableNow,
        'is_favorite': isFavorite,
        'city_id': cityId,
        'sport_id': sportId,
        'amenities': amenities.map((Amenity a) => a.toJson()).toList(),
      };

  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      // The API may send the city either as a plain string or as a nested
      // object; both shapes are accepted so a change on the other side
      // cannot blank out every card.
      city: _nameOf(json['city']),
      area: json['area'] as String? ?? _nameOf(json['district']),
      sportType: json['sport_type'] as String? ?? SportType.football,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: json['review_count'] as int? ?? 0,
      hourlyPrice: (json['min_hourly_price'] as num?)?.round() ?? 0,
      photos: (json['photos'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic p) => p.toString())
          .toList(),
      isAvailableNow: json['is_available_now'] as bool? ?? false,
      isFavorite: json['is_favorite'] as bool? ?? false,
      cityId: json['city_id'] as int?,
      sportId: json['sport_id'] as int?,
      amenities: (json['amenities'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic a) => Amenity.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }
}

String _nameOf(dynamic value) {
  if (value is String) {
    return value;
  }
  if (value is Map<String, dynamic>) {
    return value['name'] as String? ?? '';
  }
  return '';
}

/// The sport values agreed with the backend. Football is the only one in
/// the MVP (SRS 1.5.2), but the filter is built around this list so adding
/// a sport later is a one-line change here.
class SportType {
  SportType._();

  static const String football = 'football';

  static const List<String> all = <String>[football];
}
