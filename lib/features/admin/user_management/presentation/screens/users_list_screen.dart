import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_strings.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/widgets/empty_state_widget.dart';
import 'package:tuish_food/core/widgets/tuish_app_bar.dart';
import 'package:tuish_food/core/widgets/tuish_text_field.dart';
import 'package:tuish_food/features/admin/user_management/presentation/providers/user_management_provider.dart';
import 'package:tuish_food/features/admin/user_management/presentation/widgets/user_table_row.dart';

class UsersListScreen extends ConsumerWidget {
  const UsersListScreen({super.key});

  static const _roleFilters = <String?, String>{
    null: 'All',
    'customer': 'Customers',
    'deliveryPartner': 'Delivery Partners',
    'admin': 'Admins',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRole = ref.watch(userRoleFilterProvider);
    final usersAsync = ref.watch(allUsersProvider);

    return Scaffold(
      appBar: TuishAppBar(
        title: AppStrings.users,
        actions: [
          IconButton(
            icon: const Icon(Icons.delivery_dining_outlined),
            tooltip: AppStrings.deliveryPartners,
            onPressed: () => context.push('/admin/delivery-partners'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.s16,
              vertical: AppSizes.s8,
            ),
            child: TuishTextField(
              hint: 'Search users...',
              prefixIcon:
                  const Icon(Icons.search, color: AppColors.textHint),
              onChanged: (value) {
                ref.read(userSearchQueryProvider.notifier).update(value);
              },
            ),
          ),

          // Role filter chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.s16),
              children: _roleFilters.entries.map((entry) {
                final isSelected = selectedRole == entry.key;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSizes.s8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(entry.value),
                    labelStyle: AppTypography.labelMedium.copyWith(
                      color: isSelected
                          ? AppColors.onPrimary
                          : AppColors.textPrimary,
                    ),
                    selectedColor: AppColors.primary,
                    checkmarkColor: AppColors.onPrimary,
                    backgroundColor: AppColors.surface,
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.divider,
                    ),
                    onSelected: (_) {
                      ref.read(userRoleFilterProvider.notifier).update(
                          entry.key);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSizes.s8),

          // User list
          Expanded(
            child: usersAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => EmptyStateWidget(
                message: 'Failed to load users',
                icon: Icons.error_outline,
                actionLabel: AppStrings.retry,
                onAction: () => ref.invalidate(allUsersProvider),
              ),
              data: (users) {
                if (users.isEmpty) {
                  return const EmptyStateWidget(
                    message: 'No users found',
                    icon: Icons.people_outline,
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    ref.invalidate(allUsersProvider);
                  },
                  child: ListView.separated(
                    itemCount: users.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      indent: AppSizes.s16,
                      endIndent: AppSizes.s16,
                      color: AppColors.divider,
                    ),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return UserTableRow(
                        user: user,
                        onTap: () =>
                            context.push('/admin/users/${user.uid}'),
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
}
