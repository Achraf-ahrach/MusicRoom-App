import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user_profile_model.dart';

class UserService {
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

  static const String _usersPath = '/api/users';
  static const String _playlistsPath = '/api/playlists';
  static const String _friendshipsPath = '/api/friendships';
  static const String _eventsPath = '/api/events';

  /// Fetches the profile of the currently logged-in user
  Future<UserProfileModel> getCurrentUserProfile(String token) async {
    final response = await http.get(
      Uri.parse('$_effectiveBaseUrl$_usersPath/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'User-Agent': 'MusicRoomApp/1.0',
        'ngrok-skip-browser-warning':
            'true', // cureent ngrok works without this header, but keep it here in case of future issues
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return UserProfileModel.fromJson(decoded);
    } else {
      throw Exception('Failed to load user profile: ${response.statusCode}');
    }
  }

  /// Fetches all events
  Future<List<Map<String, dynamic>>> getAllEvents(String token) async {
    try {
      final url = Uri.parse('$_effectiveBaseUrl$_eventsPath');
      print('DEBUG [getAllEvents]: Requesting $url with token length ${token.length}');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      print('DEBUG [getAllEvents]: Response status = ${response.statusCode}');
      print('DEBUG [getAllEvents]: Response body = ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> allEvents = jsonDecode(response.body);
        return allEvents.cast<Map<String, dynamic>>();
      } else {
        print('DEBUG [getAllEvents]: Failed to load events, status = ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('DEBUG [getAllEvents]: Exception caught = $e');
      print('DEBUG [getAllEvents]: Stacktrace = $stackTrace');
    }
    return [];
  }

  /// Fetches playlists and returns those owned by the current user.
  Future<List<Map<String, dynamic>>> getUserEvents(
    String token,
    String currentUserId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_effectiveBaseUrl$_playlistsPath'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> allPlaylists = jsonDecode(response.body);
        final filteredEvents = allPlaylists
            .where((e) => e['ownerId']?.toString() == currentUserId)
            .toList();
        return filteredEvents.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return []; // fallback
  }

  /// Updates the user's profile
  Future<UserProfileModel> updateUserProfile(
    String token,
    Map<String, dynamic> updateData,
  ) async {
    final response = await http.put(
      Uri.parse('$_effectiveBaseUrl$_usersPath/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',
      },
      body: jsonEncode(updateData),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return UserProfileModel.fromJson(decoded);
    } else {
      throw Exception('Failed to update user profile: ${response.statusCode}');
    }
  }

  /// Updates the user's music preferences
  Future<UserProfileModel> updateUserPreferences(
    String token,
    Map<String, dynamic> preferencesData,
  ) async {
    final response = await http.put(
      Uri.parse('$_effectiveBaseUrl$_usersPath/me/preferences'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',
      },
      body: jsonEncode({'musicPreferences': preferencesData}),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return UserProfileModel.fromJson(decoded);
    } else {
      throw Exception('Failed to update preferences: ${response.statusCode}');
    }
  }

  /// Fetches friends and returns the count (Followers / Following equivalent)
  Future<int> getUserFriendsCount(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_effectiveBaseUrl$_friendshipsPath'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning':
              'true', //current ngrok works without this header, but keep it here in case of future issues
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> validFriends = jsonDecode(response.body);
        return validFriends.length;
      }
    } catch (_) {}
    return 0; // fallback
  }

  /// Fetches friends
  Future<List<dynamic>> getFriends(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_effectiveBaseUrl$_friendshipsPath'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return []; // fallback
  }
}
