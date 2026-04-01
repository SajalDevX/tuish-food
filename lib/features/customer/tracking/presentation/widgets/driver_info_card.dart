import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';

class DriverInfoCard extends StatelessWidget {
  const DriverInfoCard({
    super.key,
    required this.driverName,
    this.driverPhotoUrl,
    this.driverRating,
    this.driverPhone,
    this.onChatPressed,
  });

  final String driverName;
  final String? driverPhotoUrl;
  final double? driverRating;
  final String? driverPhone;
  final VoidCallback? onChatPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSizes.paddingAllM,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSizes.borderRadiusL,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
            backgroundImage: driverPhotoUrl != null
                ? NetworkImage(driverPhotoUrl!)
                : null,
            child: driverPhotoUrl == null
                ? const Icon(Icons.person, color: AppColors.primary)
                : null,
          ),

          const SizedBox(width: AppSizes.s12),

          // Name and rating
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  driverName,
                  style: AppTypography.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (driverRating != null) ...[
                  const SizedBox(height: AppSizes.s4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: AppColors.starFilled,
                      ),
                      const SizedBox(width: AppSizes.s4),
                      Text(
                        driverRating!.toStringAsFixed(1),
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Action buttons
          if (driverPhone != null)
            _ActionButton(
              icon: Icons.phone_rounded,
              onPressed: () => _makePhoneCall(driverPhone!),
            ),

          if (onChatPressed != null) ...[
            const SizedBox(width: AppSizes.s8),
            _ActionButton(
              icon: Icons.chat_bubble_outline_rounded,
              onPressed: onChatPressed!,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: AppColors.primary, size: 20),
        constraints: const BoxConstraints(
          minWidth: AppSizes.minTouchTarget,
          minHeight: AppSizes.minTouchTarget,
        ),
      ),
    );
  }
}
