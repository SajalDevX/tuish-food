import 'package:equatable/equatable.dart';

class MenuItemCustomizationOption extends Equatable {
  final String id;
  final String name;
  final double additionalPrice;

  const MenuItemCustomizationOption({
    required this.id,
    required this.name,
    required this.additionalPrice,
  });

  @override
  List<Object?> get props => [id, name, additionalPrice];
}

class MenuItemCustomization extends Equatable {
  final String id;
  final String title;
  final bool required;
  final bool multiSelect;
  final int maxSelections;
  final List<MenuItemCustomizationOption> options;

  const MenuItemCustomization({
    required this.id,
    required this.title,
    required this.required,
    required this.multiSelect,
    required this.maxSelections,
    required this.options,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    required,
    multiSelect,
    maxSelections,
    options,
  ];
}

class MenuItem extends Equatable {
  final String id;
  final String categoryId;
  final String name;
  final String description;
  final String imageUrl;
  final double price;
  final double? discountedPrice;
  final bool isVegetarian;
  final bool isVegan;
  final bool isGlutenFree;
  final int spiceLevel;
  final List<MenuItemCustomization> customizations;
  final bool isAvailable;
  final bool isPopular;
  final int sortOrder;
  final int preparationTimeMinutes;

  const MenuItem({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    this.discountedPrice,
    required this.isVegetarian,
    required this.isVegan,
    required this.isGlutenFree,
    required this.spiceLevel,
    required this.customizations,
    required this.isAvailable,
    required this.isPopular,
    required this.sortOrder,
    required this.preparationTimeMinutes,
  });

  double get effectivePrice => discountedPrice ?? price;

  bool get hasDiscount => discountedPrice != null && discountedPrice! < price;

  bool get hasCustomizations => customizations.isNotEmpty;

  @override
  List<Object?> get props => [
    id,
    categoryId,
    name,
    description,
    imageUrl,
    price,
    discountedPrice,
    isVegetarian,
    isVegan,
    isGlutenFree,
    spiceLevel,
    customizations,
    isAvailable,
    isPopular,
    sortOrder,
    preparationTimeMinutes,
  ];
}
