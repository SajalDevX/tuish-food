import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_strings.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/widgets/confirmation_dialog.dart';
import 'package:tuish_food/core/widgets/tuish_app_bar.dart';

/// Notifier for dark mode preference.
class DarkModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void update(bool value) {
    state = value;
  }
}

final darkModeProvider =
    NotifierProvider<DarkModeNotifier, bool>(DarkModeNotifier.new);

/// Notifier for notification preferences.
class NotificationsEnabledNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void update(bool value) {
    state = value;
  }
}

final notificationsEnabledProvider =
    NotifierProvider<NotificationsEnabledNotifier, bool>(
        NotificationsEnabledNotifier.new);

/// Notifier for order update notifications.
class OrderUpdatesEnabledNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void update(bool value) {
    state = value;
  }
}

final orderUpdatesEnabledProvider =
    NotifierProvider<OrderUpdatesEnabledNotifier, bool>(
        OrderUpdatesEnabledNotifier.new);

/// Notifier for promotional notifications.
class PromoNotificationsNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void update(bool value) {
    state = value;
  }
}

final promoNotificationsProvider =
    NotifierProvider<PromoNotificationsNotifier, bool>(
        PromoNotificationsNotifier.new);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(darkModeProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);
    final orderUpdates = ref.watch(orderUpdatesEnabledProvider);
    final promoNotifications = ref.watch(promoNotificationsProvider);

    return Scaffold(
      appBar: const TuishAppBar(title: AppStrings.settings),
      body: ListView(
        children: [
          // Appearance section
          _SectionHeader(title: 'Appearance'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Toggle dark theme'),
            secondary: Icon(
              isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: AppColors.primary,
            ),
            value: isDarkMode,
            activeTrackColor: AppColors.primary,
            onChanged: (val) {
              ref.read(darkModeProvider.notifier).update(val);
            },
          ),

          const Divider(indent: AppSizes.s16, endIndent: AppSizes.s16),

          // Notifications section
          _SectionHeader(title: 'Notifications'),
          SwitchListTile(
            title: const Text('Push Notifications'),
            subtitle: const Text('Enable or disable all notifications'),
            secondary: const Icon(
              Icons.notifications_outlined,
              color: AppColors.primary,
            ),
            value: notificationsEnabled,
            activeTrackColor: AppColors.primary,
            onChanged: (val) {
              ref.read(notificationsEnabledProvider.notifier).update(val);
            },
          ),
          SwitchListTile(
            title: const Text('Order Updates'),
            subtitle: const Text('Get notified about order status changes'),
            value: orderUpdates && notificationsEnabled,
            activeTrackColor: AppColors.primary,
            onChanged: notificationsEnabled
                ? (val) {
                    ref.read(orderUpdatesEnabledProvider.notifier).update(
                        val);
                  }
                : null,
          ),
          SwitchListTile(
            title: const Text('Promotions & Offers'),
            subtitle:
                const Text('Receive promotional offers and discounts'),
            value: promoNotifications && notificationsEnabled,
            activeTrackColor: AppColors.primary,
            onChanged: notificationsEnabled
                ? (val) {
                    ref.read(promoNotificationsProvider.notifier).update(
                        val);
                  }
                : null,
          ),

          const Divider(indent: AppSizes.s16, endIndent: AppSizes.s16),

          // General section
          _SectionHeader(title: 'General'),
          ListTile(
            leading: const Icon(Icons.language, color: AppColors.primary),
            title: const Text('Language'),
            subtitle: const Text('English'),
            trailing: const Icon(Icons.chevron_right,
                color: AppColors.textHint),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Language settings coming soon'),
                ),
              );
            },
          ),
          ListTile(
            leading:
                const Icon(Icons.info_outline, color: AppColors.primary),
            title: const Text('About'),
            subtitle: const Text('Version 1.0.0'),
            trailing: const Icon(Icons.chevron_right,
                color: AppColors.textHint),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: AppStrings.appName,
                applicationVersion: '1.0.0',
                applicationLegalese: '2026 Tuish Food',
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined,
                color: AppColors.primary),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.chevron_right,
                color: AppColors.textHint),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Terms of Service coming soon'),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined,
                color: AppColors.primary),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right,
                color: AppColors.textHint),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Privacy Policy coming soon'),
                ),
              );
            },
          ),

          const Divider(indent: AppSizes.s16, endIndent: AppSizes.s16),

          // Danger zone
          _SectionHeader(title: 'Danger Zone'),
          ListTile(
            leading: const Icon(Icons.delete_forever_outlined,
                color: AppColors.error),
            title: Text(
              'Delete Account',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.error,
              ),
            ),
            subtitle: const Text('Permanently delete your account'),
            onTap: () => _handleDeleteAccount(context),
          ),

          const SizedBox(height: AppSizes.s48),
        ],
      ),
    );
  }

  Future<void> _handleDeleteAccount(BuildContext context) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Account',
      message:
          'This action is permanent and cannot be undone. All your data including orders, reviews, and saved addresses will be permanently deleted.',
      confirmLabel: 'Delete Account',
      cancelLabel: AppStrings.cancel,
    );

    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account deletion request submitted'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.s16,
        AppSizes.s16,
        AppSizes.s16,
        AppSizes.s8,
      ),
      child: Text(
        title,
        style: AppTypography.titleSmall.copyWith(
          color: AppColors.primary,
        ),
      ),
    );
  }
}
