import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_strings.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/widgets/confirmation_dialog.dart';
import 'package:tuish_food/core/widgets/empty_state_widget.dart';
import 'package:tuish_food/core/widgets/tuish_app_bar.dart';
import 'package:tuish_food/core/widgets/tuish_card.dart';
import 'package:tuish_food/features/admin/user_management/presentation/providers/user_management_provider.dart';
import 'package:tuish_food/features/auth/domain/entities/app_user.dart';

/// Notifier for selected tab index on the delivery partners screen.
class _DeliveryPartnerTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void update(int value) {
    state = value;
  }
}

final _deliveryPartnerTabProvider =
    NotifierProvider<_DeliveryPartnerTabNotifier, int>(
        _DeliveryPartnerTabNotifier.new);

class DeliveryPartnersScreen extends ConsumerWidget {
  const DeliveryPartnersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(_deliveryPartnerTabProvider);
    final partnersAsync =
        ref.watch(usersByRoleProvider('deliveryPartner'));

    return Scaffold(
      appBar: const TuishAppBar(title: AppStrings.deliveryPartners),
      body: Column(
        children: [
          // Tab bar
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.s16),
              children: [
                _TabChip(
                  label: 'All',
                  isSelected: selectedTab == 0,
                  onTap: () => ref
                      .read(_deliveryPartnerTabProvider.notifier)
                      .update(0),
                ),
                _TabChip(
                  label: 'Pending',
                  isSelected: selectedTab == 1,
                  onTap: () => ref
                      .read(_deliveryPartnerTabProvider.notifier)
                      .update(1),
                ),
                _TabChip(
                  label: 'Verified',
                  isSelected: selectedTab == 2,
                  onTap: () => ref
                      .read(_deliveryPartnerTabProvider.notifier)
                      .update(2),
                ),
                _TabChip(
                  label: 'Rejected',
                  isSelected: selectedTab == 3,
                  onTap: () => ref
                      .read(_deliveryPartnerTabProvider.notifier)
                      .update(3),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.s8),

          // Partners list
          Expanded(
            child: partnersAsync.when(
              loading: () => const Center(
                child:
                    CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => EmptyStateWidget(
                message: 'Failed to load delivery partners',
                icon: Icons.error_outline,
                actionLabel: AppStrings.retry,
                onAction: () => ref.invalidate(
                    usersByRoleProvider('deliveryPartner')),
              ),
              data: (partners) {
                // Filter partners based on selected tab
                // Note: verification status is stored in Firestore,
                // we do a simple client-side filter here.
                final filtered = _filterPartners(partners, selectedTab);

                if (filtered.isEmpty) {
                  return const EmptyStateWidget(
                    message: 'No delivery partners found',
                    icon: Icons.delivery_dining_outlined,
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    ref.invalidate(
                        usersByRoleProvider('deliveryPartner'));
                  },
                  child: ListView.builder(
                    padding: AppSizes.screenPadding,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final partner = filtered[index];
                      return _PartnerCard(
                        partner: partner,
                        onTap: () => context
                            .push('/admin/users/${partner.uid}'),
                        onVerify: () =>
                            _handleVerify(context, ref, partner.uid),
                        onReject: () =>
                            _handleReject(context, ref, partner.uid),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<AppUser> _filterPartners(List<AppUser> partners, int tab) {
    return switch (tab) {
      // All
      0 => partners,
      // Pending (not verified and not banned)
      1 => partners
          .where((p) => !p.isBanned && p.isActive)
          .toList(),
      // Verified (active and not banned)
      2 => partners
          .where((p) => p.isActive && !p.isBanned)
          .toList(),
      // Rejected (banned)
      3 => partners.where((p) => p.isBanned).toList(),
      _ => partners,
    };
  }

  Future<void> _handleVerify(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Verify Partner',
      message: 'Are you sure you want to verify this delivery partner?',
      confirmLabel: 'Verify',
      cancelLabel: AppStrings.cancel,
    );
    if (confirmed == true) {
      final success =
          await ref.read(verifyPartnerProvider.notifier).verify(userId);
      if (context.mounted && success) {
        ref.invalidate(usersByRoleProvider('deliveryPartner'));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Partner verified successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _handleReject(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Reject Partner',
      message: 'Are you sure you want to reject this delivery partner?',
      confirmLabel: 'Reject',
      cancelLabel: AppStrings.cancel,
    );
    if (confirmed == true) {
      final success =
          await ref.read(banUserProvider.notifier).banUser(userId);
      if (context.mounted && success) {
        ref.invalidate(usersByRoleProvider('deliveryPartner'));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Partner rejected'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Private widgets
// ---------------------------------------------------------------------------

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSizes.s8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: AppTypography.labelMedium.copyWith(
          color: isSelected ? AppColors.onPrimary : AppColors.textPrimary,
        ),
        selectedColor: AppColors.primary,
        checkmarkColor: AppColors.onPrimary,
        backgroundColor: AppColors.surface,
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.divider,
        ),
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _PartnerCard extends StatelessWidget {
  const _PartnerCard({
    required this.partner,
    required this.onTap,
    required this.onVerify,
    required this.onReject,
  });

  final AppUser partner;
  final VoidCallback onTap;
  final VoidCallback onVerify;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return TuishCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: AppSizes.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: AppSizes.avatarM / 2,
                backgroundColor:
                    AppColors.secondary.withValues(alpha: 0.1),
                backgroundImage: partner.photoUrl != null
                    ? NetworkImage(partner.photoUrl!)
                    : null,
                child: partner.photoUrl == null
                    ? Icon(
                        Icons.delivery_dining,
                        color: AppColors.secondary,
                        size: AppSizes.iconM,
                      )
                    : null,
              ),
              const SizedBox(width: AppSizes.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partner.displayName ?? 'Unknown',
                      style: AppTypography.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      partner.phone ?? partner.email ?? 'No contact',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              // Status indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.s8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: partner.isBanned
                      ? AppColors.error.withValues(alpha: 0.1)
                      : partner.isActive
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: AppSizes.borderRadiusPill,
                ),
                child: Text(
                  partner.isBanned
                      ? 'Rejected'
                      : partner.isActive
                          ? 'Active'
                          : 'Pending',
                  style: AppTypography.labelSmall.copyWith(
                    color: partner.isBanned
                        ? AppColors.error
                        : partner.isActive
                            ? AppColors.success
                            : AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          // Action buttons for non-banned partners
          if (!partner.isBanned) ...[
            const SizedBox(height: AppSizes.s12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onReject,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                  child: const Text('Reject'),
                ),
                const SizedBox(width: AppSizes.s8),
                FilledButton(
                  onPressed: onVerify,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                  ),
                  child: const Text('Verify'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
