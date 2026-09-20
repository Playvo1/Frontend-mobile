/// What `POST /auth/register` returns: the new account's id and email.
/// A verification code (VERIFICATION_CODE, type=email) has been sent at
/// this point, so the next screen is OTP entry (Guidelines 7.2).
class RegistrationResult {
  const RegistrationResult({required this.userId, required this.email});

  final int userId;
  final String email;

  factory RegistrationResult.fromJson(Map<String, dynamic> json) {
    return RegistrationResult(
      userId: json['user_id'] as int,
      email: json['email'] as String,
    );
  }
}
