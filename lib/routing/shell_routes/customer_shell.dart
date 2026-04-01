import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_strings.dart';

/// Shell widget for the customer role.
///
/// Wraps the child route's widget with a [Scaffold] containing a
/// [NavigationBar] (Material 3) with 4 tabs: Home, Orders, Cart, Profile.
class CustomerShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const CustomerShell({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
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
            icon: Icon(Icons.restaurant_outlined),
            selectedIcon: Icon(
              Icons.restaurant,
              color: AppColors.primary,
            ),
            label: AppStrings.home,
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(
              Icons.receipt_long,
              color: AppColors.primary,
            ),
            label: AppStrings.myOrders,
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(
              Icons.shopping_cart,
              color: AppColors.primary,
            ),
            label: AppStrings.cart,
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(
              Icons.person,
              color: AppColors.primary,
            ),
            label: AppStrings.profile,
          ),
        ],
      ),
    );
  }
}
