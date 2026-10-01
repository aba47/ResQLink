import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/local/models/sync_queue_model.dart';

class ApiClient {
  String baseUrl;
  final http.Client _httpClient;

  ApiClient({
    String? baseUrl,
    http.Client? httpClient,
  })  : baseUrl = baseUrl ?? 'http://10.0.2.2:8000',
        _httpClient = httpClient ?? http.Client();

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

  Future<Map<String, dynamic>> pushSync(String deviceId, List<SyncQueueModel> items) async {
    final body = jsonEncode({
      'device_id': deviceId,
      'items': items.map((i) => i.toMap()).toList(),
    });

    final response = await _httpClient
        .post(
          Uri.parse('$baseUrl/sync/push'),
          headers: {'Content-Type': 'application/json'},
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
          headers: {'Content-Type': 'application/json'},
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
