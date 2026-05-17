import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audius_service.dart';
import '../services/user_service.dart';
import '../models/track_model.dart';
import '../providers/user_profile_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/playlist_provider.dart';
import '../config/app_theme.dart';
import 'create_event_screen.dart';
import 'manage_delegations_screen.dart';
import 'invite_friends_screen.dart';
import 'profile/profile_screen.dart';
import 'playlist_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final AudiusService _audiusService = AudiusService();
  final UserService _userService = UserService();
  bool isLoadingTracks = true;
  bool isLoadingEvents = true;
  List<Track> trendingTracks = [];
  List<Map<String, dynamic>> events = [];
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
        Provider.of<PlaylistProvider>(
          context,
          listen: false,
        ).loadPlaylists(authProvider.currentUser);
        _fetchEvents(token);
      } else {
        setState(() => isLoadingEvents = false);
      }
    });
  }

  Future<void> _fetchData() async {
    await _fetchTracks();
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

    return Consumer<PlaylistProvider>(
      builder: (context, playlistProvider, child) {
        final playlists = playlistProvider.playlists;
        final displayPlaylists = playlists.take(6).toList();

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
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ProfileScreen(),
                                  ),
                                );
                              },
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.grey[800],
                                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty && !avatarUrl.contains('photo-1535713875002-d1d0cf377fde')
                                    ? NetworkImage(avatarUrl)
                                    : null,
                                child: avatarUrl == null || avatarUrl.isEmpty || avatarUrl.contains('photo-1535713875002-d1d0cf377fde')
                                    ? const Icon(
                                        Icons.person,
                                        size: 18,
                                        color: Colors.white70,
                                      )
                                    : null,
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
              if (displayPlaylists.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final playlist = displayPlaylists[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlaylistDetailScreen(
                                  playlistId: playlist.id,
                                  initialPlaylist: playlist,
                                  useBackend: true,
                                ),
                              ),
                            );
                          },
                          child: Container(
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
                                  child: playlist.imageUrl != null && playlist.imageUrl!.isNotEmpty
                                      ? Image.network(
                                          playlist.imageUrl!,
                                          width: 55,
                                          height: 55,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            width: 55,
                                            height: 55,
                                            color: Colors.grey[800],
                                            child: const Icon(Icons.music_note, color: Colors.white54),
                                          ),
                                        )
                                      : Container(
                                          width: 55,
                                          height: 55,
                                          color: Colors.grey[800],
                                          child: const Icon(Icons.music_note, color: Colors.white54),
                                        ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          playlist.title,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (playlist.visibility == 'private') ...[
                                        const SizedBox(width: 4),
                                        const Padding(
                                          padding: EdgeInsets.only(right: 8.0),
                                          child: Icon(
                                            Icons.lock_outline_rounded,
                                            color: Colors.redAccent,
                                            size: 14,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: displayPlaylists.length,
                    ),
                  ),
                ),

          _buildEventsSectionHeader(context),
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
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: state.events.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CreateEventScreen(),
                                ),
                              ).then((_) {
                                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                final token = authProvider.currentUser?.accessToken;
                                if (token != null) {
                                  state._fetchEvents(token);
                                }
                              });
                            },
                            child: Container(
                              width: 140,
                              margin: const EdgeInsets.only(right: 16),
                              decoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.green.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      color: Colors.green,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    "Create Event",
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Host a live room",
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final event = state.events[index - 1];
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        final currentUserId = authProvider.currentUser?.id;
                        final isOwner = event['ownerId'] == currentUserId;

                        return GestureDetector(
                          onTap: () {
                            if (isOwner) {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: AppTheme.background,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                ),
                                builder: (context) => Container(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event['name'] ?? "Event Actions",
                                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 16),
                                      ListTile(
                                        leading: const Icon(Icons.people_outline, color: Colors.green),
                                        title: const Text('Manage Co-Hosts & DJs', style: TextStyle(color: Colors.white)),
                                        subtitle: const Text('Delegate room controller privileges', style: TextStyle(color: Colors.white70)),
                                        onTap: () {
                                          Navigator.pop(context);
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ManageDelegationsScreen(
                                                resourceId: event['id'],
                                                resourceType: 'EVENT',
                                                resourceName: event['name'] ?? 'Event',
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.share_outlined, color: Colors.green),
                                        title: const Text('Invite Listeners', style: TextStyle(color: Colors.white)),
                                        subtitle: const Text('Send room invitation links', style: TextStyle(color: Colors.white70)),
                                        onTap: () {
                                          Navigator.pop(context);
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => InviteFriendsScreen(eventId: event['id']),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('You are a participant in this room.')),
                              );
                            }
                          },
                          child: Container(
                            width: 140,
                            margin: const EdgeInsets.only(right: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.green.withValues(alpha: 0.2),
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
                                  event['name'] ?? "Unnamed Event",
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
  },
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

  Widget _buildEventsSectionHeader(BuildContext context) {
    final state = context.findAncestorStateOfType<HomeScreenState>();
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Events',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            GestureDetector(
              onTap: () {
                if (state != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateEventScreen(),
                    ),
                  ).then((_) {
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    final token = authProvider.currentUser?.accessToken;
                    if (token != null) {
                      state._fetchEvents(token);
                    }
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green, width: 1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: Colors.green, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Create Event',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
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
