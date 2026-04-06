import 'package:flutter/material.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/features/auth/domain/entities/app_user.dart';

class UserTableRow extends StatelessWidget {
  const UserTableRow({
    super.key,
    required this.user,
    this.onTap,
  });

  final AppUser user;
  final VoidCallback? onTap;

  Color _roleColor() {
    return switch (user.role?.claimValue) {
      'admin' => AppColors.primary,
      'deliveryPartner' => AppColors.secondary,
      _ => AppColors.info,
    };
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.s16,
        vertical: AppSizes.s4,
      ),
      leading: CircleAvatar(
        radius: AppSizes.avatarS / 2,
        backgroundColor: _roleColor().withValues(alpha: 0.1),
        backgroundImage:
            user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
        child: user.photoUrl == null
            ? Text(
                (user.displayName?.isNotEmpty == true)
                    ? user.displayName![0].toUpperCase()
                    : '?',
                style: AppTypography.titleSmall.copyWith(
                  color: _roleColor(),
                ),
              )
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              user.displayName ?? 'Unknown',
              style: AppTypography.titleSmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSizes.s8),
          // Role chip
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.s8,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: _roleColor().withValues(alpha: 0.1),
              borderRadius: AppSizes.borderRadiusPill,
            ),
            child: Text(
              user.role?.displayName ?? 'No Role',
              style: AppTypography.labelSmall.copyWith(
                color: _roleColor(),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              user.email ?? user.phone ?? 'No contact',
              style: AppTypography.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (user.isBanned)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.s8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: AppSizes.borderRadiusPill,
              ),
              child: Text(
                'Banned',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.textHint,
      ),
    );
  }
}
