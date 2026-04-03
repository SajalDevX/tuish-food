import 'package:flutter/material.dart';
import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';

class TuishCard extends StatefulWidget {
  const TuishCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.elevation, // kept for API compat but ignored for glass
    this.borderRadius,
    this.color,
    this.margin,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final double? elevation;
  final BorderRadius? borderRadius;
  final Color? color;
  final EdgeInsetsGeometry? margin;

  @override
  State<TuishCard> createState() => _TuishCardState();
}

class _TuishCardState extends State<TuishCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    if (widget.onTap != null) _controller.forward();
  }

  void _handleTapUp(TapUpDetails _) {
    if (widget.onTap != null) {
      _controller.reverse();
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) widget.onTap?.call();
      });
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null) _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveRadius = widget.borderRadius ?? AppSizes.borderRadiusL;
    final effectiveFill =
        widget.color ??
        (isDark ? AppColors.darkCard : AppColors.cardBackground);
    final effectiveBorder = isDark ? AppColors.darkDivider : AppColors.divider;

    final content = Padding(
      padding: widget.margin ?? EdgeInsets.zero,
      child: Material(
        color: effectiveFill,
        borderRadius: effectiveRadius,
        elevation: widget.elevation ?? AppSizes.elevationCard,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: widget.onTap != null ? _handleTapDown : null,
          onTapUp: widget.onTap != null ? _handleTapUp : null,
          onTapCancel: widget.onTap != null ? _handleTapCancel : null,
          borderRadius: effectiveRadius,
          child: Container(
            decoration: BoxDecoration(
              color: effectiveFill,
              borderRadius: effectiveRadius,
              border: Border.all(color: effectiveBorder),
            ),
            padding: widget.padding ?? AppSizes.paddingAllM,
            child: widget.child,
          ),
        ),
      ),
    );

    if (widget.onTap != null) {
      return AnimatedBuilder(
        animation: _scale,
        builder: (context, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: content,
      );
    }

    return content;
  }
}
