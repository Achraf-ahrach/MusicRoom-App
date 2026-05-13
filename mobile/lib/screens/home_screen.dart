import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/section_header.dart';
import '../widgets/playlist_grid_card.dart';
import '../widgets/music_room_card.dart';
import '../widgets/music_card.dart';
import 'profile/profile_screen.dart';
import '../screens/search_screen.dart';
import '../screens/library_screen.dart';
import '../screens/create_room_screen.dart';
import '../widgets/create_menu_bottom_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isCreateMenuOpen = false;

  void toggleCreateMenu() {
    setState(() {
      _isCreateMenuOpen = !_isCreateMenuOpen;
    });
  }

  final List<Map<String, String>> _recentPlaylists = [
    {'title': 'Chill Lofi Beats', 'image': 'https://images.unsplash.com/photo-1516280440614-37939bbacd81?w=200&h=200&fit=crop'},
    {'title': '80s Rock Classics', 'image': 'https://images.unsplash.com/photo-1498038432885-c6f3f1b912ee?w=200&h=200&fit=crop'},
    {'title': 'Gym Motivation', 'image': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=200&h=200&fit=crop'},
    {'title': 'Top Hits 2026', 'image': 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=200&h=200&fit=crop'},
    {'title': 'Jazz & Blues', 'image': 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=200&h=200&fit=crop'},
    {'title': 'Podcast: Tech', 'image': 'https://images.unsplash.com/photo-1478737270239-2f02b77fc618?w=200&h=200&fit=crop'},
  ];

  final List<Map<String, dynamic>> _activeRooms = [
    {'title': 'Morning Coffee', 'image': 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=400&h=400&fit=crop', 'isLive': true},
    {'title': 'Study Session', 'image': 'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=400&h=400&fit=crop', 'isLive': true},
    {'title': 'Late Night Jazz', 'image': 'https://images.unsplash.com/photo-1514525253344-f814d074e015?w=400&h=400&fit=crop', 'isLive': true},
  ];

  late final List<Widget> _screens = [
    const _HomeContent(),
    const SearchScreen(),
    const LibraryScreen(),
    const CreateRoomScreen(),
  ];

  void setSelectedIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
          // Dimmed background
          AnimatedOpacity(
            opacity: _isCreateMenuOpen ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: _isCreateMenuOpen
                ? GestureDetector(
                    onTap: toggleCreateMenu,
                    child: Container(
                      color: Colors.black54,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          // Menu Overlay
          AnimatedSlide(
            offset: _isCreateMenuOpen ? Offset.zero : const Offset(0, 1),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _isCreateMenuOpen 
                ? CreateMenuOverlay(onClose: toggleCreateMenu)
                : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Theme(
      data: ThemeData(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 3) {
            toggleCreateMenu();
          } else {
            setState(() {
              _selectedIndex = index;
              _isCreateMenuOpen = false;
            });
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black.withValues(alpha: 0.95),
        selectedItemColor: Colors.white,
        unselectedItemColor: AppTheme.textMuted,
        selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
        unselectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
        items: [
          const BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.home_filled, size: 28),
            ),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.search_rounded, size: 28),
            ),
            label: 'Search',
          ),
          const BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.library_music_rounded, size: 28),
            ),
            label: 'Your Library',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Icon(
                _isCreateMenuOpen ? Icons.close_rounded : Icons.add_box_rounded,
                size: 28,
              ),
            ),
            label: 'Create',
          ),
        ],
      ),
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

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<HomeScreenState>()!;
    
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final userName = auth.currentUser?.fullName ?? 'User';

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Top Header ──────────────────────────────────────────────────
            SliverAppBar(
              floating: true,
              pinned: false,
              backgroundColor: AppTheme.background,
              expandedHeight: 80,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.bottomLeft,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
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
                          backgroundColor: AppTheme.accent,
                          child: Text(
                            state._getInitials(userName),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Recent Items Grid ──────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3.2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = state._recentPlaylists[index];
                    return PlaylistGridCard(
                      title: item['title']!,
                      imageUrl: item['image'],
                    );
                  },
                  childCount: state._recentPlaylists.length,
                ),
              ),
            ),

            // ── Active Music Rooms ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'Active Music Rooms'),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: state._activeRooms.length,
                        itemBuilder: (context, index) {
                          final room = state._activeRooms[index];
                          return MusicRoomCard(
                            title: room['title'],
                            imageUrl: room['image'],
                            isLive: room['isLive'],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Made for you ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'Made for you'),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: 4,
                        itemBuilder: (context, index) {
                          return MusicCard(
                            title: 'Mix ${index + 1}',
                            subtitle: 'Based on your recent listening',
                            imageUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=400&h=400&fit=crop&q=80&sig=$index',
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
