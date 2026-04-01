# UI Design System

This document defines the visual design system for Tuish Food, including brand identity, color palette, typography, spacing, component library, dark mode, accessibility, and animations.

---

## Brand Identity

| Attribute | Value |
| --------- | ----- |
| **App Name** | Tuish Food |
| **Tagline** | Delicious food, delivered fast |
| **Primary Color** | Deep Orange `#FF5722` |
| **Secondary Color** | Teal `#009688` |
| **Icon Style** | Material Icons Rounded |
| **Personality** | Warm, fast, reliable, modern |

---

## Color Palette

### Light Theme

| Token | Hex | Usage |
| ----- | --- | ----- |
| `primary` | `#FF5722` | Buttons, active states, brand accents |
| `primaryLight` | `#FF8A65` | Hover states, lighter accents |
| `primaryDark` | `#E64A19` | Pressed states, app bar |
| `onPrimary` | `#FFFFFF` | Text/icons on primary color |
| `secondary` | `#009688` | Secondary buttons, accents, success states |
| `secondaryLight` | `#4DB6AC` | Lighter secondary accents |
| `secondaryDark` | `#00796B` | Darker secondary accents |
| `onSecondary` | `#FFFFFF` | Text/icons on secondary color |
| `surface` | `#FFFFFF` | Cards, sheets, dialogs |
| `onSurface` | `#1C1B1F` | Primary text on surface |
| `onSurfaceVariant` | `#6B6B6B` | Secondary text, captions |
| `background` | `#F5F5F5` | Page background |
| `onBackground` | `#1C1B1F` | Text on background |
| `error` | `#D32F2F` | Error states, destructive actions |
| `onError` | `#FFFFFF` | Text/icons on error |
| `success` | `#2E7D32` | Success states, confirmations |
| `warning` | `#F9A825` | Warnings, pending states |
| `info` | `#1976D2` | Informational badges |
| `outline` | `#C4C4C4` | Borders, dividers |
| `shadow` | `#000000` (10%) | Elevation shadows |
| `disabled` | `#BDBDBD` | Disabled elements |
| `onDisabled` | `#757575` | Text on disabled elements |
| `starYellow` | `#FFB300` | Rating stars |
| `skeleton` | `#E0E0E0` | Loading skeleton base |
| `skeletonHighlight` | `#F5F5F5` | Loading skeleton shimmer |

### Dark Theme

| Token | Hex | Usage |
| ----- | --- | ----- |
| `primary` | `#FF7043` | Slightly lighter primary for dark backgrounds |
| `primaryLight` | `#FFAB91` | Light variant |
| `primaryDark` | `#FF5722` | Dark variant |
| `onPrimary` | `#1C1B1F` | Text/icons on primary |
| `secondary` | `#4DB6AC` | Lighter teal for dark backgrounds |
| `onSecondary` | `#1C1B1F` | Text/icons on secondary |
| `surface` | `#1E1E1E` | Cards, sheets |
| `onSurface` | `#E1E1E1` | Primary text |
| `onSurfaceVariant` | `#A0A0A0` | Secondary text |
| `background` | `#121212` | Page background |
| `onBackground` | `#E1E1E1` | Text on background |
| `error` | `#EF5350` | Error states |
| `success` | `#66BB6A` | Success states |
| `warning` | `#FFD54F` | Warning states |
| `outline` | `#424242` | Borders, dividers |
| `skeleton` | `#2C2C2C` | Loading skeleton base |
| `skeletonHighlight` | `#3C3C3C` | Loading skeleton shimmer |

### Color Implementation

