import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/widgets/glass_scaffold.dart';
import 'package:tuish_food/core/widgets/tuish_card.dart';
import 'package:tuish_food/routing/route_paths.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_strings.dart';
import 'package:tuish_food/core/enums/user_role.dart';
import 'package:tuish_food/core/widgets/staggered_fade_slide.dart';
import 'package:tuish_food/features/auth/presentation/providers/auth_provider.dart';
import 'package:tuish_food/features/auth/presentation/providers/auth_state.dart';

class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  static const String routeName = 'role-selection';
  static const String routePath = '/role-selection';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoading;
    final theme = Theme.of(context);

    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: AppColors.error,
          ),
        );
      } else if (next is Authenticated) {
        final role = next.user.role;
        switch (role) {
          case UserRole.customer:
            context.go(RoutePaths.customerHome);
          case UserRole.deliveryPartner:
            context.go(RoutePaths.deliveryHome);
          case UserRole.restaurantOwner:
            context.go(RoutePaths.restaurantDashboard);
          case UserRole.admin:
            context.go(RoutePaths.adminDashboard);
        }
      }
    });

    return GlassScaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSizes.paddingAllL,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSizes.s64),

              // Header
              Text(
                AppStrings.selectRole,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.s12),
              Text(
                'Choose your role to get started',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSizes.s48),

              // Customer card
              StaggeredFadeSlide(
                index: 0,
                delay: const Duration(milliseconds: 150),
                child: _RoleCard(
                  icon: Icons.restaurant_menu,
                  title: AppStrings.iWantToOrder,
                  subtitle:
                      'Browse restaurants, order food, and get it delivered',
                  color: AppColors.primary,
                  isLoading: isLoading,
                  onTap: () {
                    if (authState is Authenticated) {
                      ref
                          .read(authNotifierProvider.notifier)
                          .updateUserRole(
                            authState.user.uid,
                            UserRole.customer,
                          );
                    }
                  },
                ),
              ),

              const SizedBox(height: AppSizes.s16),

              // Restaurant owner card
              StaggeredFadeSlide(
                index: 1,
                delay: const Duration(milliseconds: 150),
                child: _RoleCard(
                  icon: Icons.storefront_rounded,
                  title: 'I Own a Restaurant',
                  subtitle: 'Register your restaurant and manage orders',
                  color: AppColors.warning,
                  isLoading: isLoading,
                  onTap: () {
                    if (authState is Authenticated) {
                      ref
                          .read(authNotifierProvider.notifier)
                          .updateUserRole(
                            authState.user.uid,
                            UserRole.restaurantOwner,
                          );
                    }
                  },
                ),
              ),

              const SizedBox(height: AppSizes.s16),

              // Delivery partner card
              StaggeredFadeSlide(
                index: 2,
                delay: const Duration(milliseconds: 150),
                child: _RoleCard(
                  icon: Icons.delivery_dining,
                  title: AppStrings.iWantToDeliver,
                  subtitle:
                      'Deliver food orders and earn money on your schedule',
                  color: AppColors.secondary,
                  isLoading: isLoading,
                  onTap: () {
                    if (authState is Authenticated) {
                      ref
                          .read(authNotifierProvider.notifier)
                          .updateUserRole(
                            authState.user.uid,
                            UserRole.deliveryPartner,
                          );
                    }
                  },
                ),
              ),

              const Spacer(),

              // Sign out option
              TextButton.icon(
                onPressed: isLoading
                    ? null
                    : () {
                        ref.read(authNotifierProvider.notifier).signOut();
                        context.go(RoutePaths.login);
                      },
                icon: const Icon(Icons.logout),
                label: const Text(AppStrings.signOut),
              ),

              const SizedBox(height: AppSizes.s16),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isLoading;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TuishCard(
      onTap: isLoading ? null : onTap,
      padding: const EdgeInsets.all(AppSizes.s24),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
            ),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(width: AppSizes.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSizes.s4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.glassTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: AppSizes.iconS,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.glassTextSecondary
                : AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}
