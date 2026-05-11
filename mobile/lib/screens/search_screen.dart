import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/category_card.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  final List<Map<String, dynamic>> _categories = const [
    {'title': 'Pop', 'color': Color(0xFFE8115B), 'image': 'https://images.unsplash.com/photo-1520127877998-122c33e8eb38?w=200&h=200&fit=crop'},
    {'title': 'Hip-Hop', 'color': Color(0xFFBC5900), 'image': 'https://images.unsplash.com/photo-1514525253344-f814d074e015?w=200&h=200&fit=crop'},
    {'title': 'Rock', 'color': Color(0xFFE91429), 'image': 'https://images.unsplash.com/photo-1498038432885-c6f3f1b912ee?w=200&h=200&fit=crop'},
    {'title': 'Jazz', 'color': Color(0xFF7D4B32), 'image': 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=200&h=200&fit=crop'},
    {'title': 'Electronic', 'color': Color(0xFF477D95), 'image': 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=200&h=200&fit=crop'},
    {'title': 'Chill', 'color': Color(0xFFD84000), 'image': 'https://images.unsplash.com/photo-1516280440614-37939bbacd81?w=200&h=200&fit=crop'},
    {'title': 'Party', 'color': Color(0xFF8D67AB), 'image': 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=200&h=200&fit=crop'},
    {'title': 'Workout', 'color': Color(0xFF777777), 'image': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=200&h=200&fit=crop'},
    {'title': 'Focus', 'color': Color(0xFF503750), 'image': 'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=200&h=200&fit=crop'},
    {'title': 'Mood', 'color': Color(0xFFE1118C), 'image': 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=200&h=200&fit=crop'},
  ];

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
          toolbarHeight: 120,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              padding: const EdgeInsets.fromLTRB(16, 60, 16, 0),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
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
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search_rounded, color: Color(0xFF121212), size: 28),
                  SizedBox(width: 12),
                  Text(
                    'What do you want to listen to?',
                    style: TextStyle(
                      color: Color(0xFF757575),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
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
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final category = _categories[index];
                return CategoryCard(
                  title: category['title'],
                  color: category['color'],
                  imageUrl: category['image'],
                );
              },
              childCount: _categories.length,
            ),
          ),
        ),
      ],
    );
  }
}
