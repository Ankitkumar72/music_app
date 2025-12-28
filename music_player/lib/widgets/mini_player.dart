import 'package:flutter/material.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          // Album Art Mini
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(color: Colors.grey, width: 45, height: 45),
          ),
          const SizedBox(width: 12),
          // Info
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Starboy", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  "The Weeknd • Daft Punk",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          // Controls
          IconButton(onPressed: () {}, icon: const Icon(Icons.skip_previous)),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.play_circle_fill,
              size: 40,
              color: Color(0xFFFFC107),
            ),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.skip_next)),
        ],
      ),
    );
  }
}
