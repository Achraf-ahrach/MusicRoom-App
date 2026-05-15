class Track {
  final String id;
  final String title;
  final String? imageUrl;
  final String artistName;

  Track({
    required this.id,
    required this.title,
    this.imageUrl,
    required this.artistName,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      imageUrl: json['artwork']?['150x150'] ?? json['artwork']?['480x480'],
      artistName: json['user']?['name'] ?? '',
    );
  }
}
