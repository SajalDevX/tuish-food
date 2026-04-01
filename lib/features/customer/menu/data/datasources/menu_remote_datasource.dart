import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tuish_food/core/constants/firebase_constants.dart';
import 'package:tuish_food/core/errors/exceptions.dart';
import 'package:tuish_food/features/customer/menu/data/models/menu_item_model.dart';
import 'package:tuish_food/features/customer/menu/data/models/menu_category_model.dart';

abstract class MenuRemoteDatasource {
  Future<List<MenuItemModel>> getMenuItems(String restaurantId);
  Future<List<MenuCategoryModel>> getMenuCategories(String restaurantId);
}

class MenuRemoteDatasourceImpl implements MenuRemoteDatasource {
  final FirebaseFirestore firestore;

  const MenuRemoteDatasourceImpl({required this.firestore});

  @override
  Future<List<MenuItemModel>> getMenuItems(String restaurantId) async {
    try {
      final snapshot = await firestore
          .collection(FirebaseConstants.restaurantsCollection)
          .doc(restaurantId)
          .collection(FirebaseConstants.menuItemsSubcollection)
          .orderBy('sortOrder')
          .get();

      return snapshot.docs
          .map((doc) => MenuItemModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ServerException('Failed to load menu items: $e');
    }
  }

  @override
  Future<List<MenuCategoryModel>> getMenuCategories(String restaurantId) async {
    try {
      final snapshot = await firestore
          .collection(FirebaseConstants.restaurantsCollection)
          .doc(restaurantId)
          .collection(FirebaseConstants.menuCategoriesSubcollection)
          .orderBy('sortOrder')
          .get();

      return snapshot.docs
          .map((doc) => MenuCategoryModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ServerException('Failed to load menu categories: $e');
    }
  }
}
