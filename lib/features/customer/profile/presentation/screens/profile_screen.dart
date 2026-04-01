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
import 'package:tuish_food/features/customer/profile/presentation/widgets/profile_avatar.dart';
import 'package:tuish_food/injection_container.dart';
import 'package:tuish_food/routing/route_names.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final displayName = currentUser?.displayName ?? 'User';
    final email = currentUser?.email;
    final phone = currentUser?.phoneNumber;
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

            // Avatar and info
            ProfileAvatar(
              imageUrl: photoUrl,
              name: displayName,
              radius: AppSizes.avatarXL / 2,
            ),
            const SizedBox(height: AppSizes.s16),
            Text(
              displayName,
              style: AppTypography.headlineSmall,
            ),
            if (email != null) ...[
              const SizedBox(height: AppSizes.s4),
              Text(
                email,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (phone != null) ...[
              const SizedBox(height: AppSizes.s4),
              Text(
                phone,
                style: AppTypography.bodySmall,
              ),
            ],

            const SizedBox(height: AppSizes.s32),

            // Menu items
            _ProfileMenuItem(
              icon: Icons.person_outline,
              title: 'Edit Profile',
              onTap: () => context.pushNamed(RouteNames.editProfile),
            ),
            _ProfileMenuItem(
              icon: Icons.location_on_outlined,
              title: 'Saved Addresses',
              onTap: () => context.pushNamed(RouteNames.addresses),
            ),
            _ProfileMenuItem(
              icon: Icons.notifications_outlined,
              title: AppStrings.notifications,
              onTap: () =>
                  context.pushNamed(RouteNames.customerNotifications),
            ),
            _ProfileMenuItem(
              icon: Icons.settings_outlined,
              title: AppStrings.settings,
              onTap: () =>
                  context.pushNamed(RouteNames.customerSettings),
            ),

            const SizedBox(height: AppSizes.s16),
            const Divider(
              indent: AppSizes.s16,
              endIndent: AppSizes.s16,
              color: AppColors.divider,
            ),
            const SizedBox(height: AppSizes.s8),

            _ProfileMenuItem(
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Help & Support coming soon'),
                  ),
                );
              },
            ),
            _ProfileMenuItem(
              icon: Icons.info_outline,
              title: 'About',
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: AppStrings.appName,
                  applicationVersion: '1.0.0',
                  applicationLegalese: '2026 Tuish Food',
                );
              },
            ),

            const SizedBox(height: AppSizes.s16),
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
