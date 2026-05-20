import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'library_screen.dart';
import '../widgets/create_menu_bottom_sheet.dart';
import '../widgets/audio_player_overlay.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isCreateMenuOpen = false;

  void _onItemTapped(int index) {
    // Automatically minimize player if it is maximized when clicking any tab
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    if (audioProvider.isPlayerMaximized) {
      audioProvider.minimizePlayer();
    }

    if (index == 3) {
      setState(() {
        _isCreateMenuOpen = !_isCreateMenuOpen;
      });
    } else {
      setState(() {
        _selectedIndex = index;
        _isCreateMenuOpen = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild screens with the correct callback every time state changes
    final screens = [
      const HomeScreen(),
      const SearchScreen(),
      LibraryScreen(
        onPlusTap: () {
          setState(() {
            _isCreateMenuOpen = !_isCreateMenuOpen;
          });
        },
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          IndexedStack(index: _selectedIndex, children: screens),
          const AudioPlayerOverlay(),
          if (_isCreateMenuOpen)
            GestureDetector(
              onTap: () => setState(() => _isCreateMenuOpen = false),
              child: Container(color: Colors.black.withOpacity(0.5)),
            ),
          if (_isCreateMenuOpen)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: CreateMenuOverlay(
                onClose: () => setState(() => _isCreateMenuOpen = false),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Selector<AudioProvider, bool>(
        selector: (context, provider) => provider.isPlayerMaximized,
        builder: (context, isMaximized, child) {
          if (isMaximized) return const SizedBox.shrink();
          return BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.black,
            selectedItemColor: Colors.green,
            unselectedItemColor: Colors.grey,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.search_outlined),
                activeIcon: Icon(Icons.search),
                label: 'Search',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.library_music_outlined),
                activeIcon: Icon(Icons.library_music),
                label: 'Library',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  _isCreateMenuOpen ? Icons.close : Icons.add_box_outlined,
                ),
                activeIcon: Icon(_isCreateMenuOpen ? Icons.close : Icons.add_box),
                label: _isCreateMenuOpen ? 'Close' : 'Create',
              ),
            ],
          );
        },
      ),
    );
  }
}
