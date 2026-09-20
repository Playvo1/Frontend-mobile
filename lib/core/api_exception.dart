/// Why a request failed before the server could answer with the unified
/// contract. Business failures (wrong password, validation) are NOT
/// exceptions — they come back as `ApiResponse.success == false`.
enum ApiFailureKind { noInternet, timeout, server, malformedResponse, unexpected }

/// Raised for transport-level failures only (Guidelines 2.1: use
/// exceptions, never swallow errors silently). The UI translates [kind]
/// into a localized message; it never shows [technicalMessage] to a user.
class ApiException implements Exception {
  const ApiException(this.kind, [this.technicalMessage]);

  final ApiFailureKind kind;
  final String? technicalMessage;

  @override
  String toString() => 'ApiException($kind): ${technicalMessage ?? ''}';
}
