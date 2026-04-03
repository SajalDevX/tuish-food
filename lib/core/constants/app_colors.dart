import 'package:flutter/material.dart';

abstract final class AppColors {
  // Primary
  static const Color primary = Color(0xFFE23744);
  static const Color primaryLight = Color(0xFFFF6B74);
  static const Color primaryDark = Color(0xFFB71C2A);
  static const Color onPrimary = Colors.white;

  // Secondary
  static const Color secondary = Color(0xFF2F855A);
  static const Color secondaryLight = Color(0xFF48BB78);
  static const Color secondaryDark = Color(0xFF276749);
  static const Color onSecondary = Colors.white;

  // Surface & Background
  static const Color surface = Colors.white;
  static const Color background = Color(0xFFF8F8F8);
  static const Color scaffoldBackground = Color(0xFFF5F5F5);
  static const Color cardBackground = Colors.white;

  // Text
  static const Color textPrimary = Color(0xFF1C1C1C);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textHint = Color(0xFF9E9E9E);
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
  static const Color divider = Color(0xFFE8E8E8);
  static const Color shimmerBase = Color(0xFFEAEAEA);
  static const Color shimmerHighlight = Color(0xFFF7F7F7);
  static const Color starFilled = Color(0xFFFFC107);
  static const Color starEmpty = Color(0xFFE0E0E0);
  static const Color vegGreen = Color(0xFF4CAF50);
  static const Color nonVegRed = Color(0xFFD32F2F);

  // Dark Theme
  static const Color darkSurface = Color(0xFF1F1F1F);
  static const Color darkBackground = Color(0xFF111111);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkDivider = Color(0xFF2B2B2B);
  static const Color darkScaffold = Color(0xFF101010);
  static const Color darkSurfaceDim = Color(0xFF161616);

  // Flat theme compatibility tokens
  static const Color lightGlassFill = surface;
  static const Color lightGlassBorder = divider;
  static const Color lightGlassStroke = divider;
  static const Color lightScaffold = scaffoldBackground;

  static const Color darkGlassFill = darkCard;
  static const Color darkGlassBorder = darkDivider;
  static const Color darkGlassStroke = darkDivider;

  static const Color glassTextPrimary = Colors.white;
  static const Color glassTextBody = Color(0xFFEAEAEA);
  static const Color glassTextSecondary = Color(0xFFB8B8B8);
  static const Color glassTextHint = Color(0xFF8C8C8C);
}
