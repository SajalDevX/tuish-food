import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_strings.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/widgets/empty_state_widget.dart';
import 'package:tuish_food/core/widgets/glass_scaffold.dart';
import 'package:tuish_food/features/customer/home/presentation/providers/search_provider.dart';
import 'package:tuish_food/features/customer/home/presentation/widgets/restaurant_list_tile.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _searchController;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(searchQueryProvider),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {});
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      ref.read(searchQueryProvider.notifier).update(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(searchResultsProvider);
    final currentQuery = ref.watch(searchQueryProvider);

    return GlassScaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: _onSearchChanged,
          style: AppTypography.bodyLarge,
          decoration: InputDecoration(
            hintText: AppStrings.searchRestaurants,
            hintStyle: AppTypography.bodyLarge.copyWith(
              color: AppColors.textHint,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        actions: [
          if (currentQuery.isNotEmpty || _searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(
                Icons.clear_rounded,
                color: AppColors.textSecondary,
              ),
              onPressed: () {
                _searchController.clear();
                setState(() {});
                ref.read(searchQueryProvider.notifier).update('');
              },
            ),
        ],
      ),
      body: _buildBody(searchResults, currentQuery),
    );
  }

  Widget _buildBody(AsyncValue searchResults, String currentQuery) {
    if (currentQuery.trim().isEmpty) {
      return _buildInitialState();
    }

    return searchResults.when(
      data: (restaurants) {
        if (restaurants.isEmpty) {
          return EmptyStateWidget(
            message: 'No restaurants found for "$currentQuery"',
            icon: Icons.search_off_rounded,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.s8),
          itemCount: restaurants.length,
          separatorBuilder: (_, _) => const Divider(
            height: 1,
            indent: AppSizes.s16,
            endIndent: AppSizes.s16,
          ),
          itemBuilder: (context, index) {
            return RestaurantListTile(restaurant: restaurants[index]);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (error, _) => EmptyStateWidget(
        message: AppStrings.somethingWentWrong,
        icon: Icons.error_outline_rounded,
        actionLabel: AppStrings.retry,
        onAction: () {
          ref.invalidate(searchResultsProvider);
        },
      ),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Padding(
        padding: AppSizes.paddingAllL,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_rounded,
              size: AppSizes.iconXL * 1.5,
              color: AppColors.textHint.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSizes.s16),
            Text(
              'Search for restaurants, cuisines, or dishes',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
