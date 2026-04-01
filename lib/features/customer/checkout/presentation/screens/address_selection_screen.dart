import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/widgets/empty_state_widget.dart';
import 'package:tuish_food/core/widgets/tuish_button.dart';
import 'package:tuish_food/features/customer/checkout/presentation/providers/checkout_provider.dart';

/// A simple address data class used within checkout address selection.
/// In a full implementation this would come from the profile feature's
/// address entity and provider.
class _SavedAddress {
  final String id;
  final String label;
  final String address;
  final IconData icon;

  const _SavedAddress({
    required this.id,
    required this.label,
    required this.address,
    required this.icon,
  });
}

class AddressSelectionScreen extends ConsumerStatefulWidget {
  const AddressSelectionScreen({super.key});

  @override
  ConsumerState<AddressSelectionScreen> createState() =>
      _AddressSelectionScreenState();
}

class _AddressSelectionScreenState
    extends ConsumerState<AddressSelectionScreen> {
  // In production, these would come from the profile provider's addresses.
  // Using sample data to demonstrate the UI flow.
  final _addresses = const <_SavedAddress>[
    _SavedAddress(
      id: 'home',
      label: 'Home',
      address: '123 Main Street, Apartment 4B, New Delhi 110001',
      icon: Icons.home,
    ),
    _SavedAddress(
      id: 'work',
      label: 'Work',
      address: '456 Business Park, Tower A, Floor 12, Gurugram 122001',
      icon: Icons.work,
    ),
  ];

  String? _selectedId;

  @override
  void initState() {
    super.initState();
    final currentId = ref.read(checkoutNotifierProvider).deliveryAddressId;
    _selectedId = currentId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Address'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _addresses.isEmpty
          ? EmptyStateWidget(
              message: 'No saved addresses.\nAdd a new address to continue.',
              icon: Icons.location_off_outlined,
              actionLabel: 'Add Address',
              onAction: () {
                // Navigate to add address screen
                // In production: context.pushNamed(RouteNames.addAddress);
              },
            )
          : ListView(
              padding: AppSizes.paddingAllM,
              children: [
                ..._addresses.map((address) {
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
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.divider,
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
                                address.icon,
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
                                  Text(
                                    address.label,
                                    style: AppTypography.titleSmall,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    address.address,
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

                const SizedBox(height: AppSizes.s16),

                // Add new address
                OutlinedButton.icon(
                  onPressed: () {
                    // In production this navigates to add address screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Add address coming soon')),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Address'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.s12),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSizes.borderRadiusM,
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _selectedId != null
          ? SafeArea(
              child: Padding(
                padding: AppSizes.paddingAllM,
                child: TuishButton.primary(
                  label: 'Confirm Address',
                  onPressed: () {
                    final selected = _addresses.firstWhere(
                      (a) => a.id == _selectedId,
                    );
                    ref
                        .read(checkoutNotifierProvider.notifier)
                        .setDeliveryAddress(selected.id, selected.address);
                    context.pop();
                  },
                ),
              ),
            )
          : null,
    );
  }
}
