import 'package:flutter/material.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/extensions/datetime_extensions.dart';
import 'package:tuish_food/features/shared/notifications/presentation/providers/notifications_provider.dart';

class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    this.onTap,
  });

  final AppNotification notification;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool isRead = notification['isRead'] as bool? ?? false;
    final String type = notification['type'] as String? ?? 'system';
    final String title = notification['title'] as String? ?? '';
    final String body = notification['body'] as String? ?? '';
    final DateTime createdAt =
        notification['createdAt'] as DateTime? ?? DateTime.now();

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isRead
            ? AppColors.surface
            : AppColors.primary.withValues(alpha: 0.04),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.s16,
          vertical: AppSizes.s12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            _buildIcon(type, isRead),

            const SizedBox(width: AppSizes.s12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row with unread dot
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight:
                                isRead ? FontWeight.w500 : FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!isRead) ...[
                        const SizedBox(width: AppSizes.s8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: AppSizes.s4),

                  // Body
                  Text(
                    body,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: AppSizes.s4),

                  // Timestamp
                  Text(
                    createdAt.timeAgo,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textHint,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(String type, bool isRead) {
    final IconData iconData;
    final Color iconColor;

    switch (type) {
      case 'order_update':
        iconData = Icons.receipt_long_rounded;
        iconColor = AppColors.info;
      case 'promotion':
        iconData = Icons.local_offer_rounded;
        iconColor = AppColors.warning;
      case 'chat':
        iconData = Icons.chat_bubble_rounded;
        iconColor = AppColors.secondary;
      case 'earnings':
        iconData = Icons.account_balance_wallet_rounded;
        iconColor = AppColors.success;
      case 'system':
      default:
        iconData = Icons.info_rounded;
        iconColor = AppColors.textSecondary;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: AppSizes.borderRadiusM,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: AppSizes.iconM,
      ),
    );
  }
}
