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

  /// Fetches the profile of any user by ID
  Future<UserProfileModel> getUserProfile(String userId, String token) async {
    final response = await http.get(
      Uri.parse('$_effectiveBaseUrl$_usersPath/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'User-Agent': 'MusicRoomApp/1.0',
        'ngrok-skip-browser-warning': 'true',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return UserProfileModel.fromJson(decoded);
    } else {
      throw Exception('Failed to load user profile: ${response.statusCode}');
    }
  }

  /// Fetches all events (with retry and timeout)
  Future<List<Map<String, dynamic>>> getAllEvents(String token) async {
    const maxRetries = 2;
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final url = Uri.parse('$_effectiveBaseUrl$_eventsPath');
        print('DEBUG [getAllEvents]: Attempt ${attempt + 1} - Requesting $url');
        final response = await http.get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
            'ngrok-skip-browser-warning': 'true',
          },
        ).timeout(const Duration(seconds: 10));

        print('DEBUG [getAllEvents]: Response status = ${response.statusCode}');

        if (response.statusCode == 200) {
          final List<dynamic> allEvents = jsonDecode(response.body);
          print('DEBUG [getAllEvents]: Got ${allEvents.length} events');
          return allEvents.cast<Map<String, dynamic>>();
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          throw Exception('Auth error: ${response.statusCode}');
        } else {
          print('DEBUG [getAllEvents]: Failed, status = ${response.statusCode}');
          if (attempt < maxRetries) {
            await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
            continue;
          }
        }
      } catch (e, stackTrace) {
        print('DEBUG [getAllEvents]: Attempt ${attempt + 1} exception = $e');
        if (e.toString().contains('401') || e.toString().contains('403')) {
          rethrow;
        }
        if (attempt < maxRetries) {
          await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
          continue;
        }
        print('DEBUG [getAllEvents]: All retries exhausted. Stacktrace = $stackTrace');
      }
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

  /// Searches users by name
  Future<List<dynamic>> searchUsers(String query, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_effectiveBaseUrl$_friendshipsPath/search?name=${Uri.encodeComponent(query)}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (_) {}
    return [];
  }
}
