import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_profile_provider.dart';

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
        Provider.of<UserProfileProvider>(context, listen: false).fetchProfile(token);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<UserProfileProvider>(context);
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
            onPressed: () {
              // Handle action
            },
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
                              backgroundImage: profile?.avatarUrl != null
                                  ? NetworkImage(profile!.avatarUrl!)
                                  : null,
                              backgroundColor: Colors.grey[800],
                              child: profile?.avatarUrl == null
                                  ? const Icon(Icons.person, size: 60, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            // Edit Profile button
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[800],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              ),
                              child: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                      
                      // Stats Row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatColumn('23', 'PLAYLISTS'),
                            _buildStatColumn((profile?.friendsInfo.length ?? 0).toString(), 'FOLLOWERS'),
                            _buildStatColumn('43', 'FOLLOWING'),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Display Name (Optional, since visual mockup doesn't explicitly show a large name string, but it's good to have)
                      if (profile != null)
                        Text(
                          profile.displayName,
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
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
                              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            _buildPlaylistItem('Shazam', '7 likes', Icons.music_note),
                            _buildPlaylistItem('Roadtrip', '4 likes', Icons.directions_car),
                            _buildPlaylistItem('Study', '5 likes', Icons.book),
                            const SizedBox(height: 16),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'See all playlists',
                                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                              ],
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

  Widget _buildStatColumn(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.grey[400], fontSize: 12, letterSpacing: 1.0),
        ),
      ],
    );
  }

  Widget _buildPlaylistItem(String title, String subtitle, IconData iconPlaceholder) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            color: Colors.grey[800],
            child: Icon(iconPlaceholder, color: Colors.grey[400], size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 16),
        ],
      ),
    );
  }
}

// Temporary Fix for gradient: Change LinearBinding to LinearGradient internally.
// Re-editing code logic since it was typed slightly wrong in memory.
