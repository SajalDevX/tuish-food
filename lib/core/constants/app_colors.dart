import 'package:flutter/material.dart';

abstract final class AppColors {
  // Primary
  static const Color primary = Color(0xFFFF5722);
  static const Color primaryLight = Color(0xFFFF8A65);
  static const Color primaryDark = Color(0xFFE64A19);
  static const Color onPrimary = Colors.white;

  // Secondary
  static const Color secondary = Color(0xFF009688);
  static const Color secondaryLight = Color(0xFF4DB6AC);
  static const Color secondaryDark = Color(0xFF00796B);
  static const Color onSecondary = Colors.white;

  // Surface & Background
  static const Color surface = Colors.white;
  static const Color background = Color(0xFFF5F5F5);
  static const Color scaffoldBackground = Color(0xFFFAFAFA);
  static const Color cardBackground = Colors.white;

  // Text
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textOnDark = Colors.white;

  // Status
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF42A5F5);

  // Order Status Colors
  static const Color statusPlaced = Color(0xFF42A5F5);
  static const Color statusConfirmed = Color(0xFF66BB6A);
  static const Color statusPreparing = Color(0xFFFFA726);
  static const Color statusReady = Color(0xFF26C6DA);
  static const Color statusPickedUp = Color(0xFF7E57C2);
  static const Color statusOnTheWay = Color(0xFF5C6BC0);
  static const Color statusDelivered = Color(0xFF4CAF50);
  static const Color statusCancelled = Color(0xFFEF5350);

  // Misc
  static const Color divider = Color(0xFFE0E0E0);
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
  static const Color starFilled = Color(0xFFFFC107);
  static const Color starEmpty = Color(0xFFE0E0E0);
  static const Color vegGreen = Color(0xFF4CAF50);
  static const Color nonVegRed = Color(0xFFD32F2F);

  // Dark Theme
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkCard = Color(0xFF2C2C2C);
  static const Color darkDivider = Color(0xFF424242);
}
