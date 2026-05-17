import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class EventService {
  String get _effectiveBaseUrl {
    final url = dotenv.env['API_URL'];
    if (url != null && url.isNotEmpty) {
      if (url.contains('localhost') && !kIsWeb && Platform.isAndroid) {
        return url.replaceAll('localhost', '10.0.2.2');
      }
      return url;
    }
    if (kIsWeb) return 'http://localhost:8080/api';
    if (Platform.isAndroid) return 'http://10.0.2.2:8080/api';
    return 'http://localhost:8080/api';
  }

  Future<void> createEvent(
    String name,
    String description,
    bool isPrivate,
    String token,
  ) async {
    final url = Uri.parse('$_effectiveBaseUrl/events');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',
      },
      body: jsonEncode({
        'name': name,
        'description': description,
        'visibility': isPrivate ? 'private' : 'public',
      }),
    );

    if (response.statusCode != 201) {
      final errorMsg = response.body.trim().isEmpty 
          ? 'Status ${response.statusCode}' 
          : response.body;
      throw Exception('Failed to create event: $errorMsg');
    }
  }

  Future<void> inviteUser(String eventId, String userId, String token) async {
    final url = Uri.parse('$_effectiveBaseUrl/events/$eventId/invite');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',
      },
      body: jsonEncode({'userId': userId, 'role': 'voter'}),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to invite user');
    }
  }
}