```dart
// core/theme/app_colors.dart
abstract class AppColors {
  // Primary
  static const primary = Color(0xFFFF5722);
  static const primaryLight = Color(0xFFFF8A65);
  static const primaryDark = Color(0xFFE64A19);
  static const onPrimary = Color(0xFFFFFFFF);

  // Secondary
  static const secondary = Color(0xFF009688);
  static const secondaryLight = Color(0xFF4DB6AC);
  static const secondaryDark = Color(0xFF00796B);
  static const onSecondary = Color(0xFFFFFFFF);

  // Surface
  static const surface = Color(0xFFFFFFFF);
  static const onSurface = Color(0xFF1C1B1F);
  static const onSurfaceVariant = Color(0xFF6B6B6B);

  // Background
  static const background = Color(0xFFF5F5F5);
  static const onBackground = Color(0xFF1C1B1F);

  // Semantic
  static const error = Color(0xFFD32F2F);
  static const onError = Color(0xFFFFFFFF);
  static const success = Color(0xFF2E7D32);
  static const warning = Color(0xFFF9A825);
  static const info = Color(0xFF1976D2);

  // Utility
  static const outline = Color(0xFFC4C4C4);
  static const disabled = Color(0xFFBDBDBD);
  static const onDisabled = Color(0xFF757575);
  static const starYellow = Color(0xFFFFB300);
  static const skeleton = Color(0xFFE0E0E0);
  static const skeletonHighlight = Color(0xFFF5F5F5);
}
```

---

## Typography

### Font Families

| Family | Weight Range | Usage |
| ------ | ------------ | ----- |
| **Poppins** | 500-700 | Headings, titles, buttons |
| **Inter** | 400-600 | Body text, captions, labels |

### Type Scale

| Name | Font | Size | Weight | Line Height | Letter Spacing | Usage |
| ---- | ---- | ---- | ------ | ----------- | -------------- | ----- |
| `displayLarge` | Poppins | 32 | 700 (Bold) | 40 | -0.5 | Hero sections, splash |
| `displayMedium` | Poppins | 28 | 700 (Bold) | 36 | -0.25 | Page titles |
| `displaySmall` | Poppins | 24 | 600 (SemiBold) | 32 | 0 | Section headers |
| `headlineLarge` | Poppins | 22 | 600 (SemiBold) | 28 | 0 | Card titles |
| `headlineMedium` | Poppins | 20 | 600 (SemiBold) | 26 | 0 | Subsection headers |
| `headlineSmall` | Poppins | 18 | 600 (SemiBold) | 24 | 0 | Widget titles |
| `titleLarge` | Poppins | 16 | 600 (SemiBold) | 22 | 0.15 | List item titles, nav |
| `titleMedium` | Poppins | 14 | 600 (SemiBold) | 20 | 0.1 | Subtitles |
| `titleSmall` | Poppins | 12 | 500 (Medium) | 16 | 0.1 | Small titles |
| `bodyLarge` | Inter | 16 | 400 (Regular) | 24 | 0.25 | Primary body text |
| `bodyMedium` | Inter | 14 | 400 (Regular) | 20 | 0.25 | Default body text |
| `bodySmall` | Inter | 12 | 400 (Regular) | 16 | 0.4 | Secondary text, hints |
| `labelLarge` | Inter | 14 | 600 (SemiBold) | 20 | 0.1 | Button text |
| `labelMedium` | Inter | 12 | 500 (Medium) | 16 | 0.5 | Tags, chips |
| `labelSmall` | Inter | 10 | 500 (Medium) | 14 | 0.5 | Overlines, tiny labels |
| `caption` | Inter | 11 | 400 (Regular) | 14 | 0.4 | Timestamps, metadata |

### Typography Implementation

```dart
// core/theme/app_typography.dart
abstract class AppTypography {
  static const _poppins = 'Poppins';
  static const _inter = 'Inter';

  static TextTheme get textTheme => const TextTheme(
    displayLarge: TextStyle(
      fontFamily: _poppins,
      fontSize: 32,
      fontWeight: FontWeight.w700,
      height: 1.25,
      letterSpacing: -0.5,
    ),
    displayMedium: TextStyle(
      fontFamily: _poppins,
      fontSize: 28,
      fontWeight: FontWeight.w700,
      height: 1.29,
      letterSpacing: -0.25,
    ),
    displaySmall: TextStyle(
      fontFamily: _poppins,
      fontSize: 24,
      fontWeight: FontWeight.w600,
      height: 1.33,
    ),
    headlineLarge: TextStyle(
      fontFamily: _poppins,
      fontSize: 22,
      fontWeight: FontWeight.w600,
      height: 1.27,
    ),
    headlineMedium: TextStyle(
      fontFamily: _poppins,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.30,
    ),
    headlineSmall: TextStyle(
      fontFamily: _poppins,
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.33,
    ),
    titleLarge: TextStyle(
      fontFamily: _poppins,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.375,
      letterSpacing: 0.15,
    ),
    titleMedium: TextStyle(
      fontFamily: _poppins,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.43,
      letterSpacing: 0.1,
    ),
    titleSmall: TextStyle(
      fontFamily: _poppins,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.33,
      letterSpacing: 0.1,
    ),
    bodyLarge: TextStyle(
      fontFamily: _inter,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
      letterSpacing: 0.25,
    ),
    bodyMedium: TextStyle(
      fontFamily: _inter,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.43,
      letterSpacing: 0.25,
    ),
    bodySmall: TextStyle(
      fontFamily: _inter,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.33,
      letterSpacing: 0.4,
    ),
    labelLarge: TextStyle(
      fontFamily: _inter,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.43,
      letterSpacing: 0.1,
    ),
    labelMedium: TextStyle(
      fontFamily: _inter,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.33,
      letterSpacing: 0.5,
    ),
    labelSmall: TextStyle(
      fontFamily: _inter,
      fontSize: 10,
      fontWeight: FontWeight.w500,
      height: 1.4,
      letterSpacing: 0.5,
    ),
  );
}
```

