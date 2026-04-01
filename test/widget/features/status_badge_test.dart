import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuish_food/core/enums/order_status.dart';
import 'package:tuish_food/core/widgets/status_badge.dart';

void main() {
  Widget buildApp(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('StatusBadge', () {
    for (final status in OrderStatus.values) {
      testWidgets('displays ${status.displayName} for $status', (tester) async {
        await tester.pumpWidget(buildApp(StatusBadge(status: status)));
        expect(find.text(status.displayName), findsOneWidget);
      });
    }

    testWidgets('renders as a Container with decoration', (tester) async {
      await tester.pumpWidget(buildApp(
        const StatusBadge(status: OrderStatus.delivered),
      ));
      expect(find.byType(Container), findsWidgets);
      expect(find.text('Delivered'), findsOneWidget);
    });
  });
}
