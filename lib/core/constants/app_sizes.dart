import 'package:flutter/material.dart';

abstract final class AppSizes {
  // Spacing (4px base unit)
  static const double s4 = 4.0;
  static const double s8 = 8.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s20 = 20.0;
  static const double s24 = 24.0;
  static const double s32 = 32.0;
  static const double s48 = 48.0;
  static const double s64 = 64.0;

  // Padding
  static const EdgeInsets paddingAllS = EdgeInsets.all(8.0);
  static const EdgeInsets paddingAllM = EdgeInsets.all(16.0);
  static const EdgeInsets paddingAllL = EdgeInsets.all(24.0);
  static const EdgeInsets paddingHorizontalM =
      EdgeInsets.symmetric(horizontal: 16.0);
  static const EdgeInsets paddingHorizontalL =
      EdgeInsets.symmetric(horizontal: 24.0);
  static const EdgeInsets screenPadding =
      EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0);

  // Border Radius
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusPill = 999.0;

  static final BorderRadius borderRadiusS = BorderRadius.circular(radiusS);
  static final BorderRadius borderRadiusM = BorderRadius.circular(radiusM);
  static final BorderRadius borderRadiusL = BorderRadius.circular(radiusL);
  static final BorderRadius borderRadiusXL = BorderRadius.circular(radiusXL);
  static final BorderRadius borderRadiusPill =
      BorderRadius.circular(radiusPill);

  // Elevation
  static const double elevationNone = 0.0;
  static const double elevationCard = 2.0;
  static const double elevationFloating = 4.0;
  static const double elevationDialog = 8.0;

  // Icon Sizes
  static const double iconS = 16.0;
  static const double iconM = 24.0;
  static const double iconL = 32.0;
  static const double iconXL = 48.0;

  // Button Heights
  static const double buttonHeight = 52.0;
  static const double buttonHeightSmall = 40.0;

  // Min touch target (accessibility)
  static const double minTouchTarget = 48.0;

  // Avatar Sizes
  static const double avatarS = 32.0;
  static const double avatarM = 48.0;
  static const double avatarL = 64.0;
  static const double avatarXL = 96.0;

  // Card
  static const double cardImageHeight = 180.0;
  static const double restaurantCardHeight = 240.0;
  static const double menuItemImageSize = 100.0;

  // Bottom Navigation
  static const double bottomNavHeight = 65.0;
}
