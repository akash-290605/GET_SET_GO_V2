import 'package:flutter/material.dart';
import '../services/theme_service.dart';

/// A modern theme-adaptive Glassmorphic card with smooth hover elevation,
/// subtle translucent borders, and soft diffused shadows.
class GlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final Color? color;
  final Gradient? gradient;
  final Border? border;
  final Color? borderColor;
  final double? width;
  final double? height;
  final bool enableHover;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.borderRadius = 16.0,
    this.onTap,
    this.color,
    this.gradient,
    this.border,
    this.borderColor,
    this.width,
    this.height,
    this.enableHover = true,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.instance.isDarkMode(context);

    final defaultBgColor = widget.color ??
        (isDark
            ? const Color(0xFF11182B).withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.78));

    final defaultBorderColor = widget.borderColor ??
        (isDark
            ? Colors.white.withValues(alpha: _isHovered ? 0.20 : 0.09)
            : const Color(0xFF64748B).withValues(alpha: _isHovered ? 0.24 : 0.14));

    final effectiveBorder = widget.border ??
        Border.all(
          color: defaultBorderColor,
          width: 1.0,
        );

    final shadowColor = isDark
        ? Colors.black.withValues(alpha: _isHovered ? 0.40 : 0.25)
        : const Color(0xFF1E40AF).withValues(alpha: _isHovered ? 0.12 : 0.07);

    final translateY = (widget.enableHover && _isHovered) ? -3.0 : 0.0;

    return Padding(
      padding: widget.margin ?? EdgeInsets.zero,
      child: MouseRegion(
        onEnter: (_) {
          if (widget.enableHover && mounted) setState(() => _isHovered = true);
        },
        onExit: (_) {
          if (widget.enableHover && mounted) setState(() => _isHovered = false);
        },
        cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, translateY, 0),
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.gradient == null ? defaultBgColor : null,
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: effectiveBorder,
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: _isHovered ? 24 : 14,
                offset: Offset(0, _isHovered ? 8 : 4),
                spreadRadius: _isHovered ? 1 : 0,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              splashColor: AppColors.primary.withValues(alpha: 0.08),
              highlightColor: AppColors.primary.withValues(alpha: 0.04),
              child: Padding(
                padding: widget.padding ?? EdgeInsets.zero,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
