import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_profile_model.dart';

class UserService {
  String get _effectiveBaseUrl {
    final url = 'https://anisa-phenetic-predictively.ngrok-free.dev';
    return url;
  }

  static const String _usersPath = '/api/users';
  static const String _playlistsPath = '/api/playlists';
  static const String _friendshipsPath = '/api/friendships';

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

  /// Fetches all accessible playlists
  Future<List<Map<String, dynamic>>> getAllEvents(String token) async {
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
        return allPlaylists.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
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
}
