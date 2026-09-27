import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/theme_service.dart';

/// A live ambient background with slow-drifting soft gradient orbs and micro-particles.
/// Rendered behind application content with pointer interactions completely disabled.
class LiveAnimatedBackground extends StatefulWidget {
  final Widget? child;
  const LiveAnimatedBackground({super.key, this.child});

  @override
  State<LiveAnimatedBackground> createState() => _LiveAnimatedBackgroundState();
}

class _LiveAnimatedBackgroundState extends State<LiveAnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.instance.isDarkMode(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Solid base background
        Container(
          color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        ),
        // Live ambient painter
        RepaintBoundary(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: _AmbientBackgroundPainter(
                    progress: _controller.value,
                    isDark: isDark,
                  ),
                );
              },
            ),
          ),
        ),
        // Foreground Content
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _AmbientBackgroundPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  _AmbientBackgroundPainter({
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final t = progress * 2 * math.pi;

    // Orb 1: Royal Blue / Violet - Top Left quadrant moving cyclically
    final o1X = size.width * (0.22 + 0.12 * math.sin(t));
    final o1Y = size.height * (0.25 + 0.10 * math.cos(t));
    final o1Radius = size.width * 0.45;
    final o1Color = isDark
        ? const Color(0xFF7C3AED).withValues(alpha: 0.12)
        : const Color(0xFF2563EB).withValues(alpha: 0.08);

    final p1 = Paint()
      ..shader = RadialGradient(
        colors: [o1Color, o1Color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromCircle(center: Offset(o1X, o1Y), radius: o1Radius));
    canvas.drawCircle(Offset(o1X, o1Y), o1Radius, p1);

    // Orb 2: Cyber Cyan - Bottom Right quadrant
    final o2X = size.width * (0.80 - 0.14 * math.cos(t * 0.8));
    final o2Y = size.height * (0.75 - 0.12 * math.sin(t * 0.8));
    final o2Radius = size.width * 0.48;
    final o2Color = isDark
        ? const Color(0xFF06B6D4).withValues(alpha: 0.10)
        : const Color(0xFF06B6D4).withValues(alpha: 0.07);

    final p2 = Paint()
      ..shader = RadialGradient(
        colors: [o2Color, o2Color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromCircle(center: Offset(o2X, o2Y), radius: o2Radius));
    canvas.drawCircle(Offset(o2X, o2Y), o2Radius, p2);

    // Orb 3: Violet / Lilac - Top Right quadrant
    final o3X = size.width * (0.75 + 0.10 * math.sin(t * 1.2));
    final o3Y = size.height * (0.20 + 0.08 * math.cos(t * 1.2));
    final o3Radius = size.width * 0.38;
    final o3Color = isDark
        ? const Color(0xFF8B5CF6).withValues(alpha: 0.09)
        : const Color(0xFF7C3AED).withValues(alpha: 0.06);

    final p3 = Paint()
      ..shader = RadialGradient(
        colors: [o3Color, o3Color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromCircle(center: Offset(o3X, o3Y), radius: o3Radius));
    canvas.drawCircle(Offset(o3X, o3Y), o3Radius, p3);

    // Orb 4: Warm Sunset Glow - Center Bottom Left
    final o4X = size.width * (0.15 + 0.08 * math.cos(t * 0.6));
    final o4Y = size.height * (0.85 + 0.06 * math.sin(t * 0.6));
    final o4Radius = size.width * 0.40;
    final o4Color = isDark
        ? const Color(0xFFF59E0B).withValues(alpha: 0.06)
        : const Color(0xFF38BDF8).withValues(alpha: 0.05);

    final p4 = Paint()
      ..shader = RadialGradient(
        colors: [o4Color, o4Color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromCircle(center: Offset(o4X, o4Y), radius: o4Radius));
    canvas.drawCircle(Offset(o4X, o4Y), o4Radius, p4);

    // Subtle micro-particles
    final particlePaint = Paint()..style = PaintingStyle.fill;
    const particleCount = 18;
    for (int i = 0; i < particleCount; i++) {
      final pProgress = (progress + (i / particleCount)) % 1.0;
      final px = (math.sin(i * 99.0) * 0.5 + 0.5) * size.width +
          math.sin(pProgress * 2 * math.pi + i) * 20;
      final py = (1.0 - pProgress) * size.height;
      final radius = 1.2 + (i % 3) * 0.8;
      final alpha = math.sin(pProgress * math.pi) * (isDark ? 0.22 : 0.16);

      particlePaint.color = (i % 2 == 0 ? AppColors.primary : AppColors.secondary)
          .withValues(alpha: alpha);
      canvas.drawCircle(Offset(px, py), radius, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}
