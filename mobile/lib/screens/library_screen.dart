import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/library_list_item.dart';
import 'package:provider/provider.dart';
import 'home_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool _isSearching = false;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _allLibraryItems = const [
    {
      'title': 'Liked Songs',
      'subtitle': 'Playlist • 124 songs',
      'image': 'https://images.unsplash.com/photo-1514525253344-f814d074e015?w=200&h=200&fit=crop',
      'isCircular': false
    },
    {
      'title': 'The Weeknd',
      'subtitle': 'Artist',
      'image': 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=200&h=200&fit=crop',
      'isCircular': true
    },
    {
      'title': 'Study Beats',
      'subtitle': 'Playlist • MusicRoom',
      'image': 'https://images.unsplash.com/photo-1516280440614-37939bbacd81?w=200&h=200&fit=crop',
      'isCircular': false
    },
    {
      'title': 'Arctic Monkeys',
      'subtitle': 'Artist',
      'image': 'https://images.unsplash.com/photo-1498038432885-c6f3f1b912ee?w=200&h=200&fit=crop',
      'isCircular': true
    },
    {
      'title': 'Summer 2026',
      'subtitle': 'Playlist • You',
      'image': 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=200&h=200&fit=crop',
      'isCircular': false
    },
    {
      'title': 'Daft Punk',
      'subtitle': 'Artist',
      'image': 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=200&h=200&fit=crop',
      'isCircular': true
    },
    {
      'title': 'Late Night Jazz',
      'subtitle': 'Playlist • MusicRoom',
      'image': 'https://images.unsplash.com/photo-1514525253344-f814d074e015?w=200&h=200&fit=crop',
      'isCircular': false
    },
  ];

  List<Map<String, dynamic>> get _filteredItems {
    if (_searchQuery.isEmpty) return _allLibraryItems;
    return _allLibraryItems.where((item) {
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
                  child: _isSearching ? _buildSearchBar() : _buildDefaultHeader(userName),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.swap_vert_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Recently played',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.grid_view_rounded, color: Colors.white, size: 20),
                  ],
                ),
              ),
            ),

            // ── Library List ───────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = _filteredItems[index];
                    return LibraryListItem(
                      title: item['title'],
                      subtitle: item['subtitle'],
                      imageUrl: item['image'],
                      isCircular: item['isCircular'],
                    );
                  },
                  childCount: _filteredItems.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDefaultHeader(String userName) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppTheme.accent,
          child: Text(
            _getInitials(userName),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
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
          onPressed: () {
            context.findAncestorStateOfType<HomeScreenState>()?.setSelectedIndex(3);
          },
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
                prefixIcon: Icon(Icons.search_rounded, color: Colors.white54, size: 20),
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
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
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
