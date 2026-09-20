import 'package:flutter_test/flutter_test.dart';
import 'package:playvo/core/api_response.dart';

void main() {
  group('ApiResponse', () {
    test('parses a success envelope and its data payload', () {
      final ApiResponse<int> response = ApiResponse<int>.fromJson(
        <String, dynamic>{
          'success': true,
          'data': <String, dynamic>{'user_id': 41},
          'message': 'Account created, verification code sent',
          'errors': null,
        },
        parseData: (dynamic data) =>
            (data as Map<String, dynamic>)['user_id'] as int,
      );

      expect(response.success, isTrue);
      expect(response.data, 41);
      expect(response.message, 'Account created, verification code sent');
      expect(response.errors, isNull);
    });

    test('parses a validation failure into per-field messages', () {
      final ApiResponse<void> response = ApiResponse<void>.fromJson(
        <String, dynamic>{
          'success': false,
          'data': null,
          'message': 'Validation failed',
          'errors': <String, dynamic>{
            'email': <String>['The email field is required.'],
          },
        },
      );

      expect(response.success, isFalse);
      expect(response.errorFor('email'), 'The email field is required.');
      expect(response.errorFor('password'), isNull);
    });

    test('does not call parseData when data is null', () {
      bool parserCalled = false;

      final ApiResponse<String> response = ApiResponse<String>.fromJson(
        <String, dynamic>{
          'success': true,
          'data': null,
          'message': 'Logged out',
          'errors': null,
        },
        parseData: (dynamic _) {
          parserCalled = true;
          return 'unreachable';
        },
      );

      expect(parserCalled, isFalse);
      expect(response.data, isNull);
    });
  });
}
