import 'package:flutter/material.dart';

class PlaylistCard extends StatelessWidget {
  final String name;
  final int songCount;
  final bool isLiked;
  final List<Color> gradientColors;
  final String? iconType;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const PlaylistCard({
    super.key,
    required this.name,
    required this.songCount,
    required this.isLiked,
    required this.gradientColors,
    this.iconType,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors.first.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(child: _buildIcon()),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (isLiked)
                const Icon(Icons.favorite, size: 12, color: Color(0xFFE91E63)),
              if (isLiked) const SizedBox(width: 4),
              Text(
                "$songCount songs",
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    if (isLiked) return const Icon(Icons.favorite, size: 60, color: Colors.white);

    IconData iconData;
    switch (iconType) {
      case 'car': iconData = Icons.directions_car; break;
      case 'meditation': iconData = Icons.self_improvement; break;
      case 'neon': iconData = Icons.fitness_center; break;
      case 'citylight': iconData = Icons.nights_stay; break;
      case 'abstract': iconData = Icons.album; break;
      case 'coffee': iconData = Icons.coffee; break;
      case 'vinyl': iconData = Icons.audiotrack; break;
      default: iconData = Icons.music_note;
    }
    return Icon(iconData, size: 60, color: Colors.white);
  }
}