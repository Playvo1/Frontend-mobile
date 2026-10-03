/// A facility a venue offers — parking, lighting, changing rooms — shown as
/// the icon tiles on the venue details screen.
class Amenity {
  const Amenity({required this.id, required this.name, this.icon});

  final int id;
  final String name;

  /// The icon key the API sends, if any. [Amenity] keeps it as a string so
  /// a new amenity does not need an app release; unknown keys fall back to
  /// a neutral icon.
  final String? icon;

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'id': id, 'name': name, 'icon': icon};

  factory Amenity.fromJson(Map<String, dynamic> json) {
    return Amenity(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String?,
    );
  }
}
