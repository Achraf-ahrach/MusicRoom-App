class UserProfileModel {
  final String id;
  final String displayName;
  final String? avatarUrl;
  final String? email;
  final Map<String, dynamic> publicInfo;
  final Map<String, dynamic> friendsInfo;
  final Map<String, dynamic> privateInfo;
  final Map<String, dynamic> musicPreferences;

  UserProfileModel({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.email,
    required this.publicInfo,
    required this.friendsInfo,
    required this.privateInfo,
    required this.musicPreferences,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'User',
      avatarUrl: json['avatarUrl'] as String?,
      email: json['email'] as String?,
      publicInfo: json['publicInfo'] != null ? Map<String, dynamic>.from(json['publicInfo']) : {},
      friendsInfo: json['friendsInfo'] != null ? Map<String, dynamic>.from(json['friendsInfo']) : {},
      privateInfo: json['privateInfo'] != null ? Map<String, dynamic>.from(json['privateInfo']) : {},
      musicPreferences: json['musicPreferences'] != null ? Map<String, dynamic>.from(json['musicPreferences']) : {},
    );
  }
}
