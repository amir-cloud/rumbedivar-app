import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Branded gradient background with a subtle animated pattern.
class AnimatedBrandBackground extends StatefulWidget {
  const AnimatedBrandBackground({super.key, required this.child});

  final Widget child;

  @override
  State<AnimatedBrandBackground> createState() => _AnimatedBrandBackgroundState();
}

class _AnimatedBrandBackgroundState extends State<AnimatedBrandBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFC30960), Color(0xFFF83389)],
        ),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _BrandPatternPainter(progress: _controller.value),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

class _BrandPatternPainter extends CustomPainter {
  _BrandPatternPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress * 2 * math.pi;
    final paint = Paint()..style = PaintingStyle.fill;

    void blob(Offset center, double radius, Color color, double dx, double dy) {
      final drift = Offset(
        math.sin(t + dx) * 18,
        math.cos(t * 0.8 + dy) * 18,
      );
      paint.color = color;
      canvas.drawCircle(center + drift, radius, paint);
    }

    void ring(Offset center, double radius, Color color, double phase) {
      final drift = Offset(math.cos(t + phase) * 12, math.sin(t + phase) * 12);
      paint
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center + drift, radius, paint);
      paint.style = PaintingStyle.fill;
    }

    // Soft pattern elements (subtle, on-brand).
    blob(Offset(size.width * 0.15, size.height * 0.12), 90,
        Colors.white.withValues(alpha: 0.06), 0.0, 1.0);
    blob(Offset(size.width * 0.88, size.height * 0.18), 70,
        Colors.white.withValues(alpha: 0.05), 1.2, 0.4);
    blob(Offset(size.width * 0.82, size.height * 0.78), 110,
        const Color(0xFFC30960).withValues(alpha: 0.18), 2.1, 1.7);
    blob(Offset(size.width * 0.12, size.height * 0.82), 95,
        const Color(0xFFF83389).withValues(alpha: 0.14), 0.7, 2.6);
    blob(Offset(size.width * 0.5, size.height * 0.45), 130,
        Colors.white.withValues(alpha: 0.03), 1.8, 0.9);

    ring(Offset(size.width * 0.25, size.height * 0.35), 42,
        Colors.white.withValues(alpha: 0.07), 0.3);
    ring(Offset(size.width * 0.78, size.height * 0.55), 34,
        Colors.white.withValues(alpha: 0.06), 1.9);
  }

  @override
  bool shouldRepaint(covariant _BrandPatternPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
