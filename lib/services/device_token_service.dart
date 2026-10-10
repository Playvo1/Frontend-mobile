import 'dart:io' show Platform;

import '../core/api_client.dart';
import '../core/api_response.dart';

/// Registers this device with the backend so it can receive pushes
/// (the DEVICE_TOKEN entity in the Guidelines).
///
/// The path is confirmed with the backend. The body shape (`token`,
/// `platform`) is still this file's own assumption.
class DeviceTokenService {
  DeviceTokenService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  static const String _path = '/device-tokens';

  /// `android` or `ios`, which the backend needs to pick the right
  /// delivery payload.
  static String get _platform => Platform.isIOS ? 'ios' : 'android';

  Future<ApiResponse<void>> register(String token) {
    return _client.post<void>(
      _path,
      authenticated: true,
      body: <String, dynamic>{'token': token, 'platform': _platform},
    );
  }

  Future<ApiResponse<void>> unregister(String token) {
    return _client.post<void>(
      '$_path/revoke',
      authenticated: true,
      body: <String, dynamic>{'token': token},
    );
  }
}