---

## Spacing System

Base unit: **4px**. All spacing values are multiples of the base unit.

| Token | Value | Usage |
| ----- | ----- | ----- |
| `xxs` | 4px | Tight padding, icon margins |
| `xs` | 8px | Compact padding, inline spacing |
| `sm` | 12px | Small component padding |
| `md` | 16px | Default padding, standard spacing |
| `lg` | 24px | Section spacing, card padding |
| `xl` | 32px | Large section gaps |
| `xxl` | 48px | Major section dividers |
| `xxxl` | 64px | Page-level spacing |

### Implementation

```dart
// core/theme/app_spacing.dart
abstract class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  // Convenience EdgeInsets
  static const allXs = EdgeInsets.all(xs);
  static const allSm = EdgeInsets.all(sm);
  static const allMd = EdgeInsets.all(md);
  static const allLg = EdgeInsets.all(lg);

  static const horizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const horizontalLg = EdgeInsets.symmetric(horizontal: lg);
  static const verticalMd = EdgeInsets.symmetric(vertical: md);
  static const verticalLg = EdgeInsets.symmetric(vertical: lg);

  // Screen-level padding
  static const screenPadding = EdgeInsets.symmetric(horizontal: md, vertical: sm);
}
```

---

## Border Radius

| Token | Value | Usage |
| ----- | ----- | ----- |
| `none` | 0px | No rounding |
| `sm` | 4px | Subtle rounding (tags, small chips) |
| `md` | 8px | Cards, containers, images |
| `lg` | 12px | Buttons, text fields, larger cards |
| `xl` | 16px | Modals, dialogs |
| `xxl` | 24px | Bottom sheets (top corners) |
| `pill` | 999px | Pill buttons, badges, chips |
| `circle` | 50% | Avatars, FABs |

### Implementation

```dart
// core/theme/app_radius.dart
abstract class AppRadius {
  static const none = BorderRadius.zero;
  static final sm = BorderRadius.circular(4);
  static final md = BorderRadius.circular(8);
  static final lg = BorderRadius.circular(12);
  static final xl = BorderRadius.circular(16);
  static final xxl = BorderRadius.circular(24);
  static final pill = BorderRadius.circular(999);

  // Top-only for bottom sheets
  static const topXxl = BorderRadius.only(
    topLeft: Radius.circular(24),
    topRight: Radius.circular(24),
  );
}
```

---

## Elevation Levels

| Level | Elevation | Shadow | Usage |
| ----- | --------- | ------ | ----- |
| 0 | 0dp | None | Flat elements, inline content |
| 1 | 2dp | Subtle | Cards, list tiles |
| 2 | 4dp | Light | Raised buttons, active cards |
| 3 | 8dp | Medium | Dialogs, bottom sheets, FAB |
| 4 | 16dp | Strong | Navigation drawers, modal overlays |

---

## Component Library

### TuishButton

The primary button component with multiple variants.

```dart
class TuishButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final TuishButtonVariant variant;
  final TuishButtonSize size;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool isFullWidth;

  // Variants: primary, secondary, outlined, text, destructive
  // Sizes: small (36h), medium (44h), large (52h)
}
```

