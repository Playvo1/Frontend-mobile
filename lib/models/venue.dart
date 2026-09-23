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

  /// "المينا، غزة" — the one-line address shown under the name.
  String get shortAddress => '$area، $city';

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
    );
  }

  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      city: json['city'] as String? ?? '',
      area: json['area'] as String? ?? '',
      sportType: json['sport_type'] as String? ?? SportType.football,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: json['review_count'] as int? ?? 0,
      hourlyPrice: (json['min_hourly_price'] as num?)?.round() ?? 0,
      photos: (json['photos'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic p) => p.toString())
          .toList(),
      isAvailableNow: json['is_available_now'] as bool? ?? false,
      isFavorite: json['is_favorite'] as bool? ?? false,
    );
  }
}

/// The sport values agreed with the backend. Football is the only one in
/// the MVP (SRS 1.5.2), but the filter is built around this list so adding
/// a sport later is a one-line change here.
class SportType {
  SportType._();

  static const String football = 'football';

  static const List<String> all = <String>[football];
}
