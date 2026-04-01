import 'package:equatable/equatable.dart';

class FoodCategory extends Equatable {
  final String id;
  final String name;
  final String imageUrl;
  final int restaurantCount;

  const FoodCategory({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.restaurantCount = 0,
  });

  @override
  List<Object?> get props => [id, name, imageUrl, restaurantCount];
}
