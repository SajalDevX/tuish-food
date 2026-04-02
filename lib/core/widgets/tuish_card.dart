import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';

class TuishCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveRadius = borderRadius ?? AppSizes.borderRadiusL;
    final effectiveFill = color ??
        (isDark ? AppColors.darkGlassFill : AppColors.lightGlassFill);
    final effectiveBorder =
        isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder;

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Material(
            color: effectiveFill,
            borderRadius: effectiveRadius,
            child: InkWell(
              onTap: onTap,
              borderRadius: effectiveRadius,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: effectiveRadius,
                  border: Border.all(color: effectiveBorder, width: 1),
                ),
                padding: padding ?? AppSizes.paddingAllM,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
