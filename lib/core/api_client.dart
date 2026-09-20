import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_exception.dart';
import 'api_response.dart';
import 'app_config.dart';
import 'locale_controller.dart';
import 'token_storage.dart';

/// The single entry point for every HTTP call in the app (Guidelines 5.3).
/// It attaches the Sanctum bearer token, decodes the unified response
/// contract, and turns transport failures into [ApiException]. Screens and
/// services never touch `http` directly.
class ApiClient {
  ApiClient({
    http.Client? httpClient,
    TokenStorage? tokenStorage,
    String baseUrl = AppConfig.apiBaseUrl,
  })  : _http = httpClient ?? http.Client(),
        _tokenStorage = tokenStorage ?? const SecureTokenStorage(),
        _baseUrl = baseUrl;

  final http.Client _http;
  final TokenStorage _tokenStorage;
  final String _baseUrl;

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, String>? query,
    T Function(dynamic data)? parseData,
    bool authenticated = false,
  }) {
    return _send<T>(
      method: 'GET',
      path: path,
      query: query,
      parseData: parseData,
      authenticated: authenticated,
    );
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    Map<String, dynamic>? body,
    T Function(dynamic data)? parseData,
    bool authenticated = false,
  }) {
    return _send<T>(
      method: 'POST',
      path: path,
      body: body,
      parseData: parseData,
      authenticated: authenticated,
    );
  }

  Future<ApiResponse<T>> put<T>(
    String path, {
    Map<String, dynamic>? body,
    T Function(dynamic data)? parseData,
    bool authenticated = false,
  }) {
    return _send<T>(
      method: 'PUT',
      path: path,
      body: body,
      parseData: parseData,
      authenticated: authenticated,
    );
  }

  Future<ApiResponse<T>> _send<T>({
    required String method,
    required String path,
    Map<String, String>? query,
    Map<String, dynamic>? body,
    T Function(dynamic data)? parseData,
    bool authenticated = false,
  }) async {
    final Uri uri = Uri.parse('$_baseUrl$path').replace(queryParameters: query);
    final Map<String, String> headers = await _buildHeaders(authenticated);

    try {
      final http.Response response = await _dispatch(
        method: method,
        uri: uri,
        headers: headers,
        body: body,
      ).timeout(AppConfig.requestTimeout);

      return _decode<T>(response, parseData);
    } on SocketException catch (e) {
      throw ApiException(ApiFailureKind.noInternet, e.message);
    } on TimeoutException {
      throw const ApiException(ApiFailureKind.timeout);
    } on http.ClientException catch (e) {
      throw ApiException(ApiFailureKind.noInternet, e.message);
    }
  }

  Future<http.Response> _dispatch({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    Map<String, dynamic>? body,
  }) {
    final String? encoded = body == null ? null : jsonEncode(body);
    switch (method) {
      case 'GET':
        return _http.get(uri, headers: headers);
      case 'POST':
        return _http.post(uri, headers: headers, body: encoded);
      case 'PUT':
        return _http.put(uri, headers: headers, body: encoded);
      default:
        throw ArgumentError.value(method, 'method', 'Unsupported HTTP method');
    }
  }

  Future<Map<String, String>> _buildHeaders(bool authenticated) async {
    final Map<String, String> headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      // Laravel reads this to translate `message`, so a failure sentence
      // arrives in the language the user is actually reading.
      'Accept-Language': LocaleController.locale.value.languageCode,
    };
    if (authenticated) {
      final String? token = await _tokenStorage.read();
      if (token != null) {
        // Guidelines 2.4: the token travels in the header, never in the URL,
        // and is never written to a log.
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  ApiResponse<T> _decode<T>(
    http.Response response,
    T Function(dynamic data)? parseData,
  ) {
    // Guidelines 2.2: the envelope is returned on error statuses too, so a
    // 422 or 401 is still parsed rather than thrown. Only a body we cannot
    // read at all is exceptional.
    Map<String, dynamic> json;
    try {
      json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } on FormatException catch (e) {
      if (response.statusCode >= 500) {
        throw ApiException(ApiFailureKind.server, e.message);
      }
      throw ApiException(ApiFailureKind.malformedResponse, e.message);
    }

    return ApiResponse<T>.fromJson(json, parseData: parseData);
  }

  void close() => _http.close();
}
