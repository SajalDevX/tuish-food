import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_strings.dart';
import 'package:tuish_food/routing/route_paths.dart';

/// Shell widget for the admin role.
///
/// Wraps the child route's widget with a [Scaffold] containing a
/// side [Drawer] for navigation between admin sections: Dashboard,
/// Restaurants, Users, Delivery Partners, Orders, Promotions, Settings.
class AdminShell extends StatelessWidget {
  final Widget child;

  const AdminShell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titleForLocation(GoRouterState.of(context).uri.toString()),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: _AdminDrawer(
        currentLocation: GoRouterState.of(context).uri.toString(),
      ),
      body: child,
    );
  }

  /// Returns the appropriate title based on the current route.
  String _titleForLocation(String location) {
    if (location.startsWith(RoutePaths.adminRestaurants)) {
      return AppStrings.restaurants;
    }
    if (location.startsWith(RoutePaths.adminUsers)) {
      return AppStrings.users;
    }
    if (location.startsWith(RoutePaths.adminDeliveryPartners)) {
      return AppStrings.deliveryPartners;
    }
    if (location.startsWith(RoutePaths.adminOrders)) {
      return AppStrings.orders;
    }
    if (location.startsWith(RoutePaths.adminPromotions)) {
      return AppStrings.promotions;
    }
    if (location.startsWith(RoutePaths.adminSettings)) {
      return AppStrings.settings;
    }
    return AppStrings.dashboard;
  }
}

/// The navigation drawer for admin sections.
class _AdminDrawer extends StatelessWidget {
  final String currentLocation;

  const _AdminDrawer({required this.currentLocation});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(
                  Icons.admin_panel_settings,
                  color: AppColors.onPrimary,
                  size: 48,
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.appName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'Admin Panel',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onPrimary.withValues(alpha: 0.8),
                      ),
                ),
              ],
            ),
          ),
          _DrawerItem(
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard,
            label: AppStrings.dashboard,
            isSelected: currentLocation.startsWith(RoutePaths.adminDashboard),
            onTap: () {
              Navigator.pop(context);
              context.go(RoutePaths.adminDashboard);
            },
          ),
          _DrawerItem(
            icon: Icons.restaurant_outlined,
            selectedIcon: Icons.restaurant,
            label: AppStrings.restaurants,
            isSelected: currentLocation.startsWith(RoutePaths.adminRestaurants),
            onTap: () {
              Navigator.pop(context);
              context.go(RoutePaths.adminRestaurants);
            },
          ),
          _DrawerItem(
            icon: Icons.people_outlined,
            selectedIcon: Icons.people,
            label: AppStrings.users,
            isSelected: currentLocation.startsWith(RoutePaths.adminUsers),
            onTap: () {
              Navigator.pop(context);
              context.go(RoutePaths.adminUsers);
            },
          ),
          _DrawerItem(
            icon: Icons.delivery_dining_outlined,
            selectedIcon: Icons.delivery_dining,
            label: AppStrings.deliveryPartners,
            isSelected:
                currentLocation.startsWith(RoutePaths.adminDeliveryPartners),
            onTap: () {
              Navigator.pop(context);
              context.go(RoutePaths.adminDeliveryPartners);
            },
          ),
          _DrawerItem(
            icon: Icons.receipt_long_outlined,
            selectedIcon: Icons.receipt_long,
            label: AppStrings.orders,
            isSelected: currentLocation.startsWith(RoutePaths.adminOrders),
            onTap: () {
              Navigator.pop(context);
              context.go(RoutePaths.adminOrders);
            },
          ),
          _DrawerItem(
            icon: Icons.local_offer_outlined,
            selectedIcon: Icons.local_offer,
            label: AppStrings.promotions,
            isSelected: currentLocation.startsWith(RoutePaths.adminPromotions),
            onTap: () {
              Navigator.pop(context);
              context.go(RoutePaths.adminPromotions);
            },
          ),
          const Divider(),
          _DrawerItem(
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings,
            label: AppStrings.settings,
            isSelected: currentLocation.startsWith(RoutePaths.adminSettings),
            onTap: () {
              Navigator.pop(context);
              context.go(RoutePaths.adminSettings);
            },
          ),
        ],
      ),
    );
  }
}

/// A single item in the admin drawer.
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        isSelected ? selectedIcon : icon,
        color: isSelected ? AppColors.primary : null,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppColors.primary : null,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onTap: onTap,
    );
  }
}
