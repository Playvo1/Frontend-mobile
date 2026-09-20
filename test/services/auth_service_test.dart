import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:playvo/core/api_client.dart';
import 'package:playvo/core/api_exception.dart';
import 'package:playvo/core/api_response.dart';
import 'package:playvo/core/token_storage.dart';
import 'package:playvo/models/auth_session.dart';
import 'package:playvo/services/auth_service.dart';

const String _baseUrl = 'https://test.playvo.app/api/v1';

AuthService _serviceReturning(
  Future<http.Response> Function(http.Request request) handler, {
  required TokenStorage tokenStorage,
}) {
  return AuthService(
    client: ApiClient(
      httpClient: MockClient(handler),
      tokenStorage: tokenStorage,
      baseUrl: _baseUrl,
    ),
    tokenStorage: tokenStorage,
  );
}

void main() {
  late InMemoryTokenStorage tokenStorage;

  setUp(() => tokenStorage = InMemoryTokenStorage());

  group('AuthService.login', () {
    test('sends the contract body and stores the token on success', () async {
      late http.Request captured;

      final AuthService service = _serviceReturning(
        (http.Request request) async {
          captured = request;
          return http.Response(
            jsonEncode(<String, dynamic>{
              'success': true,
              'data': <String, dynamic>{
                'token': '1|abcdef',
                'user': <String, dynamic>{
                  'id': 41,
                  'name': 'Omar Yousef',
                  'email': 'omar@example.com',
                  'roles': <String>['player'],
                  'status': 'active',
                },
              },
              'message': 'Logged in',
              'errors': null,
            }),
            200,
            headers: <String, String>{'content-type': 'application/json'},
          );
        },
        tokenStorage: tokenStorage,
      );

      final ApiResponse<AuthSession> response = await service.login(
        email: 'omar@example.com',
        password: 'Str0ngPass!',
      );

      expect(captured.url.toString(), '$_baseUrl/auth/login');
      expect(
        jsonDecode(captured.body),
        <String, dynamic>{
          'email': 'omar@example.com',
          'password': 'Str0ngPass!',
        },
      );
      expect(response.success, isTrue);
      expect(response.data!.user.name, 'Omar Yousef');
      expect(response.data!.user.hasRole('player'), isTrue);
      expect(await tokenStorage.read(), '1|abcdef');
    });

    test('returns the failure envelope and stores nothing when rejected',
        () async {
      final AuthService service = _serviceReturning(
        (http.Request request) async => http.Response(
          jsonEncode(<String, dynamic>{
            'success': false,
            'data': null,
            'message': 'Account locked, try again later',
            'errors': null,
          }),
          423,
          headers: <String, String>{'content-type': 'application/json'},
        ),
        tokenStorage: tokenStorage,
      );

      final ApiResponse<AuthSession> response = await service.login(
        email: 'omar@example.com',
        password: 'wrong',
      );

      expect(response.success, isFalse);
      expect(response.message, 'Account locked, try again later');
      expect(await tokenStorage.read(), isNull);
    });

    test('throws a typed exception when the body is not JSON', () async {
      final AuthService service = _serviceReturning(
        (http.Request request) async => http.Response('<html>502</html>', 502),
        tokenStorage: tokenStorage,
      );

      expect(
        () => service.login(email: 'omar@example.com', password: 'x'),
        throwsA(
          isA<ApiException>().having(
            (ApiException e) => e.kind,
            'kind',
            ApiFailureKind.server,
          ),
        ),
      );
    });
  });

  group('AuthService.resetPassword', () {
    test('sends email, code and the new password together', () async {
      late http.Request captured;

      final AuthService service = _serviceReturning(
        (http.Request request) async {
          captured = request;
          return http.Response(
            jsonEncode(<String, dynamic>{
              'success': true,
              'data': null,
              'message': 'Password updated',
              'errors': null,
            }),
            200,
          );
        },
        tokenStorage: tokenStorage,
      );

      await service.resetPassword(
        email: 'omar@example.com',
        code: '482913',
        password: 'NewStr0ngPass!',
      );

      expect(
        jsonDecode(captured.body),
        <String, dynamic>{
          'email': 'omar@example.com',
          'code': '482913',
          'password': 'NewStr0ngPass!',
        },
      );
    });
  });

  group('AuthService.logout', () {
    test('clears the stored token even when the request fails', () async {
      await tokenStorage.write('1|abcdef');

      final AuthService service = _serviceReturning(
        (http.Request request) async =>
            throw const http.ClientException('offline'),
        tokenStorage: tokenStorage,
      );

      await expectLater(service.logout(), throwsA(isA<ApiException>()));
      expect(await tokenStorage.read(), isNull);
    });
  });

  group('ApiClient auth header', () {
    test('sends the bearer token on authenticated calls only', () async {
      await tokenStorage.write('1|abcdef');
      final List<String?> seenHeaders = <String?>[];

      final AuthService service = _serviceReturning(
        (http.Request request) async {
          seenHeaders.add(request.headers['Authorization']);
          return http.Response(
            jsonEncode(<String, dynamic>{
              'success': true,
              'data': null,
              'message': 'OK',
              'errors': null,
            }),
            200,
          );
        },
        tokenStorage: tokenStorage,
      );

      await service.forgotPassword('omar@example.com'); // public
      await service.logout(); // authenticated

      expect(seenHeaders.first, isNull);
      expect(seenHeaders.last, 'Bearer 1|abcdef');
    });
  });
}
