class Playlist {
  final String id;
  final String title;
  final String? imageUrl;
  final String creatorName;
  final int version;
  final String visibility;
  final String ownerId;
  final String? permission;

  Playlist({
    required this.id,
    required this.title,
    this.imageUrl,
    required this.creatorName,
    required this.version,
    this.visibility = 'public',
    this.ownerId = '',
    this.permission,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    final dynamic rawId = json['id'];
    final String parsedId = rawId == null ? '' : rawId.toString();
    final String parsedTitle =
        (json['name'] ?? json['title'] ?? json['playlist_name'] ?? '').toString();
    final String parsedCreatorName =
        (json['ownerName'] ?? json['creatorName'] ?? json['user']?['name'] ?? '').toString();
    final int parsedVersion = json['version'] is int
        ? json['version'] as int
        : int.tryParse('${json['version'] ?? 0}') ?? 0;
    final String parsedVisibility = (json['visibility'] ?? 'public').toString();
    final String parsedOwnerId = (json['ownerId'] ?? '').toString();
    final String? parsedPermission = json['permission']?.toString();

    return Playlist(
      id: parsedId,
      title: parsedTitle,
      imageUrl: json['coverUrl'] ?? json['artwork']?['150x150'] ?? json['artwork']?['480x480'],
      creatorName: parsedCreatorName,
      version: parsedVersion,
      visibility: parsedVisibility,
      ownerId: parsedOwnerId,
      permission: parsedPermission,
    );
  }
}
