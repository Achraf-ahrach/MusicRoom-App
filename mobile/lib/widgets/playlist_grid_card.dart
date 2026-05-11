import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class PlaylistGridCard extends StatelessWidget {
  final String title;
  final String? imageUrl;

  const PlaylistGridCard({
    super.key,
    required this.title,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          // Image
          AspectRatio(
            aspectRatio: 1,
            child: imageUrl != null
                ? Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, _, __) => _buildPlaceholder(),
                  )
                : _buildPlaceholder(),
          ),
          const SizedBox(width: 8),
          // Title
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppTheme.surfaceLight,
      child: const Center(
        child: Icon(
          Icons.music_note_rounded,
          color: AppTheme.textMuted,
          size: 20,
        ),
      ),
    );
  }
}