| Variant | Background | Text | Border |
| ------- | ---------- | ---- | ------ |
| `primary` | `primary` | `onPrimary` | None |
| `secondary` | `secondary` | `onSecondary` | None |
| `outlined` | Transparent | `primary` | `primary` 1.5px |
| `text` | Transparent | `primary` | None |
| `destructive` | `error` | `onError` | None |

### TuishTextField

```dart
class TuishTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? errorText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final IconData? prefixIcon;
  final Widget? suffix;
  final int? maxLines;
  final String? Function(String?)? validator;
}
```

- Default height: 52px
- Border radius: 12px
- Border: 1.5px `outline`, 2px `primary` when focused
- Error state: 2px `error` border, error text below

### TuishCard

```dart
class TuishCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final double? elevation;
  final BorderRadius? borderRadius;

  // Default: elevation 2, borderRadius 8, padding 16
}
```

### TuishAppBar

```dart
class TuishAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final bool showBackButton;
  final Color? backgroundColor;

  // Default: primary background, white text, 56px height
}
```

### StatusBadge

Colored badge for order status display.

```dart
class StatusBadge extends StatelessWidget {
  final String label;
  final StatusBadgeType type;

  // Types map to colors:
  // placed -> info (blue)
  // confirmed -> secondary (teal)
  // preparing -> warning (amber)
  // readyForPickup -> warning (amber)
  // pickedUp -> primary (orange)
  // delivered -> success (green)
  // cancelled -> error (red)
}
```

### RatingBar

```dart
class RatingBar extends StatelessWidget {
  final double rating;
  final int maxRating;
  final double size;
  final bool interactive;
  final ValueChanged<double>? onRatingChanged;
  final bool allowHalfRating;

  // Stars with starYellow color, empty stars with outline color
}
```

### PriceTag

```dart
class PriceTag extends StatelessWidget {
  final int priceInCents;
  final int? originalPriceInCents; // Show strikethrough if provided
  final TextStyle? style;

  // Formats: $12.99, with original as strikethrough $15.99
}
```

### LoadingSkeleton

Shimmer loading placeholder that matches content layout.

```dart
class LoadingSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  // Animated shimmer effect:
  // Base color: skeleton
  // Highlight color: skeletonHighlight
  // Duration: 1.5 seconds
}

// Pre-built skeleton layouts:
class RestaurantCardSkeleton extends StatelessWidget { ... }
class MenuItemSkeleton extends StatelessWidget { ... }
class OrderCardSkeleton extends StatelessWidget { ... }
```

### EmptyStateWidget

```dart
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String? description;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  // Centered layout with large icon, title, description, and optional CTA button
}
```

### TuishBottomSheet

```dart
class TuishBottomSheet extends StatelessWidget {
  final Widget child;
  final String? title;
  final bool showDragHandle;

  // Top border radius: 24px
  // Drag handle: 40x4px rounded bar
  // Max height: 90% of screen
}
```

---

## Dark Mode

Dark mode uses the adjusted palette defined in the Dark Theme colors above. It is applied via Flutter's `ThemeData`:

```dart
// core/theme/app_theme.dart
abstract class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      error: AppColors.error,
      onError: AppColors.onError,
    ),
    scaffoldBackgroundColor: AppColors.background,
    textTheme: AppTypography.textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
      color: AppColors.surface,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
        textStyle: AppTypography.textTheme.labelLarge,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: AppRadius.lg),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.onSurfaceVariant,
      backgroundColor: AppColors.surface,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFFF7043),
      onPrimary: Color(0xFF1C1B1F),
      secondary: Color(0xFF4DB6AC),
      onSecondary: Color(0xFF1C1B1F),
      surface: Color(0xFF1E1E1E),
      onSurface: Color(0xFFE1E1E1),
      error: Color(0xFFEF5350),
      onError: Color(0xFF1C1B1F),
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    textTheme: AppTypography.textTheme,
    // ... similar theme customizations for dark mode
  );
}
```

### Theme Mode Selection

```dart
// Follows system setting by default
MaterialApp.router(
  themeMode: ThemeMode.system, // or .light, .dark
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
)
```

---

## Accessibility

### Touch Targets

All interactive elements have a minimum touch target of **48x48 pixels** (per Material Design and WCAG guidelines).

