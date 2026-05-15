class Playlist {
  final String id;
  final String title;
  final String? imageUrl;
  final String creatorName;

  Playlist({
    required this.id,
    required this.title,
    this.imageUrl,
    required this.creatorName,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] ?? '',
      title: json['playlist_name'] ?? '',
      imageUrl: json['artwork']?['150x150'] ?? json['artwork']?['480x480'],
      creatorName: json['user']?['name'] ?? '',
    );
  }
}
