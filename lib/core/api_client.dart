import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/app_config.dart';
import 'api_exception.dart';

/// A file ready to upload (works on Android, iOS and Web).
class UploadFile {
  UploadFile({required this.bytes, required this.filename});

  final Uint8List bytes;
  final String filename;

  MediaType get mediaType {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return MediaType('image', 'png');
      case 'webp':
        return MediaType('image', 'webp');
      default:
        return MediaType('image', 'jpeg');
    }
  }
}

/// Thin JSON HTTP client for the Laravel player API.
class ApiClient {
  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final String baseUrl;
  final http.Client _http = http.Client();
  String? token;

  /// Called whenever the server answers 401 (expired / revoked token).
  void Function()? onUnauthorized;

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  /// Headers for authenticated image requests (documents, screenshots).
  Map<String, String> get authHeaders => _headers;

  Uri _uri(String path) => Uri.parse(path.startsWith('http') ? path : '$baseUrl/$path');

  Future<Map<String, dynamic>> get(String path) =>
      _send(() => _http.get(_uri(path), headers: _headers));

  Future<Map<String, dynamic>> post(String path, [Map<String, dynamic>? body]) => _send(() => _http.post(
        _uri(path),
        headers: {..._headers, 'Content-Type': 'application/json'},
        body: jsonEncode(body ?? {}),
      ));

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) => _send(() => _http.put(
        _uri(path),
        headers: {..._headers, 'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ));

  /// Multipart POST with text fields and files.
  Future<Map<String, dynamic>> multipart(
    String path, {
    Map<String, String> fields = const {},
    Map<String, UploadFile> files = const {},
  }) {
    return _send(() async {
      final req = http.MultipartRequest('POST', _uri(path))
        ..headers.addAll(_headers)
        ..fields.addAll(fields);
      files.forEach((field, f) {
        req.files.add(http.MultipartFile.fromBytes(field, f.bytes, filename: f.filename, contentType: f.mediaType));
      });
      return http.Response.fromStream(await _http.send(req));
    }, timeout: const Duration(seconds: 90));
  }

  /// Raw bytes (for private images that need the bearer token).
  Future<Uint8List> bytes(String url) async {
    final res = await _http.get(_uri(url), headers: _headers).timeout(AppConfig.requestTimeout);
    if (res.statusCode == 200) return res.bodyBytes;
    if (res.statusCode == 401) onUnauthorized?.call();
    throw ApiException('Could not load image (${res.statusCode}).', statusCode: res.statusCode);
  }

  Future<Map<String, dynamic>> _send(Future<http.Response> Function() request, {Duration? timeout}) async {
    http.Response res;
    try {
      res = await request().timeout(timeout ?? AppConfig.requestTimeout);
    } on TimeoutException {
      throw ApiException('The server is taking too long. Please check your internet and try again.');
    } on http.ClientException {
      // http 1.x wraps socket / DNS errors in ClientException (works on web too)
      throw ApiException('Could not reach the server. Please check your internet and try again.');
    }

    Map<String, dynamic> data = {};
    try {
      final decoded = res.body.isEmpty ? {} : jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) data = decoded;
    } catch (_) {
      // non-JSON response (e.g. server error page)
    }

    if (res.statusCode >= 200 && res.statusCode < 300) return data;

    if (res.statusCode == 401) onUnauthorized?.call();

    final errors = <String, List<String>>{};
    final raw = data['errors'];
    if (raw is Map) {
      raw.forEach((k, v) => errors[k.toString()] = (v as List).map((e) => e.toString()).toList());
    }
    throw ApiException(
      (data['message'] as String?) ?? 'Something went wrong (${res.statusCode}).',
      statusCode: res.statusCode,
      errors: errors,
    );
  }
}
