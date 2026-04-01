import 'package:flutter/material.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';

/// Convenient getters and helper methods on [BuildContext].
extension ContextExtensions on BuildContext {
  // ---------------------------------------------------------------------------
  // Theme shortcuts
  // ---------------------------------------------------------------------------

  /// Equivalent to `Theme.of(context)`.
  ThemeData get theme => Theme.of(this);

  /// Equivalent to `Theme.of(context).colorScheme`.
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Equivalent to `Theme.of(context).textTheme`.
  TextTheme get textTheme => Theme.of(this).textTheme;

  // ---------------------------------------------------------------------------
  // MediaQuery shortcuts
  // ---------------------------------------------------------------------------

  /// Equivalent to `MediaQuery.of(context)`.
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Logical screen width in dp.
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// Logical screen height in dp.
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// Top padding (status bar / notch).
  double get topPadding => MediaQuery.paddingOf(this).top;

  /// Bottom padding (navigation bar / home indicator).
  double get bottomPadding => MediaQuery.paddingOf(this).bottom;

  // ---------------------------------------------------------------------------
  // SnackBar helpers
  // ---------------------------------------------------------------------------

  /// Shows a [SnackBar] with the given [message].
  ///
  /// When [isError] is `true` the snackbar uses the error colour scheme.
  void showSnackBar(
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor:
              isError ? AppColors.error : AppColors.textPrimary,
          duration: duration,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppSizes.borderRadiusS,
          ),
          margin: const EdgeInsets.all(AppSizes.s16),
          action: action,
        ),
      );
  }

  // ---------------------------------------------------------------------------
  // Dialog helpers
  // ---------------------------------------------------------------------------

  /// Shows a centered loading dialog that blocks interaction.
  ///
  /// Call [hideLoadingDialog] to dismiss it.
  void showLoadingDialog({String? message}) {
    showDialog<void>(
      context: this,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Center(
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: AppSizes.borderRadiusM,
            ),
            child: Padding(
              padding: AppSizes.paddingAllL,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  if (message != null) ...[
                    const SizedBox(height: AppSizes.s16),
                    Text(
                      message,
                      style: context.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Pops the topmost route -- intended to dismiss a dialog opened by
  /// [showLoadingDialog].
  void hideLoadingDialog() {
    if (Navigator.of(this).canPop()) {
      Navigator.of(this).pop();
    }
  }
}
