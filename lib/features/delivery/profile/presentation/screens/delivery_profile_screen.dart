import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_strings.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/widgets/confirmation_dialog.dart';
import 'package:tuish_food/core/widgets/tuish_app_bar.dart';
import 'package:tuish_food/features/auth/presentation/providers/auth_provider.dart';
import 'package:tuish_food/features/delivery/profile/presentation/widgets/online_toggle.dart';
import 'package:tuish_food/injection_container.dart';
import 'package:tuish_food/routing/route_paths.dart';

class DeliveryProfileScreen extends ConsumerWidget {
  const DeliveryProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final displayName = currentUser?.displayName ?? 'Delivery Partner';
    final email = currentUser?.email;
    final photoUrl = currentUser?.photoURL;

    return Scaffold(
      appBar: const TuishAppBar(
        title: AppStrings.profile,
        showBackButton: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: AppSizes.s24),

            // Profile avatar
            CircleAvatar(
              radius: AppSizes.avatarXL / 2,
              backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
              backgroundImage:
                  photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null
                  ? Icon(
                      Icons.person,
                      size: AppSizes.avatarXL / 2,
                      color: AppColors.secondary,
                    )
                  : null,
            ),
            const SizedBox(height: AppSizes.s16),

            // Name
            Text(displayName, style: AppTypography.headlineSmall),
            if (email != null) ...[
              const SizedBox(height: AppSizes.s4),
              Text(
                email,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: AppSizes.s16),

            // Rating and total deliveries row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StatChip(
                  icon: Icons.star_rounded,
                  iconColor: AppColors.starFilled,
                  label: '4.8',
                  subtitle: 'Rating',
                ),
                const SizedBox(width: AppSizes.s24),
                _StatChip(
                  icon: Icons.delivery_dining,
                  iconColor: AppColors.secondary,
                  label: '156',
                  subtitle: 'Deliveries',
                ),
              ],
            ),
            const SizedBox(height: AppSizes.s24),

            // Online toggle
            Padding(
              padding: AppSizes.paddingHorizontalM,
              child: const OnlineToggle(),
            ),

            const SizedBox(height: AppSizes.s24),
            const Divider(
              indent: AppSizes.s16,
              endIndent: AppSizes.s16,
              color: AppColors.divider,
            ),
            const SizedBox(height: AppSizes.s8),

            // Menu items
            _ProfileMenuItem(
              icon: Icons.directions_car_outlined,
              title: 'Vehicle Info',
              onTap: () => context.push('/delivery/profile/vehicle-info'),
            ),
            _ProfileMenuItem(
              icon: Icons.description_outlined,
              title: 'Documents',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Documents coming soon')),
                );
              },
            ),
            _ProfileMenuItem(
              icon: Icons.account_balance_wallet_outlined,
              title: AppStrings.earnings,
              onTap: () => context.go(RoutePaths.deliveryEarnings),
            ),
            _ProfileMenuItem(
              icon: Icons.settings_outlined,
              title: AppStrings.settings,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings coming soon')),
                );
              },
            ),

            const SizedBox(height: AppSizes.s8),
            const Divider(
              indent: AppSizes.s16,
              endIndent: AppSizes.s16,
              color: AppColors.divider,
            ),
            const SizedBox(height: AppSizes.s8),

            _ProfileMenuItem(
              icon: Icons.logout_rounded,
              title: AppStrings.signOut,
              iconColor: AppColors.error,
              titleColor: AppColors.error,
              onTap: () => _handleSignOut(context, ref),
            ),

            const SizedBox(height: AppSizes.s48),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Sign Out',
      message: 'Are you sure you want to sign out?',
      confirmLabel: 'Sign Out',
      cancelLabel: AppStrings.cancel,
    );

    if (confirmed == true) {
      ref.read(authNotifierProvider.notifier).signOut();
    }
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: AppSizes.iconM),
            const SizedBox(width: AppSizes.s4),
            Text(label, style: AppTypography.titleLarge),
          ],
        ),
        const SizedBox(height: AppSizes.s4),
        Text(
          subtitle,
          style: AppTypography.bodySmall,
        ),
      ],
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
    this.titleColor,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: AppSizes.s24),
      leading: Icon(
        icon,
        color: iconColor ?? AppColors.textSecondary,
        size: AppSizes.iconM,
      ),
      title: Text(
        title,
        style: AppTypography.bodyLarge.copyWith(
          color: titleColor ?? AppColors.textPrimary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: iconColor ?? AppColors.textHint,
      ),
      onTap: onTap,
    );
  }
}
