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
import 'package:tuish_food/features/customer/profile/presentation/providers/profile_provider.dart';
import 'package:tuish_food/features/customer/profile/presentation/widgets/address_card.dart';
import 'package:tuish_food/injection_container.dart';
import 'package:tuish_food/routing/route_names.dart';

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final userId = currentUser?.uid ?? '';
    final addressesAsync = ref.watch(addressesProvider(userId));

    return Scaffold(
      appBar: const TuishAppBar(title: 'Saved Addresses'),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        onPressed: () => context.pushNamed(RouteNames.addAddress),
        child: const Icon(Icons.add),
      ),
      body: addressesAsync.when(
        data: (addresses) {
          if (addresses.isEmpty) {
            return EmptyStateWidget(
              message: 'No saved addresses yet',
              icon: Icons.location_off_outlined,
              actionLabel: 'Add Address',
              onAction: () => context.pushNamed(RouteNames.addAddress),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(addressesProvider(userId));
            },
            child: ListView.builder(
              padding: AppSizes.paddingAllM,
              itemCount: addresses.length,
              itemBuilder: (context, index) {
                final address = addresses[index];
                return AddressCard(
                  address: address,
                  onSetDefault: () async {
                    final notifier =
                        ref.read(addressManagementProvider.notifier);
                    final success = await notifier.setDefaultAddress(
                        userId, address.id);
                    if (success) {
                      ref.invalidate(addressesProvider(userId));
                    }
                  },
                  onEdit: () {
                    // Navigate to add address screen with pre-filled data
                    context.pushNamed(RouteNames.addAddress);
                  },
                  onDelete: () async {
                    final confirmed = await ConfirmationDialog.show(
                      context,
                      title: 'Delete Address',
                      message:
                          'Are you sure you want to delete this address?',
                      confirmLabel: AppStrings.delete,
                      cancelLabel: AppStrings.cancel,
                    );

                    if (confirmed == true) {
                      final notifier =
                          ref.read(addressManagementProvider.notifier);
                      final success = await notifier.deleteAddress(
                          userId, address.id);
                      if (success) {
                        ref.invalidate(addressesProvider(userId));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Address deleted'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      }
                    }
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: AppSizes.iconXL, color: AppColors.error),
              const SizedBox(height: AppSizes.s16),
              Text(
                error.toString(),
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.s16),
              TextButton(
                onPressed: () =>
                    ref.invalidate(addressesProvider(userId)),
                child: const Text(AppStrings.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
