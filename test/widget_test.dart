import 'package:flutter_test/flutter_test.dart';
import 'package:tuish_food/core/constants/app_strings.dart';

void main() {
  test('App name is correct', () {
    expect(AppStrings.appName, 'Tuish Food');
  });

  test('App tagline is correct', () {
    expect(AppStrings.appTagline, 'Delicious food, delivered fast');
  });
}
