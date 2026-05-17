import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/track_model.dart';

class EventService {
  String get _effectiveBaseUrl {
    final url = dotenv.env['API_URL'];
    if (url != null && url.isNotEmpty) {
      if (url.contains('localhost') && !kIsWeb && Platform.isAndroid) {
        return url.replaceAll('localhost', '10.0.2.2');
      }
      return url;
    }
    if (kIsWeb) return 'http://localhost:8080';
    if (Platform.isAndroid) return 'http://10.0.2.2:8080';
    return 'http://localhost:8080';
  }

  String get baseUrl => _effectiveBaseUrl;

  static const String _eventsPath = '/api/events';

  Future<void> createEvent(
    String name,
    String description,
    bool isPrivate,
    String token,
  ) async {
    final url = Uri.parse('$_effectiveBaseUrl$_eventsPath');
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
    final url = Uri.parse('$_effectiveBaseUrl$_eventsPath/$eventId/invite');
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

  // Get current user role and access for an event
  Future<Map<String, dynamic>> getEventUserRole(String eventId, String token) async {
    final url = Uri.parse('$_effectiveBaseUrl$_eventsPath/$eventId/role');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch event role: ${response.statusCode}');
    }
  }

  // Get current event details
  Future<Map<String, dynamic>> getEventById(String eventId, String token) async {
    final url = Uri.parse('$_effectiveBaseUrl$_eventsPath/$eventId');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch event details: ${response.statusCode}');
    }
  }

  // Get event playlist
  Future<List<Map<String, dynamic>>> getEventPlaylist(String eventId, String token) async {
    final url = Uri.parse('$_effectiveBaseUrl$_eventsPath/$eventId/playlist');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(utf8.decode(response.bodyBytes));
      return list.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch event playlist: ${response.statusCode}');
    }
  }

  // Suggest track to event
  Future<Map<String, dynamic>> suggestTrack(String eventId, Track track, String token) async {
    final url = Uri.parse('$_effectiveBaseUrl$_eventsPath/$eventId/playlist');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',
      },
      body: jsonEncode({
        'externalId': track.id,
        'provider': 'audius',
        'title': track.title,
        'artist': track.artistName,
        'album': '',
        'coverUrl': track.imageUrl ?? '',
        'durationMs': null,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } else {
      final errorMsg = response.body.trim().isEmpty 
          ? 'Status ${response.statusCode}' 
          : response.body;
      throw Exception('Failed to suggest track: $errorMsg');
    }
  }
}
