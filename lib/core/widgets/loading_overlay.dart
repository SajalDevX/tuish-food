import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:tuish_food/core/constants/app_colors.dart';

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.color,
    this.opacity = 0.5,
  });

  final bool isLoading;
  final Widget child;
  final Color? color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: AbsorbPointer(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isLoading ? 1.0 : 0.0,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    color: (color ?? Colors.black).withValues(alpha: opacity),
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
