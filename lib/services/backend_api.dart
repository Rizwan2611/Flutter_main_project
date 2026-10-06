import 'dart:convert';

import 'package:http/http.dart' as http;

class BackendApi {
  const BackendApi({this.baseUrl = _configuredBaseUrl});

  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  final String baseUrl;

  bool get isConfigured => baseUrl.isNotEmpty;

  Future<AuthenticatedUser> signUp({
    required String name,
    required String email,
    required String password,
  }) => _authenticate('/api/auth/signup', <String, String>{
    'name': name,
    'email': email,
    'password': password,
  });

  Future<AuthenticatedUser> logIn({
    required String email,
    required String password,
  }) => _authenticate('/api/auth/login', <String, String>{
    'email': email,
    'password': password,
  });

  Future<AuthenticatedUser> _authenticate(
    String path,
    Map<String, String> body,
  ) async {
    final http.Response response = await http.post(
      _uri(path),
      headers: const <String, String>{'content-type': 'application/json'},
      body: jsonEncode(body),
    );
    final Map<String, dynamic> payload = _payload(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BackendException(payload['error'] as String? ?? 'Could not authenticate.');
    }
    final Map<String, dynamic> user = payload['user'] as Map<String, dynamic>;
    return AuthenticatedUser(
      token: payload['token'] as String,
      name: user['name'] as String,
      email: user['email'] as String,
    );
  }

  Future<List<String>> getFavorites(String token) async {
    final Map<String, dynamic> payload = await _get('/api/me/favorites', token);
    return (payload['favorites'] as List<dynamic>).cast<String>();
  }

  Future<void> putFavorites(String token, Iterable<String> favorites) => _put(
    '/api/me/favorites',
    token,
    <String, Object>{'favorites': favorites.toList()},
  );

  Future<Map<String, bool>> getPreferences(String token) async {
    final Map<String, dynamic> payload = await _get('/api/me/preferences', token);
    final Map<String, dynamic> preferences =
        payload['preferences'] as Map<String, dynamic>;
    return preferences.map(
      (String key, dynamic value) => MapEntry<String, bool>(key, value as bool),
    );
  }

  Future<void> putPreferences(String token, Map<String, bool> preferences) =>
      _put('/api/me/preferences', token, <String, Object>{'preferences': preferences});

  Future<Map<String, dynamic>> _get(String path, String token) async {
    final http.Response response = await http.get(_uri(path), headers: _headers(token));
    return _successfulPayload(response);
  }

  Future<void> _put(String path, String token, Map<String, Object> body) async {
    final http.Response response = await http.put(
      _uri(path),
      headers: _headers(token),
      body: jsonEncode(body),
    );
    _successfulPayload(response);
  }

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Map<String, String> _headers(String token) => <String, String>{
    'authorization': 'Bearer $token',
    'content-type': 'application/json',
  };

  Map<String, dynamic> _successfulPayload(http.Response response) {
    final Map<String, dynamic> payload = _payload(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BackendException(payload['error'] as String? ?? 'Server request failed.');
    }
    return payload;
  }

  Map<String, dynamic> _payload(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw const BackendException('The server returned an invalid response.');
    }
  }
}

class AuthenticatedUser {
  const AuthenticatedUser({
    required this.token,
    required this.name,
    required this.email,
  });

  final String token;
  final String name;
  final String email;
}

class BackendException implements Exception {
  const BackendException(this.message);
  final String message;

  @override
  String toString() => message;
}
