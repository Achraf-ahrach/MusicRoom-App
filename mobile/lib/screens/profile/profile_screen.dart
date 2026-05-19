import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../providers/playlist_provider.dart';
import 'edit_profile_screen.dart';
import 'all_playlists_screen.dart';
import 'settings_screen.dart';
import '../playlist_detail_screen.dart';
import 'followers_following_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch profile on initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.currentUser?.accessToken;
      if (token != null) {
        Provider.of<UserProfileProvider>(
          context,
          listen: false,
        ).fetchProfile(token);
        Provider.of<PlaylistProvider>(
          context,
          listen: false,
        ).loadPlaylists(authProvider.currentUser);
      }
    });
  }

  void _showMoreOptions(BuildContext context) {
    final parentContext = context;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Small drag handle
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.share, color: Colors.white),
                title: const Text(
                  'Share Profile',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(parentContext);
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    const SnackBar(
                      content: Text('Profile link copied to clipboard!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings, color: Colors.white),
                title: const Text(
                  'Settings & Privacy',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(parentContext);
                  Navigator.of(parentContext).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
              const Divider(color: Colors.grey),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text(
                  'Log out',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () {
                  final auth = Provider.of<AuthProvider>(parentContext, listen: false);
                  Navigator.pop(parentContext); // Close bottom sheet
                  auth.logout();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<UserProfileProvider>(context);
    final playlistProvider = Provider.of<PlaylistProvider>(context);
    final profile = profileProvider.profile;

    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Spotify-like dark background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.white),
            onPressed: () => _showMoreOptions(context),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: profileProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : profileProvider.errorMessage != null
          ? Center(
              child: Text(
                profileProvider.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Gradient background at top similar to Spotify
                  Container(
                    height: 280,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF006466), // Deep green/teal
                          Color(0xFF121212),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 60),
                        // Avatar
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: profile?.avatarUrl != null && !profile!.avatarUrl!.contains('photo-1535713875002-d1d0cf377fde')
                              ? NetworkImage(profile.avatarUrl!)
                              : null,
                          backgroundColor: Colors.grey[800],
                          child: profile?.avatarUrl == null || profile!.avatarUrl!.contains('photo-1535713875002-d1d0cf377fde')
                              ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(height: 16),
                        // Edit Profile button
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EditProfileScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[800],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 8,
                            ),
                          ),
                          child: const Text(
                            'Edit Profile',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Stats Row
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40.0,
                      vertical: 16.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatColumn(
                          '${playlistProvider.playlists.length}',
                          'PLAYLISTS',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AllPlaylistsScreen(
                                  playlists: playlistProvider.playlists.map((p) => {
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
                        _buildStatColumn(
                          '${profileProvider.followersCount}',
                          'FOLLOWERS',
                          onTap: () {
                            if (profile != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FollowersFollowingScreen(
                                    userId: profile.id,
                                    displayName: profile.displayName,
                                    initialTab: 0,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                        _buildStatColumn(
                          '${profileProvider.followingCount}',
                          'FOLLOWING',
                          onTap: () {
                            if (profile != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FollowersFollowingScreen(
                                    userId: profile.id,
                                    displayName: profile.displayName,
                                    initialTab: 1,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Display Name (Optional, since visual mockup doesn't explicitly show a large name string, but it's good to have)
                  if (profile != null)
                    Text(
                      profile.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Playlists Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Playlists',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (playlistProvider.playlists.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(
                              child: Text(
                                'No playlists created yet.',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          )
                        else
                          ...playlistProvider.playlists.take(3).map((playlist) {
                            final title = playlist.title.isEmpty ? 'Untitled Playlist' : playlist.title;
                            return _buildPlaylistItem(
                              title,
                              'Playlist',
                              Icons.music_note,
                              imageUrl: playlist.imageUrl,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PlaylistDetailScreen(
                                      playlistId: playlist.id,
                                      initialPlaylist: playlist,
                                      useBackend: true,
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList(),

                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AllPlaylistsScreen(
                                  playlists: playlistProvider.playlists.map((p) => {
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
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'See all playlists',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.grey,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80), // Bottom padding
                ],
              ),
            ),
    );
  }

  Widget _buildStatColumn(String count, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Text(
            count,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistItem(
    String title,
    String subtitle,
    IconData iconPlaceholder,
    {String? imageUrl,
    VoidCallback? onTap}
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.grey[800],
              ),
              clipBehavior: Clip.antiAlias,
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, _, __) => Icon(iconPlaceholder, color: Colors.grey[400], size: 30),
                    )
                  : Icon(iconPlaceholder, color: Colors.grey[400], size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 16),
          ],
        ),
      ),
    );
  }
}

// Temporary Fix for gradient: Change LinearBinding to LinearGradient internally.
// Re-editing code logic since it was typed slightly wrong in memory.
