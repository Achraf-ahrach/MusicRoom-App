import 'dart:convert';
import 'package:http/http.dart' as http;

/// Handles all HTTP communication with the authentication backend.
/// Base URL points to Android emulator localhost (127.0.0.1:3000).
class AuthService {
  // Android emulator maps 10.0.2.2 → host machine's localhost
  static const String _baseUrl = 'http://127.0.0.1:3000';

  /// POST /login
  /// Returns the full parsed response body.
  /// Throws [AuthException] on failure.
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw AuthException(body['error'] as String? ?? 'Login failed');
    }

    return body;
  }

  /// POST /signup
  /// Returns the full parsed response body (includes token).
  /// Throws [AuthException] on failure.
  Future<Map<String, dynamic>> signup({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': fullName,
        'email': email,
        'password': password,
      }),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw AuthException(body['error'] as String? ?? 'Signup failed');
    }

    return body;
  }

  /// POST /verify-otp
  /// Verifies a user account using the OTP from signup.
  /// Returns the response body which now includes tokens.
  /// Throws [AuthException] on failure.
  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'token': otp}),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw AuthException(body['error'] as String? ?? 'Verification failed');
    }

    return body;
  }

  /// POST /resend-otp
  /// Generates and sends a new OTP for an unverified user.
  /// Throws [AuthException] on failure.
  Future<void> resendOtp({
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/resend-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw AuthException(body['error'] as String? ?? 'Failed to resend OTP');
    }
  }

  /// POST /forgot-password
  /// Requests an OTP for password reset.
  /// Throws [AuthException] on failure.
  Future<void> forgotPassword({
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw AuthException(body['error'] as String? ?? 'Failed to request password reset');
    }
  }

  /// POST /verify-reset-otp
  /// Verifies the OTP for password reset.
  /// Throws [AuthException] on failure.
  Future<void> verifyResetOtp({
    required String email,
    required String otp,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/verify-reset-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'token': otp}),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw AuthException(body['error'] as String? ?? 'Verification failed');
    }
  }

  /// POST /reset-password
  /// Resets the user's password and returns tokens.
  /// Throws [AuthException] on failure.
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'token': otp,
        'newPassword': newPassword,
      }),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw AuthException(body['error'] as String? ?? 'Failed to reset password');
    }

    return body;
  }
}

/// Custom exception for auth-related errors.
/// Carries a user-friendly message from the backend.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}
