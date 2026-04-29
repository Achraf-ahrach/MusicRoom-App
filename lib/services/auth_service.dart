import 'dart:convert';
import 'package:http/http.dart' as http;

/// Handles all HTTP communication with the authentication backend.
/// Base URL points to Android emulator localhost (127.0.0.1:3000).
class AuthService {
  // Android emulator maps 10.0.2.2 → host machine's localhost
  static const String _baseUrl = 'https://anisa-phenetic-predictively.ngrok-free.dev';
  static const String _authPath = '/api/auth';

  /// POST /login
  /// Returns the full parsed response body.
  /// Throws [AuthException] on failure.
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$_authPath/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final decoded = _decodeBody(response.body);
    final body = _toMap(decoded);

    if (response.statusCode != 200) {
      throw AuthException(_extractErrorMessage(decoded, 'Login failed'));
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
      Uri.parse('$_baseUrl$_authPath/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'displayname': fullName,
        'email': email,
        'password': password,
      }),
    );

    final decoded = _decodeBody(response.body);
    final body = _toMap(decoded);

    if (response.statusCode != 200) {
      throw AuthException(_extractErrorMessage(decoded, 'Signup failed'));
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
      Uri.parse('$_baseUrl$_authPath/verify-email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'verificationCode': otp}),
    );

    final decoded = _decodeBody(response.body);
    final body = _toMap(decoded);

    if (response.statusCode != 200) {
      throw AuthException(_extractErrorMessage(decoded, 'Verification failed'));
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
      Uri.parse('$_baseUrl$_authPath/send-verification-email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    final decoded = _decodeBody(response.body);

    if (response.statusCode != 200) {
      throw AuthException(
        _extractErrorMessage(decoded, 'Failed to resend OTP'),
      );
    }
  }

  /// POST /forgot-password
  /// Requests an OTP for password reset.
  /// Throws [AuthException] on failure.
  Future<void> forgotPassword({
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$_authPath/send-verification-email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    final decoded = _decodeBody(response.body);

    if (response.statusCode != 200) {
      throw AuthException(
        _extractErrorMessage(decoded, 'Failed to request password reset'),
      );
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
      Uri.parse('$_baseUrl$_authPath/verify-email-password-reset'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'verificationCode': otp}),
    );

    final decoded = _decodeBody(response.body);

    if (response.statusCode != 200) {
      throw AuthException(_extractErrorMessage(decoded, 'Verification failed'));
    }
  }

  /// POST /reset-password
  /// Resets the user's password and returns tokens.
  /// Throws [AuthException] on failure.
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$_authPath/Password-reset-change'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'verificationCode': otp,
        'newPassword': newPassword,
      }),
    );

    final decoded = _decodeBody(response.body);

    if (response.statusCode != 200) {
      throw AuthException(
        _extractErrorMessage(decoded, 'Failed to reset password'),
      );
    }

  }

  /// POST /auth/google
  /// Sends Google profile data to the backend for login/auto-registration.
  /// Returns the full response body (includes user, accessToken, refreshToken).
  /// Throws [AuthException] on failure.
  Future<Map<String, dynamic>> googleSignIn({
    required String idToken,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$_authPath/google-login'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
    );

    final decoded = _decodeBody(response.body);
    final body = _toMap(decoded);

    if (response.statusCode != 200) {
      throw AuthException(_extractErrorMessage(decoded, 'Google sign-in failed'));
    }

    return body;
  }

  dynamic _decodeBody(String body) {
    if (body.trim().isEmpty) return <String, dynamic>{};
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }

  Map<String, dynamic> _toMap(dynamic decoded) {
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return <String, dynamic>{'message': decoded.toString()};
  }

  String _extractErrorMessage(dynamic decoded, String fallback) {
    if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);
      final error = map['error'];
      if (error is String && error.trim().isNotEmpty) return error;

      final message = map['message'];
      if (message is String && message.trim().isNotEmpty) return message;

      final detail = map['detail'];
      if (detail is String && detail.trim().isNotEmpty) return detail;

      final errors = map['errors'];
      if (errors is List && errors.isNotEmpty) {
        final first = errors.first;
        if (first is String && first.trim().isNotEmpty) return first;
        if (first is Map) {
          final firstMap = Map<String, dynamic>.from(first);
          final firstMsg = firstMap['message'];
          if (firstMsg is String && firstMsg.trim().isNotEmpty) {
            return firstMsg;
          }
          final firstDefault = firstMap['defaultMessage'];
          if (firstDefault is String && firstDefault.trim().isNotEmpty) {
            return firstDefault;
          }
        }
      }
    }

    if (decoded is String && decoded.trim().isNotEmpty) {
      return decoded;
    }

    return fallback;
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
