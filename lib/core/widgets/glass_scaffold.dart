import 'package:flutter/material.dart';
import 'package:tuish_food/core/constants/app_colors.dart';

/// A scaffold wrapper that provides a gradient background for glassmorphism.
///
/// `BackdropFilter` needs varied content behind it to produce a visible
/// frosted-glass effect. A flat solid color blurs into itself and looks
/// identical. This widget places a subtle gradient + decorative blurred
/// circles behind the scaffold body so that glass cards and app bars have
/// something to frost over.
class GlassScaffold extends StatelessWidget {
  const GlassScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.extendBodyBehindAppBar = true,
    this.extendBody = false,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool extendBodyBehindAppBar;
  final bool extendBody;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      extendBody: extendBody,
      backgroundColor: Colors.transparent,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        AppColors.darkScaffold,
                        const Color(0xFF0F1923), // slight blue tint
                        const Color(0xFF131A24),
                        AppColors.darkSurfaceDim,
                      ]
                    : [
                        AppColors.lightScaffold,
                        const Color(0xFFE8ECF4), // slight blue tint
                        const Color(0xFFF2EDE8), // slight warm tint
                        const Color(0xFFEEF0F5),
                      ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),

          // Decorative blurred accent circles for depth
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.secondary.withValues(alpha: isDark ? 0.06 : 0.04),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Actual body content
          body,
        ],
      ),
    );
  }
}
