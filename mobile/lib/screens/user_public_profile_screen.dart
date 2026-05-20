import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/playlist_model.dart';
import '../models/user_profile_model.dart';
import '../providers/auth_provider.dart';
import '../services/follow_service.dart';
import '../services/playlist_service.dart';
import '../services/user_service.dart';
import 'playlist_detail_screen.dart';
import 'profile/followers_following_screen.dart';
import 'profile/all_playlists_screen.dart';

class UserPublicProfileScreen extends StatefulWidget {
  final String userId;
  final String displayName;

  const UserPublicProfileScreen({
    super.key,
    required this.userId,
    required this.displayName,
  });

  @override
  State<UserPublicProfileScreen> createState() =>
      _UserPublicProfileScreenState();
}

class _UserPublicProfileScreenState extends State<UserPublicProfileScreen> {
  bool _isFollowing = false;
  int _followersCount = 0;
  int _followingCount = 0;
  List<Playlist> _playlists = [];
  bool _isLoading = true;
  UserProfileModel? _profile;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final token =
        Provider.of<AuthProvider>(context, listen: false).currentUser?.accessToken;
    if (token == null) return;

    final followService = FollowService();
    final playlistService = PlaylistService();

    try {
      final results = await Future.wait([
        followService.isFollowing(widget.userId, token),
        followService.getFollowers(widget.userId, token),
        followService.getFollowing(widget.userId, token),
        playlistService.getPublicPlaylistsByUser(widget.userId, token),
        UserService().getUserProfile(widget.userId, token),
      ]);

      if (!mounted) return;
      setState(() {
        _isFollowing = results[0] as bool;
        _followersCount = (results[1] as List).length;
        _followingCount = (results[2] as List).length;
        _playlists = results[3] as List<Playlist>;
        _profile = results[4] as UserProfileModel;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading public profile: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFollow() async {
    final token =
        Provider.of<AuthProvider>(context, listen: false).currentUser?.accessToken;
    if (token == null) return;
    final followService = FollowService();
    try {
      if (_isFollowing) {
        await followService.unfollowUser(widget.userId, token);
        setState(() {
          _isFollowing = false;
          _followersCount = (_followersCount - 1).clamp(0, 9999);
        });
      } else {
        await followService.followUser(widget.userId, token);
        setState(() {
          _isFollowing = true;
          _followersCount++;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
    final isOwnProfile = currentUserId == widget.userId;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : CustomScrollView(
              slivers: [
                // ── App Bar ──────────────────────────────────────────────────
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 220,
                  backgroundColor: AppTheme.background,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppTheme.accent.withValues(alpha: 0.4),
                            AppTheme.background,
                          ],
                        ),
                      ),
                      child: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            // Avatar
                            CircleAvatar(
                              radius: 46,
                              backgroundImage: _profile?.avatarUrl != null &&
                                      (_profile!.avatarUrl!.isNotEmpty) &&
                                      !_profile!.avatarUrl!.contains('photo-1535713875002-d1d0cf377fde')
                                  ? NetworkImage(_profile!.avatarUrl!)
                                  : null,
                              backgroundColor: AppTheme.surface,
                              child: (() {
                                final av = _profile?.avatarUrl;
                                final showDefault = av == null ||
                                    av.isEmpty ||
                                    av.contains('photo-1535713875002-d1d0cf377fde');
                                return showDefault
                                    ? Text(
                                        widget.displayName.isNotEmpty
                                            ? widget.displayName[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null;
                              })(),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              widget.displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Stats Row ─────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _statItem(
                          '$_followersCount',
                          'Followers',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FollowersFollowingScreen(
                                  userId: widget.userId,
                                  displayName: widget.displayName,
                                  initialTab: 0,
                                ),
                              ),
                            );
                          },
                        ),
                        Container(width: 1, height: 32, color: Colors.white24),
                        _statItem(
                          '$_followingCount',
                          'Following',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FollowersFollowingScreen(
                                  userId: widget.userId,
                                  displayName: widget.displayName,
                                  initialTab: 1,
                                ),
                              ),
                            );
                          },
                        ),
                        Container(width: 1, height: 32, color: Colors.white24),
                        _statItem(
                          '${_playlists.length}',
                          'Playlists',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AllPlaylistsScreen(
                                  playlists: _playlists.map((p) => {
                                    'name': p.title,
                                    'id': p.id,
                                    'creatorName': p.creatorName,
                                    'imageUrl': p.imageUrl,
                                    'trackCount': p.trackCount,
                                    'playlist': p,
                                  }).toList(),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Follow Button ─────────────────────────────────────────────
                if (!isOwnProfile)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _toggleFollow,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: _isFollowing
                                  ? Colors.white38
                                  : AppTheme.accent,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: _isFollowing
                                ? Colors.transparent
                                : AppTheme.accent.withValues(alpha: 0.1),
                          ),
                          child: Text(
                            _isFollowing ? 'Following' : 'Follow',
                            style: TextStyle(
                              color:
                                  _isFollowing ? Colors.white54 : AppTheme.accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // ── Public Info ───────────────────────────────────────────────
                if (_hasPublicInfo())
                  SliverToBoxAdapter(
                    child: _buildInfoCard(
                      icon: Icons.public,
                      title: 'About',
                      pillLabel: 'Public',
                      pillColor: const Color(0xFF1DB954),
                      rows: [
                        if ((_profile?.publicInfo['bio'] ?? '').toString().isNotEmpty)
                          _infoRow(Icons.info_outline, 'Bio', _profile!.publicInfo['bio'].toString()),
                        if ((_profile?.publicInfo['location'] ?? '').toString().isNotEmpty)
                          _infoRow(Icons.location_on_outlined, 'Location', _profile!.publicInfo['location'].toString()),
                        if ((_profile?.publicInfo['website'] ?? '').toString().isNotEmpty)
                          _infoRow(Icons.link, 'Website', _profile!.publicInfo['website'].toString()),
                      ],
                    ),
                  ),

                // ── Friends Info (only if backend returned it = we are friends) ─
                if (_hasFriendsInfo())
                  SliverToBoxAdapter(
                    child: _buildInfoCard(
                      icon: Icons.group,
                      title: 'Friends info',
                      pillLabel: 'Friends only',
                      pillColor: const Color(0xFFFFC107),
                      rows: _buildFriendsInfoRows(),
                    ),
                  ),

                // ── Section Header ────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                    child: Text(
                      'Public Playlists',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),

                // ── Playlists ─────────────────────────────────────────────────
                _playlists.isEmpty
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              'No public playlists yet',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 15),
                            ),
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              _buildPlaylistTile(_playlists[index]),
                          childCount: _playlists.length,
                        ),
                      ),

                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<Widget> _buildFriendsInfoRows() {
    final fri = _profile?.friendsInfo ?? {};
    return [
      if ((fri['phone'] ?? '').toString().isNotEmpty)
        _infoRow(Icons.phone_outlined, 'Phone', fri['phone'].toString()),
      if ((fri['birthday'] ?? '').toString().isNotEmpty)
        _infoRow(Icons.cake_outlined, 'Birthday', fri['birthday'].toString()),
      if ((fri['instagram'] ?? '').toString().isNotEmpty)
        _infoRow(Icons.alternate_email, 'Instagram', fri['instagram'].toString()),
    ];
  }

  bool _hasPublicInfo() {
    final pub = _profile?.publicInfo ?? {};
    return ['bio', 'location', 'website']
        .any((k) => (pub[k] ?? '').toString().isNotEmpty);
  }

  bool _hasFriendsInfo() {
    // Backend returns null for friendsInfo when requester is not a friend.
    // A non-null but possibly empty map means we ARE friends.
    final fri = _profile?.friendsInfo;
    if (fri == null) return false;
    return ['phone', 'birthday', 'instagram']
        .any((k) => (fri[k] ?? '').toString().isNotEmpty);
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String pillLabel,
    required Color pillColor,
    required List<Widget> rows,
  }) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: pillColor, size: 16),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: pillColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: pillColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  pillLabel,
                  style: TextStyle(
                    color: pillColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(children: rows),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white38, size: 18),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistTile(Playlist playlist) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: playlist.imageUrl != null && playlist.imageUrl!.isNotEmpty
            ? Image.network(
                playlist.imageUrl!,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _defaultCover(),
              )
            : _defaultCover(),
      ),
      title: Text(
        playlist.title.isEmpty ? 'Untitled' : playlist.title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        'Playlist • ${playlist.creatorName}',
        style: TextStyle(color: Colors.white54, fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.white38),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlaylistDetailScreen(
            playlistId: playlist.id,
            initialPlaylist: playlist,
            useBackend: true,
          ),
        ),
      ),
    );
  }

  Widget _defaultCover() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.music_note, color: Colors.white38, size: 24),
    );
  }
}
