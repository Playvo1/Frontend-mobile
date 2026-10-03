import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../core/api_client.dart';
import '../core/token_storage.dart';
import '../services/auth_service.dart';

/// Canned [AuthService] instances for the screen gallery, so every screen
/// state can be opened without a running backend.
///
/// DEV ONLY. Nothing outside `lib/dev/` may import this file, and the whole
/// folder is deleted once the real API is connected.
class PreviewAuthService {
  PreviewAuthService._();

  /// Every request answers with [body] after a short pause, so loading
  /// spinners are visible the way they will be on a real network.
  static AuthService answering(
    Map<String, dynamic> body, {
    int statusCode = 200,
  }) {
    final InMemoryTokenStorage storage = InMemoryTokenStorage();
    return AuthService(
      client: ApiClient(
        httpClient: MockClient((http.Request request) async {
          await Future<void>.delayed(const Duration(milliseconds: 600));
          return http.Response(
            jsonEncode(body),
            statusCode,
            headers: <String, String>{'content-type': 'application/json'},
          );
        }),
        tokenStorage: storage,
        baseUrl: 'https://preview.local/api/v1',
      ),
      tokenStorage: storage,
    );
  }

  /// Login state 2 in the design: wrong credentials, attempts remaining.
  static AuthService get wrongCredentials => answering(
        <String, dynamic>{
          'success': false,
          'data': <String, dynamic>{'remaining_attempts': 4},
          'message': 'البريد الإلكتروني أو كلمة المرور غير صحيحة',
          'errors': null,
        },
        statusCode: 401,
      );

  /// Login state 3 in the design: the account is locked for 15 minutes.
  static AuthService get lockedAccount => answering(
        <String, dynamic>{
          'success': false,
          'data': <String, dynamic>{
            'locked_until': DateTime.now()
                .toUtc()
                .add(const Duration(minutes: 15))
                .toIso8601String(),
          },
          'message': 'تم تجاوز عدد محاولات تسجيل الدخول المسموح بها',
          'errors': null,
        },
        statusCode: 423,
      );

  /// A signed-in player, for the placeholder home screen.
  static AuthService get signedIn => answering(<String, dynamic>{
        'success': true,
        'data': <String, dynamic>{
          'id': 41,
          'name': 'عمر يوسف',
          'email': 'omar@example.com',
          'phone': '0599123456',
          'roles': <String>['player'],
          'status': 'active',
        },
        'message': '',
        'errors': null,
      });

  /// Any call succeeds with no payload — enough for the screens whose
  /// submit button only needs to move forward.
  static AuthService get alwaysOk => answering(<String, dynamic>{
        'success': true,
        'data': null,
        'message': '',
        'errors': null,
      });
}
