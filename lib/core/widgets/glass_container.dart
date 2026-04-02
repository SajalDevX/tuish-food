import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';

class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius,
    this.blur = 12.0,
    this.fillColor,
    this.borderColor,
    this.padding,
    this.margin,
    this.onTap,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final double blur;
  final Color? fillColor;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveRadius = borderRadius ?? AppSizes.borderRadiusL;
    final effectiveFill = fillColor ??
        (isDark ? AppColors.darkGlassFill : AppColors.lightGlassFill);
    final effectiveBorder = borderColor ??
        (isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder);

    Widget content = ClipRRect(
      borderRadius: effectiveRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: effectiveFill,
            borderRadius: effectiveRadius,
            border: Border.all(color: effectiveBorder, width: 1),
          ),
          padding: padding ?? AppSizes.paddingAllM,
          margin: margin,
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      content = GestureDetector(onTap: onTap, child: content);
    }

    return content;
  }
}
