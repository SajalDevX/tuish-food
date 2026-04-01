import 'package:flutter/material.dart';
import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';

class TuishCard extends StatelessWidget {
  const TuishCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.elevation,
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
    final effectiveBorderRadius = borderRadius ?? AppSizes.borderRadiusM;
    final effectiveElevation = elevation ?? AppSizes.elevationCard;
    final effectiveColor = color ?? AppColors.cardBackground;

    return Card(
      elevation: effectiveElevation,
      shape: RoundedRectangleBorder(borderRadius: effectiveBorderRadius),
      color: effectiveColor,
      margin: margin ?? EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: effectiveBorderRadius,
        child: Padding(
          padding: padding ?? AppSizes.paddingAllM,
          child: child,
        ),
      ),
    );
  }
}
