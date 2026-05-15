import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audius_service.dart';
import '../services/user_service.dart';
import '../models/playlist_model.dart';
import '../models/track_model.dart';
import '../providers/user_profile_provider.dart';
import '../providers/auth_provider.dart';
import '../config/app_theme.dart';
import 'playlist_detail_screen.dart';
import 'profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final AudiusService _audiusService = AudiusService();
  final UserService _userService = UserService();
  bool isLoadingPlaylists = true;
  bool isLoadingTracks = true;
  bool isLoadingEvents = true;
  List<Playlist> trendingPlaylists = [];
  List<Track> trendingTracks = [];
  List<Map<String, dynamic>> events = [];
  String? playlistError;
  String? trackError;
  String? eventError;

  @override
  void initState() {
    super.initState();
    _fetchData();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.currentUser?.accessToken;
      if (token != null) {
        Provider.of<UserProfileProvider>(
          context,
          listen: false,
        ).fetchProfile(token);
        _fetchEvents(token);
      } else {
        setState(() => isLoadingEvents = false);
      }
    });
  }

  Future<void> _fetchData() async {
    await Future.wait([_fetchPlaylists(), _fetchTracks()]);
  }

  Future<void> _fetchEvents(String token) async {
    try {
      setState(() {
        isLoadingEvents = true;
        eventError = null;
      });
      final fetchedEvents = await _userService.getAllEvents(token);
      if (mounted)
        setState(() {
          events = fetchedEvents;
          isLoadingEvents = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          eventError = e.toString();
          isLoadingEvents = false;
        });
    }
  }

  Future<void> _fetchPlaylists() async {
    try {
      setState(() {
        isLoadingPlaylists = true;
        playlistError = null;
      });
      final playlists = await _audiusService.getTrendingPlaylists();
      if (mounted)
        setState(() {
          trendingPlaylists = playlists;
          isLoadingPlaylists = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          playlistError = e.toString();
          isLoadingPlaylists = false;
        });
    }
  }

  Future<void> _fetchTracks() async {
    try {
      setState(() {
        isLoadingTracks = true;
        trackError = null;
      });
      final tracks = await _audiusService.getTrendingTracks();
      if (mounted)
        setState(() {
          trendingTracks = tracks;
          isLoadingTracks = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          trackError = e.toString();
          isLoadingTracks = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _HomeContent();
  }
}

class _HomeContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<HomeScreenState>();
    if (state == null) return const SizedBox.shrink();

    final recentPlaylists = [
      {
        'title': 'Chill Lofi Beats',
        'image':
            'https://images.unsplash.com/photo-1516280440614-37939bbacd81?w=200&h=200&fit=crop',
      },
      {
        'title': '80s Rock Classics',
        'image':
            'https://images.unsplash.com/photo-1498038432885-c6f3f1b912ee?w=200&h=200&fit=crop',
      },
      {
        'title': 'Gym Motivation',
        'image':
            'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=200&h=200&fit=crop',
      },
      {
        'title': 'Top Hits 2026',
        'image':
            'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=200&h=200&fit=crop',
      },
      {
        'title': 'Jazz & Blues',
        'image':
            'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=200&h=200&fit=crop',
      },
      {
        'title': 'Podcast: Tech',
        'image':
            'https://images.unsplash.com/photo-1478737270239-2f02b77fc618?w=200&h=200&fit=crop',
      },
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: AppTheme.background,
            elevation: 0,
            toolbarHeight: 80,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                padding: const EdgeInsets.fromLTRB(16, 50, 16, 0),
                child: Row(
                  children: [
                    Consumer<UserProfileProvider>(
                      builder: (context, profileProvider, child) {
                        final profile = profileProvider.profile;
                        final avatarUrl = profile?.avatarUrl;
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfileScreen(),
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.grey[800],
                            backgroundImage:
                                avatarUrl != null && avatarUrl.isNotEmpty
                                ? NetworkImage(avatarUrl)
                                : const NetworkImage(
                                    'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100&h=100&fit=crop',
                                  ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Home',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final playlist = recentPlaylists[index];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          bottomLeft: Radius.circular(4),
                        ),
                        child: Image.network(
                          playlist['image']!,
                          width: 55,
                          height: 55,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          playlist['title']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }, childCount: recentPlaylists.length),
            ),
          ),
          _buildSectionHeader('Trending Playlists'),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 220,
              child: state.isLoadingPlaylists
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.green),
                    )
                  : state.playlistError != null
                  ? Center(
                      child: Text(
                        'Error: ${state.playlistError}',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: state.trendingPlaylists.length,
                      itemBuilder: (context, index) => _buildPlaylistCard(
                        context,
                        state.trendingPlaylists[index],
                      ),
                    ),
            ),
          ),
          _buildSectionHeader('Events'),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 180,
              child: state.isLoadingEvents
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.green),
                    )
                  : state.eventError != null
                  ? Center(
                      child: Text(
                        'Error loading events',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    )
                  : state.events.isEmpty
                  ? Center(
                      child: Text(
                        'No events found',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: state.events.length,
                      itemBuilder: (context, index) {
                        final event = state.events[index];
                        return Container(
                          width: 140,
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.green.withAlpha(50),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.event,
                                color: Colors.green,
                                size: 40,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                event['title'] ?? "Unnamed Event",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                event['description'] ?? "No description",
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
          _buildSectionHeader('Trending Tracks'),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 220,
              child: state.isLoadingTracks
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.green),
                    )
                  : state.trackError != null
                  ? Center(
                      child: Text(
                        'Error',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: state.trendingTracks.length,
                      itemBuilder: (context, index) =>
                          _buildTrackCard(state.trendingTracks[index]),
                    ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistCard(BuildContext context, Playlist playlist) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlaylistDetailScreen(playlistId: playlist.id),
        ),
      ),
      child: Container(
        width: 155,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Container(
              height: 155,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                image: DecorationImage(
                  image: NetworkImage(playlist.imageUrl ?? ''),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Text(
              playlist.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackCard(Track track) {
    return Container(
      width: 155,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            height: 155,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              image: DecorationImage(
                image: NetworkImage(track.imageUrl ?? ''),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Text(
            track.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
