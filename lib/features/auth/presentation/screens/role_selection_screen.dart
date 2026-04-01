import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/routing/route_paths.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_strings.dart';
import 'package:tuish_food/core/enums/user_role.dart';
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
          case UserRole.admin:
            context.go(RoutePaths.adminDashboard);
        }
      }
    });

    return Scaffold(
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
                style: theme.textTheme.headlineMedium,
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
              _RoleCard(
                icon: Icons.restaurant_menu,
                title: AppStrings.iWantToOrder,
                subtitle: 'Browse restaurants, order food, and get it delivered',
                color: AppColors.primary,
                isLoading: isLoading,
                onTap: () {
                  if (authState is Authenticated) {
                    ref.read(authNotifierProvider.notifier).updateUserRole(
                          authState.user.uid,
                          UserRole.customer,
                        );
                  }
                },
              ),

              const SizedBox(height: AppSizes.s20),

              // Delivery partner card
              _RoleCard(
                icon: Icons.delivery_dining,
                title: AppStrings.iWantToDeliver,
                subtitle: 'Deliver food orders and earn money on your schedule',
                color: AppColors.secondary,
                isLoading: isLoading,
                onTap: () {
                  if (authState is Authenticated) {
                    ref.read(authNotifierProvider.notifier).updateUserRole(
                          authState.user.uid,
                          UserRole.deliveryPartner,
                        );
                  }
                },
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
    final theme = Theme.of(context);

    return Card(
      elevation: AppSizes.elevationFloating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
      ),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.s24),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(width: AppSizes.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSizes.s4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: AppSizes.iconS,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
