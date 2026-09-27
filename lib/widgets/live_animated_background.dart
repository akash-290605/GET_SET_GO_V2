import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/theme_service.dart';

/// A rich, lively ambient animated background with drifting luminous gradient orbs,
/// subtle harmonic motion, and floating luminous micro-particles.
/// Always rendered behind UI layers with pointer events disabled.
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
      duration: const Duration(seconds: 18),
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
        // Solid base canvas
        Container(
          color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        ),
        // Live animated gradient & particle canvas
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
        // Foreground UI Content
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

    // 1. Orb 1: Royal Blue / Electric Indigo - Top Left to Center
    final o1X = size.width * (0.22 + 0.16 * math.sin(t));
    final o1Y = size.height * (0.24 + 0.14 * math.cos(t));
    final o1Radius = size.width * 0.48;
    final o1Color = isDark
        ? const Color(0xFF2563EB).withValues(alpha: 0.22)
        : const Color(0xFF3B82F6).withValues(alpha: 0.18);

    final p1 = Paint()
      ..shader = RadialGradient(
        colors: [o1Color, o1Color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromCircle(center: Offset(o1X, o1Y), radius: o1Radius));
    canvas.drawCircle(Offset(o1X, o1Y), o1Radius, p1);

    // 2. Orb 2: Vibrant Cyan / Teal - Bottom Right
    final o2X = size.width * (0.82 - 0.16 * math.cos(t * 0.9));
    final o2Y = size.height * (0.76 - 0.14 * math.sin(t * 0.9));
    final o2Radius = size.width * 0.52;
    final o2Color = isDark
        ? const Color(0xFF06B6D4).withValues(alpha: 0.20)
        : const Color(0xFF06B6D4).withValues(alpha: 0.16);

    final p2 = Paint()
      ..shader = RadialGradient(
        colors: [o2Color, o2Color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromCircle(center: Offset(o2X, o2Y), radius: o2Radius));
    canvas.drawCircle(Offset(o2X, o2Y), o2Radius, p2);

    // 3. Orb 3: Radiant Violet / Purple - Top Right
    final o3X = size.width * (0.78 + 0.14 * math.sin(t * 1.1));
    final o3Y = size.height * (0.22 + 0.12 * math.cos(t * 1.1));
    final o3Radius = size.width * 0.44;
    final o3Color = isDark
        ? const Color(0xFF7C3AED).withValues(alpha: 0.18)
        : const Color(0xFF8B5CF6).withValues(alpha: 0.15);

    final p3 = Paint()
      ..shader = RadialGradient(
        colors: [o3Color, o3Color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromCircle(center: Offset(o3X, o3Y), radius: o3Radius));
    canvas.drawCircle(Offset(o3X, o3Y), o3Radius, p3);

    // 4. Orb 4: Amber / Coral Glow - Bottom Left
    final o4X = size.width * (0.18 + 0.12 * math.cos(t * 0.7));
    final o4Y = size.height * (0.82 + 0.10 * math.sin(t * 0.7));
    final o4Radius = size.width * 0.42;
    final o4Color = isDark
        ? const Color(0xFFF59E0B).withValues(alpha: 0.14)
        : const Color(0xFFF97316).withValues(alpha: 0.12);

    final p4 = Paint()
      ..shader = RadialGradient(
        colors: [o4Color, o4Color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromCircle(center: Offset(o4X, o4Y), radius: o4Radius));
    canvas.drawCircle(Offset(o4X, o4Y), o4Radius, p4);

    // 5. Orb 5: Center Emerald / Mint Pulse
    final o5X = size.width * (0.50 + 0.10 * math.sin(t * 0.8));
    final o5Y = size.height * (0.50 + 0.10 * math.cos(t * 0.8));
    final o5Radius = size.width * 0.36;
    final o5Color = isDark
        ? const Color(0xFF10B981).withValues(alpha: 0.12)
        : const Color(0xFF10B981).withValues(alpha: 0.10);

    final p5 = Paint()
      ..shader = RadialGradient(
        colors: [o5Color, o5Color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromCircle(center: Offset(o5X, o5Y), radius: o5Radius));
    canvas.drawCircle(Offset(o5X, o5Y), o5Radius, p5);

    // Floating Ambient Micro-Particles
    final particlePaint = Paint()..style = PaintingStyle.fill;
    const particleCount = 28;
    for (int i = 0; i < particleCount; i++) {
      final pProgress = (progress + (i / particleCount)) % 1.0;
      final px = (math.sin(i * 137.5) * 0.5 + 0.5) * size.width +
          math.sin(pProgress * 2 * math.pi + i) * 26;
      final py = (1.0 - pProgress) * size.height;
      final radius = 1.2 + (i % 4) * 0.9;
      final alpha = math.sin(pProgress * math.pi) * (isDark ? 0.35 : 0.28);

      final Color pColor;
      if (i % 4 == 0) {
        pColor = AppColors.primary;
      } else if (i % 4 == 1) {
        pColor = AppColors.secondary;
      } else if (i % 4 == 2) {
        pColor = AppColors.purple;
      } else {
        pColor = AppColors.accentAmber;
      }

      particlePaint.color = pColor.withValues(alpha: alpha);
      canvas.drawCircle(Offset(px, py), radius, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}
