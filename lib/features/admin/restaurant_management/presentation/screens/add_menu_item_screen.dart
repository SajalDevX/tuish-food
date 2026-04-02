import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/widgets/tuish_app_bar.dart';
import 'package:tuish_food/features/admin/restaurant_management/presentation/providers/restaurant_management_provider.dart';
import 'package:tuish_food/features/admin/restaurant_management/presentation/widgets/menu_item_form.dart';

class AddMenuItemScreen extends ConsumerWidget {
  const AddMenuItemScreen({
    super.key,
    required this.restaurantId,
  });

  final String restaurantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final crudState = ref.watch(menuCrudProvider);
    final isLoading = crudState.isLoading;

    ref.listen<AsyncValue<void>>(menuCrudProvider, (_, state) {
      state.whenOrNull(
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString()),
              backgroundColor: AppColors.error,
            ),
          );
        },
      );
    });

    return Scaffold(
      appBar: const TuishAppBar(title: 'Add Menu Item'),
      body: MenuItemForm(
        isLoading: isLoading,
        onSubmit: (data) async {
          final success = await ref
              .read(menuCrudProvider.notifier)
              .addMenuItem(restaurantId, data);
          if (success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Menu item added successfully'),
                backgroundColor: AppColors.success,
              ),
            );
            context.pop();
          }
        },
      ),
    );
  }
}
