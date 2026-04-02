import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_strings.dart';

/// Shell widget for the restaurant owner role.
///
/// Wraps the child route's widget with a [Scaffold] containing a
/// [NavigationBar] (Material 3) with 4 tabs: Dashboard, Menu, Orders, Profile.
class RestaurantOwnerShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const RestaurantOwnerShell({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: NavigationBar(
            backgroundColor: Colors.transparent,
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) {
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            },
            indicatorColor: AppColors.primary.withValues(alpha: 0.15),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(
                  Icons.dashboard,
                  color: AppColors.primary,
                ),
                label: AppStrings.dashboard,
              ),
              NavigationDestination(
                icon: Icon(Icons.restaurant_menu_outlined),
                selectedIcon: Icon(
                  Icons.restaurant_menu,
                  color: AppColors.primary,
                ),
                label: AppStrings.menu,
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(
                  Icons.receipt_long,
                  color: AppColors.primary,
                ),
                label: AppStrings.orders,
              ),
              NavigationDestination(
                icon: Icon(Icons.storefront_outlined),
                selectedIcon: Icon(
                  Icons.storefront,
                  color: AppColors.primary,
                ),
                label: AppStrings.profile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
