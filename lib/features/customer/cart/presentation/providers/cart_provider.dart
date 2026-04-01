import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuish_food/core/widgets/confirmation_dialog.dart';
import 'package:tuish_food/features/customer/cart/data/repositories/cart_repository_impl.dart';
import 'package:tuish_food/features/customer/cart/domain/entities/cart.dart';
import 'package:tuish_food/features/customer/cart/domain/entities/cart_item.dart';
import 'package:tuish_food/features/customer/cart/domain/repositories/cart_repository.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden at app startup',
  );
});

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepositoryImpl(
    sharedPreferences: ref.watch(sharedPreferencesProvider),
  );
});

final cartNotifierProvider = NotifierProvider<CartNotifier, Cart>(
  CartNotifier.new,
);

class CartNotifier extends Notifier<Cart> {
  @override
  Cart build() {
    _loadCart();
    return const Cart();
  }

  CartRepository get _repository => ref.read(cartRepositoryProvider);

  Future<void> _loadCart() async {
    final result = await _repository.getCart();
    result.fold((_) {}, (cart) => state = cart);
  }

  /// Adds an item to the cart. If the cart currently belongs to a different
  /// restaurant, shows a confirmation dialog asking the user to clear it first.
  Future<void> addItem(
    CartItem item, {
    required String restaurantId,
    required String restaurantName,
    BuildContext? context,
  }) async {
    // Check if switching restaurants
    if (state.isNotEmpty &&
        state.restaurantId != null &&
        state.restaurantId != restaurantId) {
      if (context != null && context.mounted) {
        final confirmed = await ConfirmationDialog.show(
          context,
          title: 'Replace cart items?',
          message:
              'Your cart contains items from ${state.restaurantName ?? "another restaurant"}. '
              'Do you want to clear it and add items from $restaurantName?',
          confirmLabel: 'Yes, start fresh',
          cancelLabel: 'No',
        );

        if (confirmed != true) return;

        // Clear and add new
        state = Cart(
          restaurantId: restaurantId,
          restaurantName: restaurantName,
          items: [item],
        );
        await _repository.saveCart(state);
        return;
      }
    }

    final updatedItems = List<CartItem>.from(state.items);

    // Check if same item (same customizations) exists
    final existingIndex = updatedItems.indexWhere(
      (i) => i.uniqueKey == item.uniqueKey,
    );

    if (existingIndex >= 0) {
      final existing = updatedItems[existingIndex];
      updatedItems[existingIndex] = existing.copyWith(
        quantity: existing.quantity + item.quantity,
      );
    } else {
      updatedItems.add(item);
    }

    state = Cart(
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      items: updatedItems,
    );

    await _repository.saveCart(state);
  }

  Future<void> removeItem(String uniqueKey) async {
    final updatedItems = state.items
        .where((i) => i.uniqueKey != uniqueKey)
        .toList();

    state = updatedItems.isEmpty
        ? const Cart()
        : state.copyWith(items: updatedItems);

    await _repository.saveCart(state);
  }

  Future<void> updateQuantity(String uniqueKey, int newQuantity) async {
    if (newQuantity <= 0) {
      await removeItem(uniqueKey);
      return;
    }

    final updatedItems = state.items.map((item) {
      if (item.uniqueKey == uniqueKey) {
        return item.copyWith(quantity: newQuantity);
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedItems);
    await _repository.saveCart(state);
  }

  Future<void> clear() async {
    state = const Cart();
    await _repository.clearCart();
  }

  /// Increments a specific menu item that has no customizations.
  /// Used by the menu item card's quick add button.
  void incrementSimpleItem(
    String menuItemId, {
    required String name,
    required String imageUrl,
    required double price,
    required String restaurantId,
    required String restaurantName,
    BuildContext? context,
  }) {
    final item = CartItem(
      menuItemId: menuItemId,
      name: name,
      imageUrl: imageUrl,
      price: price,
      quantity: 1,
    );
    addItem(
      item,
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      context: context,
    );
  }

  void decrementSimpleItem(String menuItemId) {
    // Find item by menuItemId with no customizations
    final existing = state.items.where(
      (i) => i.menuItemId == menuItemId && i.selectedCustomizations.isEmpty,
    );
    if (existing.isEmpty) return;

    final item = existing.first;
    updateQuantity(item.uniqueKey, item.quantity - 1);
  }

  /// Returns the total quantity of a specific menu item ID in the cart
  /// (only for items with no customizations).
  int getSimpleItemQuantity(String menuItemId) {
    final matching = state.items.where(
      (i) => i.menuItemId == menuItemId && i.selectedCustomizations.isEmpty,
    );
    if (matching.isEmpty) return 0;
    return matching.first.quantity;
  }
}
