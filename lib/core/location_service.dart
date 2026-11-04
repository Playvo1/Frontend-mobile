import 'package:geolocator/geolocator.dart';

/// Why a location request did not produce a position.
enum LocationFailure { serviceDisabled, permissionDenied, permanentlyDenied }

/// Raised when the device cannot give a position; the screen decides what
/// to show, since a map without the player's dot still works.
class LocationException implements Exception {
  const LocationException(this.failure);

  final LocationFailure failure;

  @override
  String toString() => 'LocationException($failure)';
}

/// Wraps geolocator so the screens never touch the plugin directly and can
/// be tested with a fake.
///
/// Permissions are requested at the moment the map needs them, not on
/// launch: asking before the player has seen why is the fastest way to get
/// a refusal.
class LocationService {
  const LocationService();

  /// Gaza city centre — where the map opens when there is no position yet.
  static const double fallbackLatitude = 31.5017;
  static const double fallbackLongitude = 34.4668;

  Future<Position> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException(LocationFailure.serviceDisabled);
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(LocationFailure.permanentlyDenied);
    }
    if (permission == LocationPermission.denied) {
      throw const LocationException(LocationFailure.permissionDenied);
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        // A rough fix is enough to sort venues by distance, and it comes
        // back far faster than a precise one.
        timeLimit: Duration(seconds: 15),
      ),
    );
  }

  /// Metres between two points, used to order "الأقرب أولاً".
  double distanceBetween({
    required double fromLatitude,
    required double fromLongitude,
    required double toLatitude,
    required double toLongitude,
  }) {
    return Geolocator.distanceBetween(
      fromLatitude,
      fromLongitude,
      toLatitude,
      toLongitude,
    );
  }
}
