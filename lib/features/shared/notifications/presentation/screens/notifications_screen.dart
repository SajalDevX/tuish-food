import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_strings.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/widgets/empty_state_widget.dart';
import 'package:tuish_food/core/widgets/tuish_app_bar.dart';
import 'package:tuish_food/features/shared/notifications/presentation/providers/notifications_provider.dart';
import 'package:tuish_food/features/shared/notifications/presentation/widgets/notification_tile.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(userNotificationsProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: TuishAppBar(
        title: AppStrings.notifications,
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () {
                ref.read(markAllNotificationsReadProvider).call();
              },
              child: Text(
                'Mark all read',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const EmptyStateWidget(
              message: 'No notifications yet',
              icon: Icons.notifications_none_rounded,
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(userNotificationsProvider);
            },
            child: _buildGroupedList(ref, notifications),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: AppSizes.iconXL,
                color: AppColors.error,
              ),
              const SizedBox(height: AppSizes.s16),
              Text(
                AppStrings.somethingWentWrong,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSizes.s16),
              TextButton(
                onPressed: () => ref.invalidate(userNotificationsProvider),
                child: const Text(AppStrings.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupedList(
    WidgetRef ref,
    List<AppNotification> notifications,
  ) {
    // Split into Today and Earlier groups
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final todayNotifications = <AppNotification>[];
    final earlierNotifications = <AppNotification>[];

    for (final notification in notifications) {
      final createdAt = notification['createdAt'] as DateTime? ?? DateTime.now();
      if (createdAt.isAfter(todayStart)) {
        todayNotifications.add(notification);
      } else {
        earlierNotifications.add(notification);
      }
    }

    return ListView(
      children: [
        if (todayNotifications.isNotEmpty) ...[
          _buildSectionHeader('Today'),
          ...todayNotifications.map(
            (n) => _buildNotificationTile(ref, n),
          ),
        ],
        if (earlierNotifications.isNotEmpty) ...[
          _buildSectionHeader('Earlier'),
          ...earlierNotifications.map(
            (n) => _buildNotificationTile(ref, n),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.s16,
        vertical: AppSizes.s8,
      ),
      child: Text(
        title,
        style: AppTypography.labelLarge.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildNotificationTile(WidgetRef ref, AppNotification notification) {
    return Column(
      children: [
        NotificationTile(
          notification: notification,
          onTap: () => _handleNotificationTap(ref, notification),
        ),
        const Divider(
          height: 1,
          indent: AppSizes.s16 + 44 + AppSizes.s12, // icon offset
          color: AppColors.divider,
        ),
      ],
    );
  }

  void _handleNotificationTap(
    WidgetRef ref,
    AppNotification notification,
  ) {
    final isRead = notification['isRead'] as bool? ?? false;
    final notificationId = notification['id'] as String? ?? '';

    // Mark as read if unread
    if (!isRead && notificationId.isNotEmpty) {
      ref.read(markNotificationReadProvider).call(notificationId);
    }

    // Navigate based on notification type
    final type = notification['type'] as String? ?? '';
    final data = notification['data'] as Map<String, dynamic>? ?? {};
    final context = ref.context;

    switch (type) {
      case 'order_update':
        final orderId = data['orderId'] as String?;
        if (orderId != null && context.mounted) {
          // Navigate to order detail - uses GoRouter context extension
          // context.push('/orders/$orderId');
        }
      case 'chat':
        final chatId = data['chatId'] as String?;
        if (chatId != null && context.mounted) {
          // context.push('/chat/$chatId');
        }
      case 'promotion':
        final promotionId = data['promotionId'] as String?;
        if (promotionId != null && context.mounted) {
          // context.push('/promotions/$promotionId');
        }
      case 'earnings':
        if (context.mounted) {
          // context.push('/earnings');
        }
      default:
        break;
    }
  }
}
