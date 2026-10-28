import '../core/app_config.dart';

/// A Playvo account, mapped one-to-one onto the USER entity
/// (Guidelines 3). Field names match the API exactly — `name`, not
/// `fullName`; `email_verified_at`, not `isVerified` — so a field is never
/// renamed between the backend and the app.
///
/// There is deliberately no password field here. The plain password only
/// ever exists as a local variable inside a login/signup call, and
/// `password_hash` never leaves the server (Guidelines 2.4).
class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.roles,
    required this.status,
    this.phone,
    this.emailVerifiedAt,
    this.photoUrl,
  });

  final int id;
  final String name;
  final String email;
  final String? phone;

  /// spatie/laravel-permission role names: `player`, `venue_owner`, `admin`.
  /// The app uses these for display and navigation only — access is always
  /// decided server-side (Guidelines 2.4).
  final List<String> roles;

  /// USER.status: one of `active`, `locked`, `unverified` (Guidelines 3.1).
  final String status;

  final DateTime? emailVerifiedAt;

  /// Absolute URL of the profile picture. The backend sends a path
  /// relative to its root, so it is resolved against the API host the same
  /// way venue images are.
  final String? photoUrl;

  bool get isActive => status == UserStatus.active;

  bool hasRole(String role) => roles.contains(role);

  factory User.fromJson(Map<String, dynamic> json) {
    final String? verifiedAt = json['email_verified_at'] as String?;
    return User(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      roles: (json['roles'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic role) => role.toString())
          .toList(),
      status: json['status'] as String? ?? UserStatus.active,
      emailVerifiedAt: verifiedAt == null ? null : DateTime.tryParse(verifiedAt),
      photoUrl: _photoUrl(json),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'roles': roles,
        'status': status,
        'email_verified_at': emailVerifiedAt?.toIso8601String(),
        'photo_url': photoUrl,
      };

  /// The picture has arrived under several names across endpoints, so each
  /// is tried before giving up.
  static String? _photoUrl(Map<String, dynamic> json) {
    for (final String key in const <String>[
      'photo_url',
      'profile_photo_url',
      'photo',
      'avatar_url',
      'avatar',
      'image_url',
    ]) {
      final String raw = (json[key] ?? '').toString().trim();
      if (raw.isNotEmpty) {
        return AppConfig.resolveFileUrl(raw);
      }
    }
    return null;
  }
}

/// The fixed USER.status strings from Guidelines 3.1. Never compare against
/// a literal elsewhere in the app; a new value has to be agreed with the
/// whole team and added here first.
class UserStatus {
  UserStatus._();

  static const String active = 'active';
  static const String locked = 'locked';
  static const String unverified = 'unverified';
}

/// The fixed role names from Guidelines 7.1.
class UserRole {
  UserRole._();

  static const String player = 'player';
  static const String venueOwner = 'venue_owner';
  static const String admin = 'admin';
}
