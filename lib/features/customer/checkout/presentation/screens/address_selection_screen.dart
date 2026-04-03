import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/widgets/empty_state_widget.dart';
import 'package:tuish_food/core/widgets/tuish_button.dart';
import 'package:tuish_food/features/customer/checkout/presentation/providers/checkout_provider.dart';
import 'package:tuish_food/features/customer/profile/domain/entities/address.dart';
import 'package:tuish_food/features/customer/profile/presentation/providers/profile_provider.dart';
import 'package:tuish_food/injection_container.dart';
import 'package:tuish_food/routing/route_names.dart';

class AddressSelectionScreen extends ConsumerStatefulWidget {
  const AddressSelectionScreen({super.key});

  @override
  ConsumerState<AddressSelectionScreen> createState() =>
      _AddressSelectionScreenState();
}

class _AddressSelectionScreenState
    extends ConsumerState<AddressSelectionScreen> {
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = ref.read(checkoutNotifierProvider).deliveryAddressId;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final userId = currentUser?.uid ?? '';
    final addressesAsync = ref.watch(addressesProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Address'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: addressesAsync.when(
        data: (addresses) => _buildAddressList(context, addresses),
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: AppSizes.iconXL, color: AppColors.error),
              const SizedBox(height: AppSizes.s16),
              Text(error.toString(),
                  style: AppTypography.bodyMedium, textAlign: TextAlign.center),
              const SizedBox(height: AppSizes.s16),
              TextButton(
                onPressed: () => ref.invalidate(addressesProvider(userId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressList(BuildContext context, List<Address> addresses) {
    // Auto-select default if nothing is selected yet
    if (_selectedId == null && addresses.isNotEmpty) {
      final defaultAddr = addresses.firstWhere(
        (a) => a.isDefault,
        orElse: () => addresses.first,
      );
      _selectedId = defaultAddr.id;
    }

    final currentUser = ref.read(currentUserProvider);
    final userId = currentUser?.uid ?? '';

    if (addresses.isEmpty) {
      return EmptyStateWidget(
        message: 'No saved addresses.\nAdd one to continue.',
        icon: Icons.location_off_outlined,
        actionLabel: 'Add Address',
        onAction: () async {
          await context.pushNamed(RouteNames.addAddress);
          ref.invalidate(addressesProvider(userId));
        },
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: AppSizes.paddingAllM,
            children: [
              ...addresses.map((address) {
                final isSelected = _selectedId == address.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.s12),
                  child: InkWell(
                    onTap: () => setState(() => _selectedId = address.id),
                    borderRadius: AppSizes.borderRadiusM,
                    child: Container(
                      padding: AppSizes.paddingAllM,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.05)
                            : AppColors.surface,
                        borderRadius: AppSizes.borderRadiusM,
                        border: Border.all(
                          color:
                              isSelected ? AppColors.primary : AppColors.divider,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.1)
                                  : AppColors.background,
                              borderRadius: AppSizes.borderRadiusS,
                            ),
                            child: Icon(
                              _iconForLabel(address.label),
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: AppSizes.s12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(address.displayLabel,
                                        style: AppTypography.titleSmall),
                                    if (address.isDefault) ...[
                                      const SizedBox(width: AppSizes.s8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.12),
                                          borderRadius: AppSizes.borderRadiusPill,
                                        ),
                                        child: Text(
                                          'Default',
                                          style: AppTypography.labelSmall
                                              .copyWith(
                                                  color: AppColors.primary),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  address.fullAddress,
                                  style: AppTypography.bodySmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          // ignore: deprecated_member_use
                          Radio<String>(
                            value: address.id,
                            // ignore: deprecated_member_use
                            groupValue: _selectedId,
                            // ignore: deprecated_member_use
                            onChanged: (v) => setState(() => _selectedId = v),
                            activeColor: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: AppSizes.s8),

              OutlinedButton.icon(
                onPressed: () async {
                  await context.pushNamed(RouteNames.addAddress);
                  ref.invalidate(addressesProvider(userId));
                },
                icon: const Icon(Icons.add),
                label: const Text('Add New Address'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSizes.s12),
                  shape: RoundedRectangleBorder(
                      borderRadius: AppSizes.borderRadiusM),
                ),
              ),
            ],
          ),
        ),

        if (_selectedId != null)
          SafeArea(
            child: Padding(
              padding: AppSizes.paddingAllM,
              child: TuishButton.primary(
                label: 'Confirm Address',
                onPressed: () {
                  final selected = addresses.firstWhere(
                    (a) => a.id == _selectedId,
                  );
                  ref
                      .read(checkoutNotifierProvider.notifier)
                      .setDeliveryAddress(selected.id, selected.fullAddress);
                  context.pop();
                },
              ),
            ),
          ),
      ],
    );
  }

  IconData _iconForLabel(String label) {
    return switch (label.toLowerCase()) {
      'home' => Icons.home,
      'work' => Icons.work,
      _ => Icons.location_on,
    };
  }
}
