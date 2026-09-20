import '../core/api_client.dart';
import '../core/api_response.dart';
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
      '/auth/register',
      body: <String, dynamic>{
        'name': name,
        'email': email,
        'password': password,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
      parseData: (dynamic data) =>
          RegistrationResult.fromJson(data as Map<String, dynamic>),
    );
  }

  /// POST /auth/verify — confirms the emailed code.
  Future<ApiResponse<void>> verifyEmail({
    required String email,
    required String code,
  }) {
    return _client.post<void>(
      '/auth/verify',
      body: <String, dynamic>{'email': email, 'code': code},
    );
  }

  /// POST /auth/login — on success the token is stored before returning, so
  /// callers never handle the credential themselves.
  Future<ApiResponse<AuthSession>> login({
    required String email,
    required String password,
  }) async {
    final ApiResponse<AuthSession> response =
        await _client.post<AuthSession>(
      '/auth/login',
      body: <String, dynamic>{'email': email, 'password': password},
      parseData: (dynamic data) =>
          AuthSession.fromJson(data as Map<String, dynamic>),
    );

    await _persistIfAuthenticated(response);
    return response;
  }

  /// POST /auth/login/google — logs in or auto-registers from a Google
  /// ID token.
  Future<ApiResponse<AuthSession>> loginWithGoogle(String idToken) async {
    final ApiResponse<AuthSession> response =
        await _client.post<AuthSession>(
      '/auth/login/google',
      body: <String, dynamic>{'id_token': idToken},
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
      },
    );
  }

  /// GET /auth/me — used on launch to decide whether a stored token is
  /// still valid.
  Future<ApiResponse<User>> me() {
    return _client.get<User>(
      '/auth/me',
      authenticated: true,
      parseData: (dynamic data) => User.fromJson(data as Map<String, dynamic>),
    );
  }

  /// POST /auth/logout — revokes the token server-side, then clears it
  /// locally whatever the server said, so a failed call cannot leave a
  /// stale credential on the device.
  Future<ApiResponse<void>> logout() async {
    try {
      return await _client.post<void>('/auth/logout', authenticated: true);
    } finally {
      await _tokenStorage.clear();
    }
  }

  Future<bool> hasStoredToken() async => await _tokenStorage.read() != null;

  Future<void> _persistIfAuthenticated(ApiResponse<AuthSession> response) async {
    final AuthSession? session = response.data;
    if (response.success && session != null) {
      await _tokenStorage.write(session.token);
    }
  }
}
