import 'package:flutter/material.dart';
import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';

enum _TuishButtonVariant { primary, secondary, outlined, text }

class TuishButton extends StatelessWidget {
  const TuishButton._({
    required this.label,
    required this.variant,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.isFullWidth = true,
    super.key,
  });

  /// Filled button with primary color.
  const factory TuishButton.primary({
    required String label,
    VoidCallback? onPressed,
    bool isLoading,
    Widget? icon,
    bool isFullWidth,
    Key? key,
  }) = _TuishButtonPrimary;

  /// Filled button with secondary color.
  const factory TuishButton.secondary({
    required String label,
    VoidCallback? onPressed,
    bool isLoading,
    Widget? icon,
    bool isFullWidth,
    Key? key,
  }) = _TuishButtonSecondary;

  /// Outlined button with primary-colored border.
  const factory TuishButton.outlined({
    required String label,
    VoidCallback? onPressed,
    bool isLoading,
    Widget? icon,
    bool isFullWidth,
    Key? key,
  }) = _TuishButtonOutlined;

  /// Text-only button.
  const factory TuishButton.text({
    required String label,
    VoidCallback? onPressed,
    bool isLoading,
    Widget? icon,
    bool isFullWidth,
    Key? key,
  }) = _TuishButtonText;

  final String label;
  // ignore: library_private_types_in_public_api
  final _TuishButtonVariant variant;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget? icon;
  final bool isFullWidth;

  bool get _isDisabled => onPressed == null || isLoading;

  Widget _buildLoadingIndicator(Color color) {
    return SizedBox(
      key: const ValueKey('loading'),
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }

  Widget _buildChild(Color foregroundColor) {
    final textWidget = Text(
      label,
      style: AppTypography.labelLarge.copyWith(color: foregroundColor),
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: isLoading
          ? _buildLoadingIndicator(foregroundColor)
          : (icon != null
              ? Row(
                  key: const ValueKey('content'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    icon!,
                    const SizedBox(width: AppSizes.s8),
                    textWidget,
                  ],
                )
              : KeyedSubtree(
                  key: const ValueKey('content'),
                  child: textWidget,
                )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget button;

    switch (variant) {
      case _TuishButtonVariant.primary:
        button = ElevatedButton(
          onPressed: _isDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            disabledBackgroundColor:
                AppColors.primaryLight.withValues(alpha: 0.5),
            disabledForegroundColor:
                AppColors.onPrimary.withValues(alpha: 0.7),
            minimumSize: Size(
              isFullWidth ? double.infinity : 0,
              AppSizes.buttonHeight,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: AppSizes.borderRadiusM,
            ),
            elevation: AppSizes.elevationCard,
          ),
          child: _buildChild(AppColors.onPrimary),
        );

      case _TuishButtonVariant.secondary:
        button = ElevatedButton(
          onPressed: _isDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: AppColors.onSecondary,
            disabledBackgroundColor:
                AppColors.secondaryLight.withValues(alpha: 0.5),
            disabledForegroundColor:
                AppColors.onSecondary.withValues(alpha: 0.7),
            minimumSize: Size(
              isFullWidth ? double.infinity : 0,
              AppSizes.buttonHeight,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: AppSizes.borderRadiusM,
            ),
            elevation: AppSizes.elevationCard,
          ),
          child: _buildChild(AppColors.onSecondary),
        );

      case _TuishButtonVariant.outlined:
        button = OutlinedButton(
          onPressed: _isDisabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: BorderSide(
              color: _isDisabled
                  ? AppColors.primaryLight.withValues(alpha: 0.5)
                  : AppColors.primary,
              width: 1.5,
            ),
            minimumSize: Size(
              isFullWidth ? double.infinity : 0,
              AppSizes.buttonHeight,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: AppSizes.borderRadiusM,
            ),
          ),
          child: _buildChild(
            _isDisabled
                ? AppColors.primaryLight.withValues(alpha: 0.5)
                : AppColors.primary,
          ),
        );

      case _TuishButtonVariant.text:
        button = TextButton(
          onPressed: _isDisabled ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: Size(
              isFullWidth ? double.infinity : 0,
              AppSizes.buttonHeight,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: AppSizes.borderRadiusM,
            ),
          ),
          child: _buildChild(
            _isDisabled
                ? AppColors.primaryLight.withValues(alpha: 0.5)
                : AppColors.primary,
          ),
        );
    }

    return _AnimatedPressScale(child: button);
  }
}

// Private subclasses to enable const factory constructors.

class _TuishButtonPrimary extends TuishButton {
  const _TuishButtonPrimary({
    required super.label,
    super.onPressed,
    super.isLoading,
    super.icon,
    super.isFullWidth,
    super.key,
  }) : super._(variant: _TuishButtonVariant.primary);
}

class _TuishButtonSecondary extends TuishButton {
  const _TuishButtonSecondary({
    required super.label,
    super.onPressed,
    super.isLoading,
    super.icon,
    super.isFullWidth,
    super.key,
  }) : super._(variant: _TuishButtonVariant.secondary);
}

class _TuishButtonOutlined extends TuishButton {
  const _TuishButtonOutlined({
    required super.label,
    super.onPressed,
    super.isLoading,
    super.icon,
    super.isFullWidth,
    super.key,
  }) : super._(variant: _TuishButtonVariant.outlined);
}

class _TuishButtonText extends TuishButton {
  const _TuishButtonText({
    required super.label,
    super.onPressed,
    super.isLoading,
    super.icon,
    super.isFullWidth,
    super.key,
  }) : super._(variant: _TuishButtonVariant.text);
}

class _AnimatedPressScale extends StatefulWidget {
  const _AnimatedPressScale({required this.child});
  final Widget child;

  @override
  State<_AnimatedPressScale> createState() => _AnimatedPressScaleState();
}

class _AnimatedPressScaleState extends State<_AnimatedPressScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}
