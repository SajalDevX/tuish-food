import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tuish_food/features/customer/menu/domain/entities/menu_item.dart';

class MenuItemCustomizationOptionModel extends MenuItemCustomizationOption {
  const MenuItemCustomizationOptionModel({
    required super.id,
    required super.name,
    required super.additionalPrice,
  });

  factory MenuItemCustomizationOptionModel.fromMap(Map<String, dynamic> map) {
    return MenuItemCustomizationOptionModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      additionalPrice: (map['additionalPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'additionalPrice': additionalPrice};
  }
}

class MenuItemCustomizationModel extends MenuItemCustomization {
  const MenuItemCustomizationModel({
    required super.id,
    required super.title,
    required super.required,
    required super.multiSelect,
    required super.maxSelections,
    required super.options,
  });

  factory MenuItemCustomizationModel.fromMap(Map<String, dynamic> map) {
    return MenuItemCustomizationModel(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      required: map['required'] as bool? ?? false,
      multiSelect: map['multiSelect'] as bool? ?? false,
      maxSelections: map['maxSelections'] as int? ?? 1,
      options:
          (map['options'] as List<dynamic>?)
              ?.map(
                (e) => MenuItemCustomizationOptionModel.fromMap(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'required': required,
      'multiSelect': multiSelect,
      'maxSelections': maxSelections,
      'options': options
          .map(
            (e) => MenuItemCustomizationOptionModel(
              id: e.id,
              name: e.name,
              additionalPrice: e.additionalPrice,
            ).toMap(),
          )
          .toList(),
    };
  }
}

class MenuItemModel extends MenuItem {
  const MenuItemModel({
    required super.id,
    required super.categoryId,
    required super.name,
    required super.description,
    required super.imageUrl,
    required super.price,
    super.discountedPrice,
    required super.isVegetarian,
    required super.isVegan,
    required super.isGlutenFree,
    required super.spiceLevel,
    required super.customizations,
    required super.isAvailable,
    required super.isPopular,
    required super.sortOrder,
    required super.preparationTimeMinutes,
  });

  factory MenuItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MenuItemModel(
      id: doc.id,
      categoryId: data['categoryId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      discountedPrice: (data['discountedPrice'] as num?)?.toDouble(),
      isVegetarian: data['isVegetarian'] as bool? ?? false,
      isVegan: data['isVegan'] as bool? ?? false,
      isGlutenFree: data['isGlutenFree'] as bool? ?? false,
      spiceLevel: data['spiceLevel'] as int? ?? 0,
      customizations:
          (data['customizations'] as List<dynamic>?)
              ?.map(
                (e) => MenuItemCustomizationModel.fromMap(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [],
      isAvailable: data['isAvailable'] as bool? ?? true,
      isPopular: data['isPopular'] as bool? ?? false,
      sortOrder: data['sortOrder'] as int? ?? 0,
      preparationTimeMinutes: data['preparationTimeMinutes'] as int? ?? 15,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'categoryId': categoryId,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'price': price,
      'discountedPrice': discountedPrice,
      'isVegetarian': isVegetarian,
      'isVegan': isVegan,
      'isGlutenFree': isGlutenFree,
      'spiceLevel': spiceLevel,
      'customizations': customizations
          .map(
            (e) => MenuItemCustomizationModel(
              id: e.id,
              title: e.title,
              required: e.required,
              multiSelect: e.multiSelect,
              maxSelections: e.maxSelections,
              options: e.options,
            ).toMap(),
          )
          .toList(),
      'isAvailable': isAvailable,
      'isPopular': isPopular,
      'sortOrder': sortOrder,
      'preparationTimeMinutes': preparationTimeMinutes,
    };
  }
}
