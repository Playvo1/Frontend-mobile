/// The unified API response envelope every Laravel endpoint returns
/// (Guidelines 2.2): `success`, `data`, `message`, `errors`.
///
/// Parsing lives here once, so no screen ever pulls fields out of a raw
/// JSON map by hand.
class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
    this.failureDetails,
  });

  final bool success;
  final T? data;
  final String message;

  /// The raw `data` object of a FAILED response. Most failures carry
  /// `"data": null`, but some endpoints attach detail the UI needs — a login
  /// rejection carries how many attempts are left, or when the lock lifts.
  /// It stays untyped here because it differs per endpoint; each screen's
  /// own model reads it.
  final Map<String, dynamic>? failureDetails;

  /// Field-level validation errors, e.g. `{"email": ["The email field is required."]}`.
  final Map<String, List<String>>? errors;

  /// Builds a response from decoded JSON. [parseData] converts the `data`
  /// payload into the model type; omit it when the endpoint returns
  /// `"data": null` (logout, forgot-password, reset-password).
  factory ApiResponse.fromJson(
    Map<String, dynamic> json, {
    T Function(dynamic data)? parseData,
  }) {
    final dynamic rawData = json['data'];
    final bool success = json['success'] as bool? ?? false;

    // parseData describes the SUCCESS payload, so it must not run on a
    // failure body — a rejected login returns a different shape under
    // `data` and would otherwise blow up inside the model's fromJson.
    final bool shouldParse = success && rawData != null && parseData != null;

    return ApiResponse<T>(
      success: success,
      message: json['message'] as String? ?? '',
      data: shouldParse ? parseData(rawData) : null,
      failureDetails:
          (!success && rawData is Map<String, dynamic>) ? rawData : null,
      errors: _parseErrors(json['errors']),
    );
  }

  /// Convenience for building a failure locally (e.g. from a caught
  /// exception) without inventing a different shape.
  factory ApiResponse.failure(String message) {
    return ApiResponse<T>(success: false, message: message);
  }

  /// The first validation message for [field], or null if that field is fine.
  String? errorFor(String field) {
    final List<String>? messages = errors?[field];
    return (messages == null || messages.isEmpty) ? null : messages.first;
  }

  static Map<String, List<String>>? _parseErrors(dynamic raw) {
    if (raw is! Map<String, dynamic>) {
      return null;
    }
    return raw.map(
      (String key, dynamic value) => MapEntry<String, List<String>>(
        key,
        value is List
            ? value.map((dynamic e) => e.toString()).toList()
            : <String>[value.toString()],
      ),
    );
  }
}
