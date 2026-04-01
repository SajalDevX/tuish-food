import 'package:flutter/material.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/enums/user_role.dart';
import 'package:tuish_food/features/auth/domain/entities/app_user.dart';

class UserActionsMenu extends StatelessWidget {
  const UserActionsMenu({
    super.key,
    required this.user,
    this.onBan,
    this.onUnban,
    this.onChangeRole,
    this.onVerify,
  });

  final AppUser user;
  final VoidCallback? onBan;
  final VoidCallback? onUnban;
  final ValueChanged<UserRole>? onChangeRole;
  final VoidCallback? onVerify;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onSelected: (value) {
        switch (value) {
          case 'ban':
            onBan?.call();
          case 'unban':
            onUnban?.call();
          case 'role_customer':
            onChangeRole?.call(UserRole.customer);
          case 'role_deliveryPartner':
            onChangeRole?.call(UserRole.deliveryPartner);
          case 'role_admin':
            onChangeRole?.call(UserRole.admin);
          case 'verify':
            onVerify?.call();
        }
      },
      itemBuilder: (context) => [
        // Ban / Unban
        if (user.isBanned)
          PopupMenuItem<String>(
            value: 'unban',
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    color: AppColors.success, size: 20),
                const SizedBox(width: 12),
                Text('Unban User',
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.success)),
              ],
            ),
          )
        else
          PopupMenuItem<String>(
            value: 'ban',
            child: Row(
              children: [
                const Icon(Icons.block, color: AppColors.error, size: 20),
                const SizedBox(width: 12),
                Text('Ban User',
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.error)),
              ],
            ),
          ),

        const PopupMenuDivider(),

        // Change role submenu items
        PopupMenuItem<String>(
          enabled: false,
          child: Text('Change Role',
              style: AppTypography.labelSmall
                  .copyWith(color: AppColors.textHint)),
        ),
        if (user.role != UserRole.customer)
          const PopupMenuItem<String>(
            value: 'role_customer',
            child: Row(
              children: [
                Icon(Icons.person_outline,
                    color: AppColors.info, size: 20),
                SizedBox(width: 12),
                Text('Customer'),
              ],
            ),
          ),
        if (user.role != UserRole.deliveryPartner)
          const PopupMenuItem<String>(
            value: 'role_deliveryPartner',
            child: Row(
              children: [
                Icon(Icons.delivery_dining,
                    color: AppColors.secondary, size: 20),
                SizedBox(width: 12),
                Text('Delivery Partner'),
              ],
            ),
          ),
        if (user.role != UserRole.admin)
          const PopupMenuItem<String>(
            value: 'role_admin',
            child: Row(
              children: [
                Icon(Icons.admin_panel_settings,
                    color: AppColors.primary, size: 20),
                SizedBox(width: 12),
                Text('Admin'),
              ],
            ),
          ),

        // Verify action for delivery partners
        if (user.role == UserRole.deliveryPartner) ...[
          const PopupMenuDivider(),
          PopupMenuItem<String>(
            value: 'verify',
            child: Row(
              children: [
                const Icon(Icons.verified,
                    color: AppColors.success, size: 20),
                const SizedBox(width: 12),
                Text('Verify Partner',
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.success)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
