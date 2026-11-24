/// Error thrown by [ApiClient]. `message` is always user-friendly.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.errors = const {}});

  final String message;
  final int? statusCode;

  /// Laravel validation errors: field → messages.
  final Map<String, List<String>> errors;

  bool get isUnauthorized => statusCode == 401;

  String? fieldError(String field) {
    final list = errors[field];
    return (list == null || list.isEmpty) ? null : list.first;
  }

  @override
  String toString() => message;
}
