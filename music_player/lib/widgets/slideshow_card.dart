import 'dart:async';
import 'package:flutter/material.dart';

class SlideshowCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<String> imagePaths;
  final VoidCallback onTap;
  final VoidCallback onPlay;

  const SlideshowCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imagePaths,
    required this.onTap,
    required this.onPlay,
  });

  @override
  State<SlideshowCard> createState() => _SlideshowCardState();
}

class _SlideshowCardState extends State<SlideshowCard> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.imagePaths.length > 1) {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(SlideshowCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imagePaths != oldWidget.imagePaths) {
      _timer?.cancel();
      if (widget.imagePaths.length > 1) {
        _startTimer();
      }
    }
  }

  void _startTimer() {
    _timer?.cancel(); // Safety cancel
    _timer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (!mounted) return;
      if (_pageController.hasClients) {
        if (_currentPage < widget.imagePaths.length - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              offset: const Offset(0, 8),
              blurRadius: 12,
            ),
          ],
        ),
        // Move clip to child to avoid shadow clipping issues if they arise, 
        // though Container clip usually clips shadow too if not careful.
        // Better structure: Container(shadow) -> ClipRRect -> Stack
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Background Slideshow
              if (widget.imagePaths.isNotEmpty)
                PageView.builder(
                  controller: _pageController,
                  itemCount: widget.imagePaths.length,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return Image.asset(
                      widget.imagePaths[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[850],
                          child: const Center(
                            child: Icon(Icons.broken_image, color: Colors.white24, size: 40),
                          ),
                        );
                      },
                    );
                  },
                )
              else
                Container(color: Colors.grey[900]),

            // Gradient Overlay for Readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.8),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // Play Button
                  GestureDetector(
                    onTap: widget.onPlay,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withOpacity(0.4),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.play_arrow, color: Colors.black, size: 28),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Text Content
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 10,
                          color: Colors.black,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.subtitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      shadows: [
                        Shadow(
                          blurRadius: 8,
                          color: Colors.black,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }
}
