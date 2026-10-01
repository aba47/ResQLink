import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/local/models/sync_queue_model.dart';
import '../config/env_config.dart';

/// Secure ApiClient with Bearer Token Authorization
class ApiClient {
  String baseUrl;
  final http.Client _httpClient;
  String? _authToken;

  ApiClient({
    String? baseUrl,
    http.Client? httpClient,
    String? initialToken,
  })  : baseUrl = baseUrl ?? EnvConfig.defaultBaseUrl,
        _httpClient = httpClient ?? http.Client(),
        _authToken = initialToken;

  String? get authToken => _authToken;

  void setAuthToken(String token) {
    _authToken = token;
  }

  void clearAuthToken() {
    _authToken = null;
  }

  bool get isAuthenticated => _authToken != null && _authToken!.isNotEmpty;

  Map<String, String> _buildHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  Future<bool> checkHealth() async {
    try {
      final response = await _httpClient
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'healthy';
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> login(String phoneOrEmail, String password) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone_or_email': phoneOrEmail,
        'password': password,
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['access_token'] != null) {
        setAuthToken(data['access_token'] as String);
      }
      return data;
    } else {
      throw Exception('Login failed: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    String? email,
    required String password,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'phone': phone,
        'email': email,
        'password': password,
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['access_token'] != null) {
        setAuthToken(data['access_token'] as String);
      }
      return data;
    } else {
      throw Exception('Registration failed: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Map<String, dynamic>> emergencyGuest() async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/auth/emergency-guest'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['access_token'] != null) {
        setAuthToken(data['access_token'] as String);
      }
      return data;
    } else {
      throw Exception('Guest access failed: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> logout() async {
    try {
      if (_authToken != null) {
        await _httpClient.post(
          Uri.parse('$baseUrl/auth/logout'),
          headers: _buildHeaders(),
        ).timeout(const Duration(seconds: 4));
      }
    } catch (_) {}
    clearAuthToken();
  }

  Future<Map<String, dynamic>> pushSync(String deviceId, List<SyncQueueModel> items) async {
    final body = jsonEncode({
      'device_id': deviceId,
      'items': items.map((i) => i.toMap()).toList(),
    });

    final response = await _httpClient
        .post(
          Uri.parse('$baseUrl/sync/push'),
          headers: _buildHeaders(),
          body: body,
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Server rejected sync push: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Map<String, dynamic>> pullSync(String deviceId, {String? sinceTimestamp}) async {
    final body = jsonEncode({
      'device_id': deviceId,
      'since_timestamp': sinceTimestamp,
    });

    final response = await _httpClient
        .post(
          Uri.parse('$baseUrl/sync/pull'),
          headers: _buildHeaders(),
          body: body,
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Server rejected sync pull: ${response.statusCode} - ${response.body}');
    }
  }
}
