import 'package:flutter/material.dart';
import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/widgets/tuish_button.dart';

class EmptyStateWidget extends StatefulWidget {
  const EmptyStateWidget({
    super.key,
    required this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  State<EmptyStateWidget> createState() => _EmptyStateWidgetState();
}

class _EmptyStateWidgetState extends State<EmptyStateWidget>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _entranceScale;
  late final Animation<double> _entranceOpacity;

  late final AnimationController _floatController;
  late final Animation<double> _floatOffset;

  @override
  void initState() {
    super.initState();

    // Entrance animation: scale + fade
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _entranceScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutBack,
      ),
    );
    _entranceOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOut,
      ),
    );
    _entranceController.forward();

    // Floating icon animation: gentle Y oscillation
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _floatOffset = Tween<double>(begin: -4.0, end: 4.0).animate(
      CurvedAnimation(
        parent: _floatController,
        curve: Curves.easeInOut,
      ),
    );
    _floatController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        return Opacity(
          opacity: _entranceOpacity.value,
          child: Transform.scale(
            scale: _entranceScale.value,
            child: child,
          ),
        );
      },
      child: Center(
        child: Padding(
          padding: AppSizes.paddingAllL,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _floatOffset,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _floatOffset.value),
                    child: child,
                  );
                },
                child: Builder(
                  builder: (context) {
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    return Icon(
                      widget.icon ?? Icons.inbox_rounded,
                      size: AppSizes.iconXL * 1.5,
                      color: isDark ? Colors.white38 : AppColors.textHint,
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSizes.s16),
              Builder(
                builder: (context) {
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  return Text(
                    widget.message,
                    style: AppTypography.bodyLarge.copyWith(
                      color: isDark ? Colors.white60 : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  );
                },
              ),
              if (widget.actionLabel != null && widget.onAction != null) ...[
                const SizedBox(height: AppSizes.s24),
                TuishButton.primary(
                  label: widget.actionLabel!,
                  onPressed: widget.onAction,
                  isFullWidth: false,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
