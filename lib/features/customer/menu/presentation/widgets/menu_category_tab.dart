import 'package:flutter/material.dart';
import 'package:tuish_food/core/constants/app_typography.dart';

class MenuCategoryTab extends StatelessWidget {
  const MenuCategoryTab({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Tab(child: Text(name, style: AppTypography.labelLarge));
  }
}
