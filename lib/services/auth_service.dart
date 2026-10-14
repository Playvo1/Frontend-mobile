import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../core/api_response.dart';
import '../core/push_notifications.dart';
import '../core/token_storage.dart';
import '../models/auth_session.dart';
import '../models/registration_result.dart';
import '../models/user.dart';

/// Every call under `/api/v1/auth` (Guidelines 7.2), in one place. Screens
/// call these methods and read the unified envelope; they never build a
/// request body or know an endpoint path.
class AuthService {
  AuthService({ApiClient? client, TokenStorage? tokenStorage})
      : _client = client ?? ApiClient(),
        _tokenStorage = tokenStorage ?? const SecureTokenStorage();

  final ApiClient _client;
  final TokenStorage _tokenStorage;

  /// POST /auth/register — creates a player account and triggers the email
  /// verification code.
  Future<ApiResponse<RegistrationResult>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) {
    return _client.post<RegistrationResult>(
      '/auth/register/player',
      body: <String, dynamic>{
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
      parseData: (dynamic data) =>
          RegistrationResult.fromJson(data as Map<String, dynamic>),
    );
  }

  /// POST /auth/send-otp
  Future<ApiResponse<void>> sendOtp(String email) {
    return _client.post<void>(
      '/auth/send-otp',
      body: <String, dynamic>{
        'email': email,
      },
    );
  }

  /// POST /auth/verify-otp — confirms the emailed code.
  Future<ApiResponse<void>> verifyEmail({
    required String email,
    required String code,
  }) {
    return _client.post<void>(
      '/auth/verify-otp',
      body: <String, dynamic>{
        'email': email,
        'otp_code': code,
      },
    );
  }

  /// POST /auth/login — on success the token is stored before returning, so
  /// callers never handle the credential themselves.
  Future<ApiResponse<AuthSession>> login({
    required String email,
    required String password,
  }) async {
    final ApiResponse<AuthSession> response = await _client.post<AuthSession>(
      '/auth/login',
      body: <String, dynamic>{'email': email, 'password': password},
      parseData: (dynamic data) =>
          AuthSession.fromJson(data as Map<String, dynamic>),
    );

    await _persistIfAuthenticated(response);
    return response;
  }

  /// POST /auth/google — registers or logs in based on the mode.
  Future<ApiResponse<AuthSession>> loginWithGoogle(
      String idToken, {
        required String mode,
      }) async {
    final ApiResponse<AuthSession> response = await _client.post<AuthSession>(
      '/auth/google',
      body: <String, dynamic>{
        'id_token': idToken,
        'mode': mode,
      },
      parseData: (dynamic data) =>
          AuthSession.fromJson(data as Map<String, dynamic>),
    );

    await _persistIfAuthenticated(response);
    return response;
  }

  /// POST /auth/forgot-password — the response is identical whether or not
  /// the email exists, so the app must not branch on it.
  Future<ApiResponse<void>> forgotPassword(String email) {
    return _client.post<void>(
      '/auth/forgot-password',
      body: <String, dynamic>{'email': email},
    );
  }

  /// POST /auth/verify-reset-otp
  Future<ApiResponse<void>> verifyResetOtp({
    required String email,
    required String code,
  }) {
    return _client.post<void>(
      '/auth/verify-reset-otp',
      body: <String, dynamic>{
        'email': email,
        'otp_code': code,
      },
    );
  }

  /// POST /auth/reset-password — needs the email and the code the player
  /// entered on the OTP screen, which is why both are carried forward
  /// through the flow rather than re-asked.
  Future<ApiResponse<void>> resetPassword({
    required String email,
    required String code,
    required String password,
  }) {
    return _client.post<void>(
      '/auth/reset-password',
      body: <String, dynamic>{
        'email': email,
        'code': code,
        'password': password,
        'password_confirmation': password,
      },
    );
  }

  /// The signed-in account.
  ///
  /// `GET /auth/me` is asked first and its answer is cached. That route is
  /// not in the Postman collection, so on a deployment without it the call
  /// comes back 404 — and the account screen would show an empty name and
  /// email. Login already returns the whole account, so the copy saved then
  /// answers instead and the profile renders either way.
  ///
  /// TODO(api): confirm the session-check route with the backend. Until it
  /// exists the cached copy cannot notice a token the server has revoked.
  Future<ApiResponse<User>> me() async {
    try {
      final ApiResponse<User> response = await _client.get<User>(
        '/auth/me',
        authenticated: true,
        parseData: (dynamic data) => User.fromJson(_userObject(data)),
      );
      final User? fresh = response.data;
      if (response.success && fresh != null) {
        await _cacheUser(fresh);
        return response;
      }
    } on ApiException {
      // Route missing or unreachable; the cached account answers below.
    }

    final User? cached = await _readCachedUser();
    if (cached != null) {
      return ApiResponse<User>(success: true, message: '', data: cached);
    }
    return const ApiResponse<User>(success: false, message: '');
  }

  /// Accepts the account either as the `data` object itself or nested under
  /// `data.user`, which is how login returns it.
  static Map<String, dynamic> _userObject(dynamic data) {
    final Map<String, dynamic> map = data as Map<String, dynamic>;
    final dynamic nested = map['user'];
    return nested is Map<String, dynamic> ? nested : map;
  }

  Future<void> _cacheUser(User user) async {
    try {
      await _tokenStorage.writeProfile(jsonEncode(user.toJson()));
    } on Object catch (error) {
      debugPrint('Profile cache skipped: $error');
    }
  }

  Future<User?> _readCachedUser() async {
    try {
      final String? raw = await _tokenStorage.readProfile();
      if (raw == null || raw.isEmpty) {
        return null;
      }
      return User.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object catch (error) {
      debugPrint('Cached profile unreadable: $error');
      return null;
    }
  }

  /// POST /auth/logout — revokes the token server-side, then clears it
  /// locally whatever the server said, so a failed call cannot leave a
  /// stale credential on the device.
  Future<ApiResponse<void>> logout() async {
    try {
      // Revoked before the session token is cleared, since the call needs
      // it. A failure here must not block signing out.
      try {
        await PushNotifications().stop();
      } on Object catch (error) {
        debugPrint('Push revocation skipped: $error');
      }
      return await _client.post<void>('/auth/logout', authenticated: true);
    } finally {
      // Clears the token AND the cached profile, so signing out leaves no
      // name or email behind on the device.
      await _tokenStorage.clear();
    }
  }

  Future<bool> hasStoredToken() async => await _tokenStorage.read() != null;

  Future<void> _persistIfAuthenticated(ApiResponse<AuthSession> response) async {
    final AuthSession? session = response.data;
    if (response.success && session != null) {
      await _tokenStorage.write(session.token);
      // Login is the one call that reliably returns the account, so the
      // profile screen is fed from here rather than from a route that may
      // not exist on this deployment.
      await _cacheUser(session.user);
      // The device token is only useful once it can be tied to an account,
      // so it is registered here rather than on launch. Push is a
      // side-effect of signing in, never a condition for it, so a failure
      // here must not fail the sign-in.
      try {
        await PushNotifications().start();
      } on Object catch (error) {
        debugPrint('Push registration skipped: $error');
      }
    }
  }
}