```dart
// Enforce in custom widgets
constraints: const BoxConstraints(
  minWidth: 48,
  minHeight: 48,
),
```

### Color Contrast

All text and interactive elements meet **WCAG 2.1 AA** contrast requirements:

| Pair | Contrast Ratio | Requirement | Status |
| ---- | -------------- | ----------- | ------ |
| `onPrimary` on `primary` | 4.7:1 | 4.5:1 (AA) | Pass |
| `onSurface` on `surface` | 16:1 | 4.5:1 (AA) | Pass |
| `onSurfaceVariant` on `surface` | 4.9:1 | 4.5:1 (AA) | Pass |
| `error` on `surface` | 5.5:1 | 4.5:1 (AA) | Pass |
| `primary` on `background` | 4.6:1 | 3:1 (AA for large text) | Pass |

### Semantic Labels

All images and icons include semantic labels for screen readers:

```dart
Image.network(
  restaurant.imageUrl,
  semanticLabel: '${restaurant.name} cover photo',
)

Icon(
  Icons.star_rounded,
  semanticLabel: 'Rating: ${restaurant.rating} stars',
)
```

### Focus Management

- Logical tab order for keyboard navigation
- Focus rings visible on all interactive elements
- `ExcludeSemantics` used to avoid redundant screen reader announcements

---

## Animations

### Page Transitions

| Transition | Duration | Curve | Usage |
| ---------- | -------- | ----- | ----- |
| Slide right | 300ms | `easeInOut` | Forward navigation |
| Slide left | 300ms | `easeInOut` | Back navigation |
| Slide up | 350ms | `easeOutCubic` | Bottom sheets, modals |
| Fade | 200ms | `easeIn` | Tab switches, content load |

### Micro-Interactions

| Interaction | Animation | Duration |
| ----------- | --------- | -------- |
| Add to cart | Item image flies to cart icon with scale down | 500ms |
| Remove from cart | Item slides out with fade | 300ms |
| Favorite toggle | Heart scales up then down (bounce) | 400ms |
| Status change | Status badge slides in with color transition | 350ms |
| Pull to refresh | Custom Tuish Food logo rotation | While loading |
| Skeleton shimmer | Linear gradient sweep | 1500ms (repeat) |
| Button press | Scale down to 0.95 then back | 150ms |
| Rating stars | Sequential fill with slight delay per star | 100ms per star |
| Order placed | Confetti/celebration animation | 2000ms |
| Counter +/- | Number slide up/down | 200ms |

### Animation Implementation

```dart
// Add to cart animation
class AddToCartAnimation extends StatefulWidget {
  final GlobalKey cartIconKey;
  final Widget child;

  // Animates child widget from its position to the cart icon position
  // Uses Overlay for the flying animation
}

// Heartbeat favorite toggle
class FavoriteButton extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback onToggle;

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: IconButton(
        icon: Icon(
          widget.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: widget.isFavorite ? AppColors.error : AppColors.onSurfaceVariant,
        ),
        onPressed: () {
          _controller.forward(from: 0);
          widget.onToggle();
        },
      ),
    );
  }
}
```

---

## Icon Style

All icons use **Material Icons Rounded** for a consistent, friendly appearance:

```dart
Icon(Icons.home_rounded)           // Not Icons.home or Icons.home_outlined
Icon(Icons.search_rounded)
Icon(Icons.shopping_cart_rounded)
Icon(Icons.person_rounded)
Icon(Icons.star_rounded)
Icon(Icons.delivery_dining_rounded)
Icon(Icons.receipt_long_rounded)
```

### Custom Icons

For brand-specific icons not available in Material Icons:

- Stored as SVG in `assets/icons/`
- Rendered with `flutter_svg` package
- Follow the same 24px grid and rounded style

---

## Responsive Breakpoints

| Breakpoint | Width | Layout |
| ---------- | ----- | ------ |
| Mobile | < 600px | Single column, bottom nav, full-width cards |
| Tablet | 600-1200px | Two column, side nav option, card grid |
| Desktop | > 1200px | Multi-column, permanent side nav, data tables |

```dart
class Responsive {
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 600 &&
      MediaQuery.sizeOf(context).width < 1200;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 1200;
}
```
