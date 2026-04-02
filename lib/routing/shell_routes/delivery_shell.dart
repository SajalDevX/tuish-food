import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_strings.dart';

/// Shell widget for the delivery partner role.
///
/// Wraps the child route's widget with a [Scaffold] containing a
/// [NavigationBar] (Material 3) with 4 tabs: Home, Orders, Earnings, Profile.
class DeliveryShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const DeliveryShell({
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
            indicatorColor: AppColors.secondary.withValues(alpha: 0.15),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.delivery_dining_outlined),
                selectedIcon: Icon(
                  Icons.delivery_dining,
                  color: AppColors.secondary,
                ),
                label: AppStrings.home,
              ),
              NavigationDestination(
                icon: Icon(Icons.list_alt_outlined),
                selectedIcon: Icon(
                  Icons.list_alt,
                  color: AppColors.secondary,
                ),
                label: AppStrings.orders,
              ),
              NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: Icon(
                  Icons.account_balance_wallet,
                  color: AppColors.secondary,
                ),
                label: AppStrings.earnings,
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outlined),
                selectedIcon: Icon(
                  Icons.person,
                  color: AppColors.secondary,
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
