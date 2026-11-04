import '../core/api_client.dart';
import '../core/api_response.dart';
import '../core/diagnostics.dart';
import '../models/user.dart';

/// The player's own account:
///
/// * `GET  /player/profile`        — read it
/// * `PUT  /player/profile`        — change name, email, phone
/// * `POST /player/profile/photo`  — replace the picture
///
/// All three are authenticated. The request and response field names were
/// never published, so the same approach as the assistant is used: ask,
/// and let a 422 correct the name. The reply is read tolerantly, because
/// the account arrives sometimes as the `data` object and sometimes nested
/// under `user` or `profile`.
class ProfileService {
  ProfileService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  static const String _path = '/player/profile';
  static const String _photoPath = '/player/profile/photo';

  /// The multipart field tried first; `updatePhoto` is the controller
  /// method, so `photo` is the likely name. Corrected on a 422.
  static String _photoField = 'photo';

  /// `GET /player/profile`
  Future<ApiResponse<User>> show() async {
    final ApiResponse<User> response = await _client.get<User>(
      _path,
      authenticated: true,
      parseData: (dynamic data) => User.fromJson(unwrap(data)),
    );

    Diagnostics.add(
      'GET /player/profile -> ${response.statusCode} '
      'success=${response.success} name=${response.data?.name}',
    );
    return response;
  }

  /// `PUT /player/profile`. Only what changed is sent, so a field the
  /// endpoint does not accept cannot be rejected for being unchanged.
  Future<ApiResponse<User>> update({
    String? name,
    String? email,
    String? phone,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
    };

    final ApiResponse<User> response = await _client.put<User>(
      _path,
      body: body,
      authenticated: true,
      parseData: (dynamic data) => User.fromJson(unwrap(data)),
    );

    Diagnostics.add(
      'PUT /player/profile fields=${body.keys.toList()} -> '
      '${response.statusCode} success=${response.success} '
      'msg="${response.message}" errors=${response.errors?.keys.toList()}',
    );
    return response;
  }

  /// `POST /player/profile/photo`, multipart.
  Future<ApiResponse<User>> updatePhoto(String filePath) async {
    ApiResponse<User> response = await _postPhoto(_photoField, filePath);

    // A 422 names the field the endpoint wanted; retry once under it.
    if (response.statusCode == 422) {
      final String? wanted = response.errors?.keys.firstOrNull;
      if (wanted != null && wanted != _photoField) {
        Diagnostics.add('photo: server wants "$wanted", retrying');
        _photoField = wanted;
        response = await _postPhoto(_photoField, filePath);
      }
    }

    Diagnostics.add(
      'POST /player/profile/photo field="$_photoField" -> '
      '${response.statusCode} success=${response.success} '
      'msg="${response.message}"',
    );
    return response;
  }

  Future<ApiResponse<User>> _postPhoto(String field, String filePath) {
    return _client.postFile<User>(
      _photoPath,
      field: field,
      filePath: filePath,
      parseData: (dynamic data) => User.fromJson(unwrap(data)),
    );
  }

  /// The account itself, whether it is the `data` object or nested under
  /// `user` or `profile`.
  static Map<String, dynamic> unwrap(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return <String, dynamic>{};
    }
    for (final String key in const <String>['user', 'profile', 'player']) {
      final dynamic nested = data[key];
      if (nested is Map<String, dynamic>) {
        return nested;
      }
    }
    return data;
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
