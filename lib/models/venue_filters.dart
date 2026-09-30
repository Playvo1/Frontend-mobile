import 'package:flutter/material.dart';

import 'venue.dart';

/// The filter set behind the "تصفية النتائج" sheet (SRS FR-04: city,
/// country, sport type, date and hour) plus the price and rating controls
/// in the design.
///
/// Immutable so a sheet can edit a working copy and the screen only adopts
/// it when the player presses "عرض النتائج".
@immutable
class VenueFilters {
  const VenueFilters({
    this.city,
    this.cityId,
    this.sportId,
    this.sportType,
    this.date,
    this.time,
    this.minPrice = priceFloor,
    this.maxPrice = priceCeiling,
    this.minRating,
    this.query = '',
  });

  /// The bounds of the price slider, in shekels per hour.
  static const double priceFloor = 50;
  static const double priceCeiling = 200;

  /// Display name of the city, for the chips and the header.
  final String? city;

  /// What `GET /venues` filters by.
  final int? cityId;
  final int? sportId;

  final String? sportType;
  final DateTime? date;
  final TimeOfDay? time;
  final double minPrice;
  final double maxPrice;

  /// 1 to 5, meaning "rated N stars and above".
  final int? minRating;

  /// Free-text search over the venue name and area.
  final String query;

  bool get isPriceRangeDefault =>
      minPrice == priceFloor && maxPrice == priceCeiling;

  /// Whether anything is narrowing the results, so the screen can show a
  /// "filters active" hint.
  bool get isActive =>
      city != null ||
      sportType != null ||
      date != null ||
      time != null ||
      minRating != null ||
      !isPriceRangeDefault;

  VenueFilters copyWith({
    Object? city = _unset,
    Object? cityId = _unset,
    Object? sportId = _unset,
    Object? sportType = _unset,
    Object? date = _unset,
    Object? time = _unset,
    double? minPrice,
    double? maxPrice,
    Object? minRating = _unset,
    String? query,
  }) {
    return VenueFilters(
      city: city == _unset ? this.city : city as String?,
      cityId: cityId == _unset ? this.cityId : cityId as int?,
      sportId: sportId == _unset ? this.sportId : sportId as int?,
      sportType: sportType == _unset ? this.sportType : sportType as String?,
      date: date == _unset ? this.date : date as DateTime?,
      time: time == _unset ? this.time : time as TimeOfDay?,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minRating: minRating == _unset ? this.minRating : minRating as int?,
      query: query ?? this.query,
    );
  }

  /// Sentinel so copyWith can tell "leave it alone" apart from "set to null".
  static const Object _unset = Object();

  /// Query parameters for the venue endpoint. Only what is actually set is
  /// sent, to keep requests light on weak networks (SRS NFR-01e).
  Map<String, String> toQueryParameters() {
    // Names taken from the Postman collection:
    // GET /venues?city_id=&sport_id=&date=&hour=&page=
    return <String, String>{
      if (query.isNotEmpty) 'q': query,
      if (cityId != null) 'city_id': cityId!.toString(),
      if (sportId != null) 'sport_id': sportId!.toString(),
      if (date != null) 'date': formatDate(date!),
      if (time != null) 'hour': _formatTime(time!),
      if (!isPriceRangeDefault) ...<String, String>{
        'min_price': minPrice.round().toString(),
        'max_price': maxPrice.round().toString(),
      },
      if (minRating != null) 'min_rating': minRating!.toString(),
    };
  }

  /// `YYYY-MM-DD`, the format the API's `date` parameter takes.
  static String formatDate(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static String _formatTime(TimeOfDay time) {
    final String hour = time.hour.toString().padLeft(2, '0');
    final String minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Applies the filters locally. Used by the mock service while the venue
  /// endpoints are being built, so the sheet can be exercised end to end.
  bool matches(Venue venue) {
    if (city != null && venue.city != city) {
      return false;
    }
    if (sportType != null && venue.sportType != sportType) {
      return false;
    }
    if (venue.hourlyPrice < minPrice || venue.hourlyPrice > maxPrice) {
      return false;
    }
    if (minRating != null && venue.rating < minRating!) {
      return false;
    }
    if (query.isNotEmpty) {
      final String q = query.toLowerCase();
      if (!venue.name.toLowerCase().contains(q) &&
          !venue.area.toLowerCase().contains(q) &&
          !venue.city.toLowerCase().contains(q)) {
        return false;
      }
    }
    return true;
  }
}
