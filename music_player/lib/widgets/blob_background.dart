import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Custom painter that creates organic blob shapes with glassmorphism effect
class BlobPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final int seed;

  BlobPainter({
    required this.primaryColor,
    required this.secondaryColor,
    this.seed = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    
    // Create multiple organic blobs
    _drawBlob(
      canvas,
      size,
      Offset(size.width * 0.2, size.height * 0.3),
      size.width * 0.4,
      primaryColor.withOpacity(0.3),
      random,
    );
    
    _drawBlob(
      canvas,
      size,
      Offset(size.width * 0.7, size.height * 0.6),
      size.width * 0.5,
      secondaryColor.withOpacity(0.25),
      random,
    );
    
    _drawBlob(
      canvas,
      size,
      Offset(size.width * 0.5, size.height * 0.8),
      size.width * 0.35,
      primaryColor.withOpacity(0.2),
      random,
    );
  }

  void _drawBlob(
    Canvas canvas,
    Size size,
    Offset center,
    double radius,
    Color color,
    math.Random random,
  ) {
    final path = Path();
    final points = 8; // Number of points for the blob
    final angleStep = (math.pi * 2) / points;

    for (int i = 0; i <= points; i++) {
      final angle = i * angleStep;
      // Add randomness to radius for organic shape
      final radiusVariation = radius * (0.7 + random.nextDouble() * 0.6);
      final x = center.dx + math.cos(angle) * radiusVariation;
      final y = center.dy + math.sin(angle) * radiusVariation;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        // Use quadratic bezier curves for smooth, organic shapes
        final prevAngle = (i - 1) * angleStep;
        final prevRadius = radius * (0.7 + random.nextDouble() * 0.6);
        final prevX = center.dx + math.cos(prevAngle) * prevRadius;
        final prevY = center.dy + math.sin(prevAngle) * prevRadius;
        
        final controlX = (prevX + x) / 2 + (random.nextDouble() - 0.5) * radius * 0.3;
        final controlY = (prevY + y) / 2 + (random.nextDouble() - 0.5) * radius * 0.3;
        
        path.quadraticBezierTo(controlX, controlY, x, y);
      }
    }
    path.close();

    // Add blur effect for glassmorphism
    final paint = Paint()
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Widget wrapper for easy use of blob backgrounds
class BlobBackground extends StatelessWidget {
  final Color primaryColor;
  final Color secondaryColor;
  final Widget child;
  final int seed;

  const BlobBackground({
    super.key,
    required this.primaryColor,
    required this.secondaryColor,
    required this.child,
    this.seed = 0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Stack(
        children: [
          // Blob background layer
          Positioned.fill(
            child: CustomPaint(
              painter: BlobPainter(
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
                seed: seed,
              ),
            ),
          ),
          // Semi-transparent glassmorphism overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withOpacity(0.1),
                    secondaryColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          // Content layer
          child,
        ],
      ),
    );
  }
}
