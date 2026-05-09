import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_profile_model.dart';

class UserService {
  static const String _effectiveBaseUrl = "https://anisa-phenetic-predictively.ngrok-free.dev";
  static const String _usersPath = '/api/users';

  /// Fetches the profile of the currently logged-in user
  Future<UserProfileModel> getCurrentUserProfile(String token) async {
    final response = await http.get(
      Uri.parse('$_effectiveBaseUrl$_usersPath/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
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
}
