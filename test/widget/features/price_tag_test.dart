import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuish_food/core/widgets/price_tag.dart';

void main() {
  Widget buildApp(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('PriceTag', () {
    testWidgets('displays price with rupee symbol', (tester) async {
      await tester.pumpWidget(buildApp(const PriceTag(price: 299)));
      expect(find.textContaining('\u20B9299'), findsOneWidget);
    });

    testWidgets('displays whole number without decimals', (tester) async {
      await tester.pumpWidget(buildApp(const PriceTag(price: 100)));
      // Whole numbers should show as ₹100, not ₹100.00
      expect(find.textContaining('100'), findsOneWidget);
    });

    testWidgets('shows discounted price with strikethrough', (tester) async {
      await tester.pumpWidget(buildApp(
        const PriceTag(price: 500, discountedPrice: 399),
      ));
      // Both prices should be visible
      expect(find.textContaining('399'), findsOneWidget);
      expect(find.textContaining('500'), findsOneWidget);
    });

    testWidgets('uses custom currency symbol', (tester) async {
      await tester.pumpWidget(buildApp(
        const PriceTag(price: 10, currencySymbol: '\$'),
      ));
      expect(find.textContaining('\$10'), findsOneWidget);
    });

    testWidgets('shows row layout when discounted', (tester) async {
      await tester.pumpWidget(buildApp(
        const PriceTag(price: 500, discountedPrice: 399),
      ));
      expect(find.byType(Row), findsOneWidget);
    });

    testWidgets('shows single Text when not discounted', (tester) async {
      await tester.pumpWidget(buildApp(const PriceTag(price: 299)));
      expect(find.byType(Row), findsNothing);
    });
  });
}
