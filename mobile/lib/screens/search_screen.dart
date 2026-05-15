import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../widgets/category_card.dart';
import '../services/audius_service.dart';
import '../models/track_model.dart';
import '../providers/user_profile_provider.dart';
import 'profile/profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final AudiusService _audiusService = AudiusService();
  final TextEditingController _searchController = TextEditingController();
  List<Track> _searchResults = [];
  List<Track> _musicVideos = [];
  bool _isLoading = false;
  bool _isVideosLoading = true;
  bool _hasSearched = false;

  final List<Map<String, dynamic>> _categories = const [
    {
      'title': 'Pop',
      'color': Color(0xFFE8115B),
      'image':
          'https://images.unsplash.com/photo-1520127877998-122c33e8eb38?w=200&h=200&fit=crop',
    },
    {
      'title': 'Hip-Hop',
      'color': Color(0xFFBC5900),
      'image':
          'https://images.unsplash.com/photo-1514525253344-f814d074e015?w=200&h=200&fit=crop',
    },
    {
      'title': 'Rock',
      'color': Color(0xFFE91429),
      'image':
          'https://images.unsplash.com/photo-1498038432885-c6f3f1b912ee?w=200&h=200&fit=crop',
    },
    {
      'title': 'Jazz',
      'color': Color(0xFF7D4B32),
      'image':
          'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=200&h=200&fit=crop',
    },
    {
      'title': 'Electronic',
      'color': Color(0xFF477D95),
      'image':
          'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=200&h=200&fit=crop',
    },
    {
      'title': 'Chill',
      'color': Color(0xFFD84000),
      'image':
          'https://images.unsplash.com/photo-1516280440614-37939bbacd81?w=200&h=200&fit=crop',
    },
    {
      'title': 'Party',
      'color': Color(0xFF8D67AB),
      'image':
          'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=200&h=200&fit=crop',
    },
    {
      'title': 'Workout',
      'color': Color(0xFF777777),
      'image':
          'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=200&h=200&fit=crop',
    },
    {
      'title': 'Focus',
      'color': Color(0xFF503750),
      'image':
          'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=200&h=200&fit=crop',
    },
    {
      'title': 'Mood',
      'color': Color(0xFFE1118C),
      'image':
          'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=200&h=200&fit=crop',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchMusicVideos();
  }

  Future<void> _fetchMusicVideos() async {
    try {
      final videos = await _audiusService.getMusicVideos();
      if (mounted) {
        setState(() {
          _musicVideos = videos;
          _isVideosLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isVideosLoading = false);
      }
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final results = await _audiusService.searchTracks(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Search failed: $e')));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Header ──────────────────────────────────────────────────────────
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
                    'Search',
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

        // ── Search Bar ──────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: TextField(
              controller: _searchController,
              onSubmitted: _performSearch,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'What do you want to listen to?',
                hintStyle: const TextStyle(
                  color: Color(0xFF757575),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF121212),
                  size: 28,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.black),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),

        if (!_hasSearched) ...[
          // ── Music Videos Section ───────────────────────────────────────────
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                'Explore music videos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 160,
              child: _isVideosLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.green),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: _musicVideos.length,
                      itemBuilder: (context, index) {
                        final track = _musicVideos[index];
                        return Container(
                          width: 240,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: NetworkImage(
                                track.imageUrl ??
                                    'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=400&h=225&fit=crop',
                              ),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(
                                Colors.black.withOpacity(0.3),
                                BlendMode.darken,
                              ),
                            ),
                          ),
                          child: Stack(
                            children: [
                              const Center(
                                child: Icon(
                                  Icons.play_circle_fill,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                              Positioned(
                                bottom: 8,
                                left: 8,
                                right: 8,
                                child: Text(
                                  track.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),

          // ── Browse All Title ───────────────────────────────────────────────
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Text(
                'Browse all',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          // ── Categories Grid ─────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.6,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                return CategoryCard(
                  title: _categories[index]['title'],
                  color: _categories[index]['color'],
                  imageUrl: _categories[index]['image'],
                );
              }, childCount: _categories.length),
            ),
          ),
        ] else if (_isLoading) ...[
          const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(color: Colors.green),
            ),
          ),
        ] else if (_searchResults.isEmpty) ...[
          const SliverFillRemaining(
            child: Center(
              child: Text(
                'No results found',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ] else ...[
          // ── Search Results ─────────────────────────────────────────────────
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final track = _searchResults[index];
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: track.imageUrl != null && track.imageUrl!.isNotEmpty
                      ? Image.network(
                          track.imageUrl!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: Colors.grey[900],
                                width: 50,
                                height: 50,
                                child: const Icon(
                                  Icons.music_note,
                                  color: Colors.grey,
                                ),
                              ),
                        )
                      : Container(
                          color: Colors.grey[900],
                          width: 50,
                          height: 50,
                          child: const Icon(
                            Icons.music_note,
                            color: Colors.grey,
                          ),
                        ),
                ),
                title: Text(
                  track.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  track.artistName,
                  style: TextStyle(color: Colors.grey[400]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.more_vert, color: Colors.grey),
                onTap: () {
                  // Handle track selection - maybe play it?
                },
              );
            }, childCount: _searchResults.length),
          ),
        ],
      ],
    );
  }
}
