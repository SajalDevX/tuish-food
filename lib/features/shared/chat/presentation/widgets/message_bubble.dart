import 'package:flutter/material.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/widgets/cached_image.dart';
import 'package:tuish_food/features/shared/chat/domain/entities/message.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isSentByMe,
    this.showTail = true,
  });

  final Message message;
  final bool isSentByMe;
  final bool showTail;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth * 0.75;

    return Padding(
      padding: EdgeInsets.only(
        left: isSentByMe ? 60 : AppSizes.s12,
        right: isSentByMe ? AppSizes.s12 : 60,
        top: showTail ? AppSizes.s8 : AppSizes.s4,
        bottom: 0,
      ),
      child: Align(
        alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            decoration: BoxDecoration(
              color: isSentByMe ? AppColors.primary : AppColors.background,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(AppSizes.radiusL),
                topRight: const Radius.circular(AppSizes.radiusL),
                bottomLeft: Radius.circular(
                  isSentByMe || !showTail
                      ? AppSizes.radiusL
                      : AppSizes.s4,
                ),
                bottomRight: Radius.circular(
                  !isSentByMe || !showTail
                      ? AppSizes.radiusL
                      : AppSizes.s4,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.s12,
                vertical: AppSizes.s8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Optional image
                  if (message.imageUrl != null &&
                      message.imageUrl!.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: AppSizes.borderRadiusM,
                      child: CachedImage(
                        imageUrl: message.imageUrl!,
                        width: maxWidth - AppSizes.s24,
                        height: 180,
                        fit: BoxFit.cover,
                        borderRadius: AppSizes.borderRadiusM,
                      ),
                    ),
                    const SizedBox(height: AppSizes.s4),
                  ],

                  // Message text
                  if (message.text.isNotEmpty)
                    Text(
                      message.text,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isSentByMe
                            ? AppColors.onPrimary
                            : AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),

                  const SizedBox(height: AppSizes.s4),

                  // Timestamp + read indicator
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.createdAt),
                        style: AppTypography.labelSmall.copyWith(
                          color: isSentByMe
                              ? AppColors.onPrimary.withValues(alpha: 0.7)
                              : AppColors.textHint,
                          fontSize: 10,
                        ),
                      ),
                      if (isSentByMe) ...[
                        const SizedBox(width: 3),
                        Icon(
                          message.isRead
                              ? Icons.done_all_rounded
                              : Icons.done_rounded,
                          size: 14,
                          color: message.isRead
                              ? (isSentByMe
                                  ? Colors.lightBlueAccent.shade100
                                  : AppColors.info)
                              : (isSentByMe
                                  ? AppColors.onPrimary.withValues(alpha: 0.7)
                                  : AppColors.textHint),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0
        ? 12
        : hour > 12
            ? hour - 12
            : hour;
    return '$displayHour:$minute $period';
  }
}
