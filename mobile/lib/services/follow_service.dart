import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class FollowService {
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

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'User-Agent': 'MusicRoomApp/1.0',
        'ngrok-skip-browser-warning': 'true',
      };

  Future<void> followUser(String userId, String token) async {
    final response = await http.post(
      Uri.parse('$_effectiveBaseUrl/api/users/$userId/follow'),
      headers: _headers(token),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to follow user: ${response.body}');
    }
  }

  Future<void> unfollowUser(String userId, String token) async {
    final response = await http.delete(
      Uri.parse('$_effectiveBaseUrl/api/users/$userId/follow'),
      headers: _headers(token),
    );
    if (response.statusCode != 204) {
      throw Exception('Failed to unfollow user: ${response.body}');
    }
  }

  Future<bool> isFollowing(String userId, String token) async {
    final response = await http.get(
      Uri.parse('$_effectiveBaseUrl/api/users/$userId/is-following'),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as bool;
    }
    return false;
  }

  Future<List<dynamic>> getFollowers(String userId, String token) async {
    final response = await http.get(
      Uri.parse('$_effectiveBaseUrl/api/users/$userId/followers'),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    }
    return [];
  }

  Future<List<dynamic>> getFollowing(String userId, String token) async {
    final response = await http.get(
      Uri.parse('$_effectiveBaseUrl/api/users/$userId/following'),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    }
    return [];
  }
}
