import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_strings.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/enums/user_role.dart';
import 'package:tuish_food/core/widgets/confirmation_dialog.dart';
import 'package:tuish_food/core/widgets/tuish_app_bar.dart';
import 'package:tuish_food/core/widgets/tuish_button.dart';
import 'package:tuish_food/features/admin/user_management/presentation/providers/user_management_provider.dart';
import 'package:tuish_food/features/admin/user_management/presentation/widgets/user_actions_menu.dart';

class UserDetailScreen extends ConsumerWidget {
  const UserDetailScreen({
    super.key,
    required this.userId,
  });

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userDetailProvider(userId));
    final banState = ref.watch(banUserProvider);

    return Scaffold(
      appBar: TuishAppBar(
        title: 'User Detail',
        actions: [
          userAsync.whenOrNull(
                data: (user) => UserActionsMenu(
                  user: user,
                  onBan: () => _handleBan(context, ref),
                  onUnban: () => _handleUnban(context, ref),
                  onChangeRole: (role) =>
                      _handleChangeRole(context, ref, role),
                  onVerify: () => _handleVerify(context, ref),
                ),
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text(
            'Failed to load user: $e',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.error,
            ),
          ),
        ),
        data: (user) {
          final dateFormat = DateFormat('MMM dd, yyyy');

          return SingleChildScrollView(
            padding: AppSizes.paddingAllM,
            child: Column(
              children: [
                const SizedBox(height: AppSizes.s16),

                // Avatar
                CircleAvatar(
                  radius: AppSizes.avatarXL / 2,
                  backgroundColor:
                      AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: user.photoUrl != null
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null
                      ? Icon(
                          Icons.person,
                          size: AppSizes.avatarXL / 2,
                          color: AppColors.primary,
                        )
                      : null,
                ),
                const SizedBox(height: AppSizes.s16),

                // Name
                Text(
                  user.displayName ?? 'Unknown',
                  style: AppTypography.headlineSmall,
                ),
                const SizedBox(height: AppSizes.s4),

                // Role badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.s12,
                    vertical: AppSizes.s4,
                  ),
                  decoration: BoxDecoration(
                    color: _roleColor(user.role).withValues(alpha: 0.1),
                    borderRadius: AppSizes.borderRadiusPill,
                  ),
                  child: Text(
                    user.role.displayName,
                    style: AppTypography.labelMedium.copyWith(
                      color: _roleColor(user.role),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // Ban indicator
                if (user.isBanned) ...[
                  const SizedBox(height: AppSizes.s8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.s12,
                      vertical: AppSizes.s4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: AppSizes.borderRadiusPill,
                    ),
                    child: Text(
                      'BANNED',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: AppSizes.s32),

                // Info rows
                _InfoRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: user.email ?? 'Not provided',
                ),
                _InfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: user.phone ?? 'Not provided',
                ),
                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Joined',
                  value: user.createdAt != null
                      ? dateFormat.format(user.createdAt!)
                      : 'Unknown',
                ),
                _InfoRow(
                  icon: Icons.verified_user_outlined,
                  label: 'Status',
                  value: user.isActive ? 'Active' : 'Inactive',
                ),

                const SizedBox(height: AppSizes.s32),

                // Action buttons
                if (user.isBanned)
                  TuishButton.secondary(
                    label: 'Unban User',
                    isLoading: banState.isLoading,
                    icon: const Icon(Icons.check_circle_outline,
                        color: AppColors.onSecondary, size: 20),
                    onPressed: () => _handleUnban(context, ref),
                  )
                else
                  TuishButton.outlined(
                    label: 'Ban User',
                    isLoading: banState.isLoading,
                    icon: const Icon(Icons.block,
                        color: AppColors.primary, size: 20),
                    onPressed: () => _handleBan(context, ref),
                  ),

                const SizedBox(height: AppSizes.s16),

                // Change role dropdown
                Text('Change Role', style: AppTypography.titleSmall),
                const SizedBox(height: AppSizes.s8),
                DropdownButtonFormField<UserRole>(
                  initialValue: user.role,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: AppSizes.borderRadiusM,
                      borderSide:
                          const BorderSide(color: AppColors.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppSizes.borderRadiusM,
                      borderSide:
                          const BorderSide(color: AppColors.divider),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.s16,
                      vertical: AppSizes.s12,
                    ),
                  ),
                  items: UserRole.values
                      .map((role) => DropdownMenuItem(
                            value: role,
                            child: Text(role.displayName,
                                style: AppTypography.bodyLarge),
                          ))
                      .toList(),
                  onChanged: (role) {
                    if (role != null && role != user.role) {
                      _handleChangeRole(context, ref, role);
                    }
                  },
                ),

                const SizedBox(height: AppSizes.s48),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _roleColor(UserRole role) {
    return switch (role) {
      UserRole.admin => AppColors.primary,
      UserRole.deliveryPartner => AppColors.secondary,
      UserRole.restaurantOwner => AppColors.warning,
      UserRole.customer => AppColors.info,
    };
  }

  Future<void> _handleBan(BuildContext context, WidgetRef ref) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Ban User',
      message:
          'Are you sure you want to ban this user? They will not be able to access the app.',
      confirmLabel: 'Ban',
      cancelLabel: AppStrings.cancel,
    );
    if (confirmed == true) {
      final success =
          await ref.read(banUserProvider.notifier).banUser(userId);
      if (context.mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User has been banned'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _handleUnban(BuildContext context, WidgetRef ref) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Unban User',
      message: 'Are you sure you want to unban this user?',
      confirmLabel: 'Unban',
      cancelLabel: AppStrings.cancel,
    );
    if (confirmed == true) {
      final success =
          await ref.read(banUserProvider.notifier).unbanUser(userId);
      if (context.mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User has been unbanned'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _handleChangeRole(
    BuildContext context,
    WidgetRef ref,
    UserRole role,
  ) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Change Role',
      message:
          'Are you sure you want to change this user\'s role to ${role.displayName}?',
      confirmLabel: AppStrings.confirm,
      cancelLabel: AppStrings.cancel,
    );
    if (confirmed == true) {
      final success = await ref
          .read(updateRoleProvider.notifier)
          .updateRole(userId, role);
      if (context.mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Role updated to ${role.displayName}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _handleVerify(BuildContext context, WidgetRef ref) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Verify Partner',
      message:
          'Are you sure you want to verify this delivery partner?',
      confirmLabel: 'Verify',
      cancelLabel: AppStrings.cancel,
    );
    if (confirmed == true) {
      final success =
          await ref.read(verifyPartnerProvider.notifier).verify(userId);
      if (context.mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Delivery partner verified'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.s8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: AppSizes.iconM),
          const SizedBox(width: AppSizes.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.bodySmall),
                const SizedBox(height: 2),
                Text(value, style: AppTypography.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
