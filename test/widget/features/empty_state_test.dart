import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuish_food/core/widgets/empty_state_widget.dart';

void main() {
  Widget buildApp(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('EmptyStateWidget', () {
    testWidgets('displays message', (tester) async {
      await tester.pumpWidget(buildApp(
        const EmptyStateWidget(message: 'No items found'),
      ));
      expect(find.text('No items found'), findsOneWidget);
    });

    testWidgets('shows default inbox icon when none provided', (tester) async {
      await tester.pumpWidget(buildApp(
        const EmptyStateWidget(message: 'Empty'),
      ));
      expect(find.byIcon(Icons.inbox_rounded), findsOneWidget);
    });

    testWidgets('shows custom icon when provided', (tester) async {
      await tester.pumpWidget(buildApp(
        const EmptyStateWidget(
          message: 'No orders',
          icon: Icons.receipt_long,
        ),
      ));
      expect(find.byIcon(Icons.receipt_long), findsOneWidget);
      expect(find.byIcon(Icons.inbox_rounded), findsNothing);
    });

    testWidgets('shows action button when label and callback provided',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildApp(
        EmptyStateWidget(
          message: 'No results',
          actionLabel: 'Retry',
          onAction: () => tapped = true,
        ),
      ));
      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(tapped, isTrue);
    });

    testWidgets('hides action button when no label', (tester) async {
      await tester.pumpWidget(buildApp(
        const EmptyStateWidget(message: 'Empty'),
      ));
      expect(find.byType(ElevatedButton), findsNothing);
    });
  });
}
