import 'package:flutter/material.dart';

import 'package:tuish_food/core/constants/app_colors.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.radius = 48,
    this.showEditIcon = false,
    this.onEditTap,
  });

  final String? imageUrl;
  final String? name;
  final double radius;
  final bool showEditIcon;
  final VoidCallback? onEditTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
          backgroundImage:
              imageUrl != null ? NetworkImage(imageUrl!) : null,
          child: imageUrl == null
              ? Text(
                  _initials,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: radius * 0.6,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : null,
        ),
        if (showEditIcon)
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: onEditTap,
              child: Container(
                width: radius * 0.6,
                height: radius * 0.6,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.surface,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  size: radius * 0.3,
                  color: AppColors.onPrimary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  String get _initials {
    if (name == null || name!.isEmpty) return 'U';
    final parts = name!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }
}
