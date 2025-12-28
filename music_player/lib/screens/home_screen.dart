import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 1. Custom App Bar with Profile and Notifications
          SliverAppBar(
            floating: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundImage: NetworkImage(
                  'https://placeholder.com/user_avatar.png',
                ),
              ),
            ),
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Good Evening",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  "Alex",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none),
              ),
            ],
          ),

          // 2. Filter Category Chips (For You, Chill, Workout)
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildCategoryChip(
                    "✨ For You",
                    const Color(0xFFFFD700),
                    Colors.black,
                    true,
                  ),
                  _buildCategoryChip(
                    "🌙 Chill",
                    Colors.white12,
                    Colors.white,
                    false,
                  ),
                  _buildCategoryChip(
                    "🏋️ Workout",
                    Colors.white12,
                    Colors.white,
                    false,
                  ),
                  _buildCategoryChip(
                    "⚙️ Mood",
                    Colors.white12,
                    Colors.white,
                    false,
                  ),
                ],
              ),
            ),
          ),

          // 3. "Your Daily Mix" Section Header
          _buildSectionHeader("✨ Your Daily Mix"),

          // 4. Large Horizontal Cards (Daily Mix 1, Discovery)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 350,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildLargeDailyMixCard(
                    "Daily Mix 1",
                    "The Weeknd, Daft Punk, Tame Impala & more",
                    const Color(0xFF5D4037),
                  ),
                  _buildLargeDailyMixCard(
                    "Discovery",
                    "New music picked just for you",
                    const Color(0xFF455A64),
                  ),
                ],
              ),
            ),
          ),

          // 5. "Jump Back In" Section Header
          _buildSectionHeader("Jump Back In"),

          // 6. Smaller Square Cards
          SliverToBoxAdapter(
            child: SizedBox(
              height: 180,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildSmallRecentCard(
                    "Neon Lights",
                    "https://placeholder.com/album1.png",
                  ),
                  _buildSmallRecentCard(
                    "Abstract Flow",
                    "https://placeholder.com/album2.png",
                  ),
                  _buildSmallRecentCard(
                    "Rock Classics",
                    "https://placeholder.com/album3.png",
                  ),
                ],
              ),
            ),
          ),

          // 7. Extra Padding for the Mini Player at the bottom
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // Helper: Section Headers
  Widget _buildSectionHeader(String title) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      sliver: SliverToBoxAdapter(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Text(
              "SEE ALL",
              style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper: Category Chips
  Widget _buildCategoryChip(
    String label,
    Color bgColor,
    Color txtColor,
    bool isActive,
  ) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isActive
            ? [BoxShadow(color: bgColor.withValues(alpha: 0.3), blurRadius: 10)]
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(color: txtColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Helper: Large Mix Cards
  Widget _buildLargeDailyMixCard(String title, String subtitle, Color color) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Colors.yellow,
            child: const Icon(Icons.play_arrow, color: Colors.black),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  // Helper: Small Square Cards
  Widget _buildSmallRecentCard(String title, String imageUrl) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              color: Colors.white12,
              height: 140,
              width: 140,
            ), // Placeholder
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
