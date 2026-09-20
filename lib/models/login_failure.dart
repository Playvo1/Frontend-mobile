import '../core/api_response.dart';

/// The detail a rejected login carries, so the screen can show the two
/// states in the design: "wrong credentials, N attempts left" and "locked,
/// try again in mm:ss".
///
/// Both numbers are decided by the server from USER.failed_login_attempts
/// and USER.locked_until (Guidelines 2.4). The app never counts attempts
/// itself — a locally kept counter resets when the app restarts and would
/// show the player a number that is simply untrue.
class LoginFailure {
  const LoginFailure({this.remainingAttempts, this.lockedUntil});

  /// How many tries are left before the account locks. Null when the server
  /// does not report it.
  final int? remainingAttempts;

  /// When the lock lifts, in the device's local time. Null when the account
  /// is not locked.
  final DateTime? lockedUntil;

  bool get isLocked =>
      lockedUntil != null && lockedUntil!.isAfter(DateTime.now());

  /// Reads the failure payload of a login response. Returns an empty
  /// instance when the server sent no detail, so the caller can fall back
  /// to showing the plain message.
  factory LoginFailure.fromResponse(ApiResponse<dynamic> response) {
    final Map<String, dynamic>? details = response.failureDetails;
    if (details == null) {
      return const LoginFailure();
    }

    final String? lockedUntilRaw = details['locked_until'] as String?;

    return LoginFailure(
      remainingAttempts: details['remaining_attempts'] as int?,
      lockedUntil: lockedUntilRaw == null
          ? null
          : DateTime.tryParse(lockedUntilRaw)?.toLocal(),
    );
  }
}
