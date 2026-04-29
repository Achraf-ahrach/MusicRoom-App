import 'dart:convert';

/// Represents an authenticated user.
/// Serializable to/from JSON for SharedPreferences persistence.
class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String accessToken;
  final String refreshToken;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.accessToken,
    required this.refreshToken,
  });

  /// Create a UserModel from a JSON map (API response or SharedPreferences).
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
    );
  }

  /// Convert to JSON map for persistence.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };
  }

  /// Encode to a JSON string (for SharedPreferences).
  String encode() => jsonEncode(toJson());

  /// Decode from a JSON string (from SharedPreferences).
  static UserModel decode(String jsonString) {
    return UserModel.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  @override
  String toString() => 'UserModel(id: $id, fullName: $fullName, email: $email)';
}
