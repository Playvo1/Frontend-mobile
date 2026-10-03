/// Reference lists the filters offer.
///
/// TODO(api): SRS FR-34 requires venues, sport types and prices to come
/// from the backend and be cached locally with sqflite, with the last
/// sync time shown (FR-35). Until those endpoints exist, the MVP's single
/// city is listed here so the filter sheet is usable.
class ReferenceData {
  ReferenceData._();

  /// Gaza only in the MVP (SRS 1.5.2 keeps other cities out of scope).
  static const List<String> cities = <String>[
    'غزة',
    'شمال غزة',
    'دير البلح',
    'خان يونس',
    'رفح',
  ];
}
