import '../core/app_config.dart';
import '../core/locale_controller.dart';
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
    this.latitude,
    this.longitude,
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

  /// Where the venue sits, for the map. Null until the backend sends it,
  /// in which case the venue simply gets no marker.
  final double? latitude;
  final double? longitude;

  bool get hasCoordinates => latitude != null && longitude != null;

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
      latitude: latitude,
      longitude: longitude,
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
        'latitude': latitude,
        'longitude': longitude,
      };

  /// Reads the shape the backend actually returns, confirmed against a
  /// live response. Names, areas and cities are bilingual; ratings and
  /// prices arrive as strings; images are server-relative paths.
  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      id: json['id'] as int,
      name: _localised(json, 'name'),
      city: _localisedObject(json['city'], 'name'),
      area: _localised(json, 'area'),
      // The venue carries a `sports` array rather than a single type. The
      // MVP is football only, so the first entry decides, and an empty
      // array (which is what the seed data has) falls back to football.
      sportType: _firstSport(json['sports']),
      rating: _toDouble(json['avg_rating'] ?? json['rating']),
      // Not in the venue payload yet; the card simply shows no count.
      reviewCount: (json['reviews_count'] as num?)?.round() ?? 0,
      hourlyPrice: _toDouble(json['min_hourly_price']).round(),
      photos: _photos(json),
      isAvailableNow: json['is_available_now'] as bool? ??
          json['status'] == 'active',
      isFavorite: json['is_favorite'] as bool? ?? false,
      cityId: json['city_id'] as int?,
      sportId: (json['sports'] as List<dynamic>?)?.isNotEmpty == true
          ? ((json['sports']! as List<dynamic>).first
              as Map<String, dynamic>)['id'] as int?
          : null,
      amenities: (json['amenities'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic a) => Amenity.fromJson(a as Map<String, dynamic>))
          .toList(),
      latitude: _toNullableDouble(json['latitude']),
      longitude: _toNullableDouble(json['longitude']),
    );
  }

  /// Picks `<field>_ar` or `<field>_en` by the active language, falling
  /// back to the other one so a missing translation never blanks a card.
  static String _localised(Map<String, dynamic> json, String field) {
    final String? ar = json['${field}_ar'] as String?;
    final String? en = json['${field}_en'] as String?;
    final String? plain = json[field] as String?;
    final bool isArabic = LocaleController.locale.value.languageCode == 'ar';
    final String? preferred = isArabic ? ar : en;
    return preferred?.trim().isNotEmpty == true
        ? preferred!.trim()
        : (ar ?? en ?? plain ?? '').trim();
  }

  /// The same, for a nested object such as `city` or `country`.
  static String _localisedObject(dynamic raw, String field) {
    if (raw is Map<String, dynamic>) {
      return _localised(raw, field);
    }
    return raw?.toString() ?? '';
  }

  static String _firstSport(dynamic raw) {
    if (raw is List && raw.isNotEmpty && raw.first is Map<String, dynamic>) {
      final Map<String, dynamic> first = raw.first as Map<String, dynamic>;
      return (first['slug'] ?? first['name_en'] ?? SportType.football)
          .toString();
    }
    return SportType.football;
  }

  /// Images arrive as `[{image_url: "/storage/..."}]` with paths relative
  /// to the server root, so each one is resolved against the API host.
  static List<String> _photos(Map<String, dynamic> json) {
    final List<dynamic> raw =
        (json['images'] ?? json['photos'] ?? <dynamic>[]) as List<dynamic>;
    return raw
        .map((dynamic item) {
          final String path = item is Map<String, dynamic>
              ? (item['image_url'] ?? item['url'] ?? '').toString()
              : item.toString();
          return path.isEmpty ? '' : AppConfig.resolveFileUrl(path);
        })
        .where((String url) => url.isNotEmpty)
        .toList();
  }

  /// Decimal columns come back as strings ("5.00"), integers as numbers.
  static double _toDouble(dynamic raw) => _toNullableDouble(raw) ?? 0;

  static double? _toNullableDouble(dynamic raw) {
    if (raw is num) {
      return raw.toDouble();
    }
    if (raw is String) {
      return double.tryParse(raw);
    }
    return null;
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
  static const String basketball = 'basketball';
  static const String volleyball = 'volleyball';
  static const String tennis = 'tennis';

  /// What a player can actually filter by today. The SRS (1.5.2) keeps
  /// every sport but football out of the MVP's scope.
  static const List<String> available = <String>[football];

  /// Listed in the filter sheet as "قريباً", so the roadmap is visible
  /// without pretending the data exists.
  static const List<String> comingSoon = <String>[
    basketball,
    volleyball,
    tennis,
  ];

  static const List<String> all = <String>[football, ...comingSoon];
}
