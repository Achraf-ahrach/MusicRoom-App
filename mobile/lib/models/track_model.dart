class Track {
  final String id;
  final String? playlistTrackId;
  final String title;
  final String? imageUrl;
  final String artistName;
  final String? audioUrl;
  final bool isStreamable;
  final String? description;

  Track({
    required this.id,
    this.playlistTrackId,
    required this.title,
    this.imageUrl,
    required this.artistName,
    this.audioUrl,
    this.isStreamable = true,
    this.description,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    final dynamic rawId = json['id'] ?? json['track_id'];
    final String? streamUrl = json['stream']?['url']?.toString();
    final String? fallbackStreamUrl = rawId != null
        ? 'https://discoveryprovider.audius.co/v1/tracks/$rawId/stream?app_name=MusicRoomApp'
        : null;

    return Track(
      id: rawId?.toString() ?? '',
      title: json['title'] ?? '',
      imageUrl:
          json['artwork']?['150x150'] ??
          json['artwork']?['480x480'] ??
          json['artwork']?['1000x1000'],
      artistName: json['user']?['name'] ?? 'Unknown Artist',
      audioUrl: (streamUrl != null && streamUrl.isNotEmpty)
          ? streamUrl
          : fallbackStreamUrl,
      isStreamable: json['is_streamable'] ?? json['is_available'] ?? true,
      description: json['description'],
    );
  }

  factory Track.fromPlaylistTrackJson(Map<String, dynamic> json) {
    final String? externalId = json['externalId']?.toString() ?? json['external_id']?.toString();
    final String? fallbackStreamUrl = externalId != null && externalId.isNotEmpty
        ? 'https://discoveryprovider.audius.co/v1/tracks/$externalId/stream?app_name=MusicRoomApp'
        : null;

    return Track(
      id: externalId ?? (json['id'] ?? '').toString(),
      playlistTrackId: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      imageUrl: json['coverUrl'] as String?,
      artistName: (json['artist'] ?? 'Unknown Artist').toString(),
      audioUrl: fallbackStreamUrl,
      isStreamable: true,
      description: null,
    );
  }
}
