import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/user_profile_provider.dart';
import '../widgets/library_list_item.dart';
import 'package:provider/provider.dart';
import 'profile/profile_screen.dart';
import '../screens/playlist_detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  final VoidCallback? onPlusTap;
  const LibraryScreen({super.key, this.onPlusTap});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool _isSearching = false;
  bool _isGridView = false;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      Provider.of<PlaylistProvider>(context, listen: false).loadPlaylists(auth.currentUser);
    });
  }

  List<Map<String, dynamic>> _getFilteredItems(BuildContext context) {
    final playlistProvider = Provider.of<PlaylistProvider>(context);
    List<Map<String, dynamic>> items = playlistProvider.playlists.map((p) {
      return {
        'id': p.id,
        'title': p.title.isEmpty ? 'Untitled Playlist' : p.title,
        'subtitle': 'Playlist • ${p.creatorName.isEmpty ? 'You' : p.creatorName}',
        'image': p.imageUrl ?? 'https://images.unsplash.com/photo-1514525253344-f814d074e015?w=200&h=200&fit=crop',
        'isCircular': false,
        'playlist': p,
      };
    }).toList();

    if (_searchQuery.isEmpty) return items;
    return items.where((item) {
      final title = item['title'].toString().toLowerCase();
      return title.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final userName = auth.currentUser?.fullName ?? 'User';

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
                  child: _isSearching
                      ? _buildSearchBar()
                      : _buildDefaultHeader(userName),
                ),
              ),
            ),

            // ── Filter Chips (Only show when not searching or as secondary) ─────
            SliverToBoxAdapter(
              child: AnimatedOpacity(
                opacity: _isSearching ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: _isSearching
                    ? const SizedBox.shrink()
                    : SizedBox(
                        height: 60,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          children: const [
                            FilterChip(label: 'Playlists'),
                            FilterChip(label: 'Artists'),
                            FilterChip(label: 'Albums'),
                            FilterChip(label: 'Podcasts & Shows'),
                          ],
                        ),
                      ),
              ),
            ),

            // ── Sorting & View Header ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () {
                        // Spotify simple sort toggle logic
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Sort options: Recently played, Recently added, Alphabetical',
                            ),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.import_export_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Recently played',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () =>
                          setState(() => _isGridView = !_isGridView),
                      icon: Icon(
                        _isGridView
                            ? Icons.list_rounded
                            : Icons.grid_view_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),

            // ── Library List/Grid ──────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              sliver: _isGridView
                  ? SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.8,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final items = _getFilteredItems(context);
                        final item = items[index];
                        return _buildGridItem(item);
                      }, childCount: _getFilteredItems(context).length),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final items = _getFilteredItems(context);
                        final item = items[index];
                        return LibraryListItem(
                          title: item['title'],
                          subtitle: item['subtitle'],
                          imageUrl: item['image'],
                          isCircular: item['isCircular'],
                          onTap: () => _openPlaylistDetail(context, item),
                        );
                      }, childCount: _getFilteredItems(context).length),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGridItem(Map<String, dynamic> item) {
    return InkWell(
      onTap: () => _openPlaylistDetail(context, item),
      borderRadius: BorderRadius.circular(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(item['isCircular'] ? 100 : 4),
                image: DecorationImage(
                  image: NetworkImage(item['image']),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item['title'],
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            item['subtitle'],
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _openPlaylistDetail(BuildContext context, Map<String, dynamic> item) {
    final playlist = item['playlist'];
    if (playlist == null) return;

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
  }

  Widget _buildDefaultHeader(String userName) {
    return Row(
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
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
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
          'Your Library',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => setState(() => _isSearching = true),
          icon: const Icon(Icons.search_rounded, color: Colors.white, size: 28),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 16),
        IconButton(
          onPressed: widget.onPlusTap,
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(4),
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: const InputDecoration(
                hintText: 'Find in Your Library',
                hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Colors.white54,
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _isSearching = false;
              _searchQuery = "";
              _searchController.clear();
            });
          },
          child: const Text(
            'Cancel',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

}

class FilterChip extends StatelessWidget {
  final String label;

  const FilterChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
