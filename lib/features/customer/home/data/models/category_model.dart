import 'package:tuish_food/features/customer/home/domain/entities/category.dart';

class CategoryModel extends FoodCategory {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.imageUrl,
    super.restaurantCount,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      restaurantCount: map['restaurantCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'restaurantCount': restaurantCount,
    };
  }

  /// Predefined list of food categories with emoji-based placeholder icons.
  static const List<CategoryModel> predefinedCategories = [
    CategoryModel(
      id: 'pizza',
      name: 'Pizza',
      imageUrl: '',
    ),
    CategoryModel(
      id: 'burger',
      name: 'Burgers',
      imageUrl: '',
    ),
    CategoryModel(
      id: 'sushi',
      name: 'Sushi',
      imageUrl: '',
    ),
    CategoryModel(
      id: 'chinese',
      name: 'Chinese',
      imageUrl: '',
    ),
    CategoryModel(
      id: 'indian',
      name: 'Indian',
      imageUrl: '',
    ),
    CategoryModel(
      id: 'mexican',
      name: 'Mexican',
      imageUrl: '',
    ),
    CategoryModel(
      id: 'thai',
      name: 'Thai',
      imageUrl: '',
    ),
    CategoryModel(
      id: 'italian',
      name: 'Italian',
      imageUrl: '',
    ),
    CategoryModel(
      id: 'dessert',
      name: 'Desserts',
      imageUrl: '',
    ),
    CategoryModel(
      id: 'healthy',
      name: 'Healthy',
      imageUrl: '',
    ),
    CategoryModel(
      id: 'coffee',
      name: 'Coffee',
      imageUrl: '',
    ),
    CategoryModel(
      id: 'fast_food',
      name: 'Fast Food',
      imageUrl: '',
    ),
  ];
}
