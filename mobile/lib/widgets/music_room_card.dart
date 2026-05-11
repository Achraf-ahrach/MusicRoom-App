import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class MusicRoomCard extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final bool isLive;

  const MusicRoomCard({
    super.key,
    required this.title,
    this.imageUrl,
    this.isLive = false,
  });

  @override
  Widget build(BuildContext context) {
    const double size = 160;
    return Container(
      width: size,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover Art
          Stack(
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, _, __) => _buildPlaceholder(size),
                        )
                      : _buildPlaceholder(size),
                ),
              ),
              if (isLive)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF2D55),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: Colors.white, size: 8),
                        SizedBox(width: 4),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(double size) {
    return Container(
      color: AppTheme.surfaceLight,
      child: Center(
        child: Icon(
          Icons.headset_rounded,
          color: AppTheme.textMuted,
          size: size * 0.3,
        ),
      ),
    );
  }
}
