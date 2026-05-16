import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class LibraryListItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final bool isCircular;
  final VoidCallback? onTap;

  const LibraryListItem({
    super.key,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.isCircular = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            // Image
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: isCircular ? null : BorderRadius.circular(4),
                color: AppTheme.surface,
              ),
              clipBehavior: Clip.antiAlias,
              child: imageUrl != null
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, _, __) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
            const SizedBox(width: 12),
            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(
        isCircular ? Icons.person_rounded : Icons.music_note_rounded,
        color: Colors.white24,
        size: 32,
      ),
    );
  }
}
