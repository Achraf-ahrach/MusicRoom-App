import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/playlist_model.dart';
import '../providers/auth_provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/user_profile_provider.dart';
import '../services/playlist_service.dart';
import '../widgets/library_list_item.dart';
import 'package:provider/provider.dart';
import 'profile/profile_screen.dart';
import '../screens/playlist_detail_screen.dart';

enum _LibraryFilter { all, myPlaylists, saved }

class LibraryScreen extends StatefulWidget {
  final VoidCallback? onPlusTap;
  const LibraryScreen({super.key, this.onPlusTap});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool _isSearching = false;
  bool _isGridView = false;
  String _searchQuery = '';
  _LibraryFilter _filter = _LibraryFilter.all;
  final TextEditingController _searchController = TextEditingController();

  List<Playlist> _savedPlaylists = [];
  bool _isLoadingSaved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      Provider.of<PlaylistProvider>(context, listen: false)
          .loadPlaylists(auth.currentUser);
      _loadSavedPlaylists();
    });
  }

  Future<void> _loadSavedPlaylists() async {
    final token =
        Provider.of<AuthProvider>(context, listen: false).currentUser?.accessToken;
    if (token == null || token.isEmpty) return;
    setState(() => _isLoadingSaved = true);
    try {
      final saved = await PlaylistService().getSavedPlaylists(token);
      if (mounted) setState(() => _savedPlaylists = saved);
    } catch (e) {
      debugPrint('Failed to load saved playlists: $e');
    } finally {
      if (mounted) setState(() => _isLoadingSaved = false);
    }
  }

  List<Map<String, dynamic>> _getFilteredItems(BuildContext context) {
    final playlistProvider = Provider.of<PlaylistProvider>(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = auth.currentUser?.id ?? '';

    // My Playlists: playlists owned by current user
    final myPlaylists = playlistProvider.playlists
        .where((p) => p.ownerId == currentUserId)
        .map((p) => _toItem(p, isSaved: false))
        .toList();

    // Saved Playlists: exclude ones already owned by me (no duplicates)
    final savedItems = _savedPlaylists
        .where((p) => p.ownerId != currentUserId)
        .map((p) => _toItem(p, isSaved: true))
        .toList();

    List<Map<String, dynamic>> combined;
    switch (_filter) {
      case _LibraryFilter.myPlaylists:
        combined = myPlaylists;
        break;
      case _LibraryFilter.saved:
        combined = savedItems;
        break;
      case _LibraryFilter.all:
        combined = [...myPlaylists, ...savedItems];
        break;
    }

    if (_searchQuery.isEmpty) return combined;
    return combined
        .where((item) =>
            item['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  Map<String, dynamic> _toItem(Playlist p, {required bool isSaved}) {
    return {
      'id': p.id,
      'title': p.title.isEmpty ? 'Untitled Playlist' : p.title,
      'subtitle': isSaved
          ? 'Saved • ${p.creatorName.isEmpty ? 'Unknown' : p.creatorName}'
          : 'Playlist • ${p.creatorName.isEmpty ? 'You' : p.creatorName}',
      'image': p.imageUrl ??
          'https://images.unsplash.com/photo-1514525253344-f814d074e015?w=200&h=200&fit=crop',
      'isCircular': false,
      'playlist': p,
      'isPrivate': p.visibility == 'private',
      'isSaved': isSaved,
    };
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

        return RefreshIndicator(
          color: AppTheme.accent,
          backgroundColor: AppTheme.surface,
          onRefresh: () async {
            Provider.of<PlaylistProvider>(context, listen: false)
                .loadPlaylists(auth.currentUser);
            await _loadSavedPlaylists();
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Header ─────────────────────────────────────────────────────
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

              // ── Filter Chips ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      _chip('All', _LibraryFilter.all),
                      const SizedBox(width: 8),
                      _chip('Playlists', _LibraryFilter.myPlaylists),
                      const SizedBox(width: 8),
                      _chip('Saved', _LibraryFilter.saved),
                    ],
                  ),
                ),
              ),

              // ── Sort & View Toggle ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.import_export_rounded,
                              color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Recently added',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
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

              // ── Loading ─────────────────────────────────────────────────────
              if (_isLoadingSaved)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                        child: SizedBox(
                            height: 2,
                            child: LinearProgressIndicator(color: AppTheme.accent))),
                  ),
                ),

              // ── Empty State ─────────────────────────────────────────────────
              Builder(builder: (context) {
                final items = _getFilteredItems(context);
                if (items.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.library_music_outlined,
                              color: Colors.white24, size: 64),
                          const SizedBox(height: 16),
                          Text(
                            _filter == _LibraryFilter.saved
                                ? 'No saved playlists yet'
                                : 'No playlists yet',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _filter == _LibraryFilter.saved
                                ? 'Save playlists from their detail page'
                                : 'Create your first playlist with +',
                            style: const TextStyle(
                                color: Colors.white30, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }),

              // ── Library List / Grid ─────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: _isGridView
                    ? SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.8,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final items = _getFilteredItems(context);
                            return _buildGridItem(items[index]);
                          },
                          childCount: _getFilteredItems(context).length,
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final items = _getFilteredItems(context);
                            final item = items[index];
                            return LibraryListItem(
                              title: item['title'],
                              subtitle: item['subtitle'],
                              imageUrl: item['image'],
                              isCircular: item['isCircular'],
                              isPrivate: item['isPrivate'] ?? false,
                              onTap: () => _openPlaylistDetail(context, item),
                            );
                          },
                          childCount: _getFilteredItems(context).length,
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _chip(String label, _LibraryFilter value) {
    final selected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? Colors.white : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
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
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    image: DecorationImage(
                      image: NetworkImage(item['image']),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (item['isSaved'] == true)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Saved',
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                if (item['isPrivate'] == true)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_outline_rounded,
                          color: Colors.redAccent, size: 14),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(item['title'],
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text(item['subtitle'],
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
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
    ).then((_) => _loadSavedPlaylists()); // Refresh saved state on return
  }

  Widget _buildDefaultHeader(String userName) {
    return Row(
      children: [
        Consumer<UserProfileProvider>(
          builder: (context, profileProvider, child) {
            final profile = profileProvider.profile;
            final avatarUrl = profile?.avatarUrl;
            return GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen())),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey[800],
                backgroundImage: avatarUrl != null &&
                        avatarUrl.isNotEmpty &&
                        !avatarUrl.contains('photo-1535713875002-d1d0cf377fde')
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null ||
                        avatarUrl.isEmpty ||
                        avatarUrl.contains('photo-1535713875002-d1d0cf377fde')
                    ? const Icon(Icons.person, size: 18, color: Colors.white70)
                    : null,
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
                prefixIcon: Icon(Icons.search_rounded,
                    color: Colors.white54, size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
        TextButton(
          onPressed: () => setState(() {
            _isSearching = false;
            _searchQuery = '';
            _searchController.clear();
          }),
          child: const Text('Cancel',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
