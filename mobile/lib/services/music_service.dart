import 'dart:convert';
import 'package:http/http.dart' as http;

class MusicService {
  // If running on iOS Simulator: 127.0.0.1.
  // If running on Android Emulator: 10.0.2.2.
  static const String _baseUrl = 'http://127.0.0.1:3000';

  static Future<Map<String, dynamic>> fetchHomeData() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/home'));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load home data');
    }
  }
}
