import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuish_food/core/widgets/tuish_button.dart';

void main() {
  Widget buildApp(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('TuishButton.primary', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(buildApp(
        TuishButton.primary(label: 'Submit', onPressed: () {}),
      ));
      expect(find.text('Submit'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var pressed = false;
      await tester.pumpWidget(buildApp(
        TuishButton.primary(
          label: 'Tap Me',
          onPressed: () => pressed = true,
        ),
      ));
      await tester.tap(find.text('Tap Me'));
      expect(pressed, isTrue);
    });

    testWidgets('shows loading indicator when isLoading', (tester) async {
      await tester.pumpWidget(buildApp(
        TuishButton.primary(
          label: 'Loading',
          onPressed: () {},
          isLoading: true,
        ),
      ));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading'), findsNothing);
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(buildApp(
        const TuishButton.primary(label: 'Disabled'),
      ));
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });
  });

  group('TuishButton.outlined', () {
    testWidgets('renders as OutlinedButton', (tester) async {
      await tester.pumpWidget(buildApp(
        TuishButton.outlined(label: 'Outlined', onPressed: () {}),
      ));
      expect(find.byType(OutlinedButton), findsOneWidget);
    });
  });

  group('TuishButton.text', () {
    testWidgets('renders as TextButton', (tester) async {
      await tester.pumpWidget(buildApp(
        TuishButton.text(label: 'Text', onPressed: () {}),
      ));
      expect(find.byType(TextButton), findsOneWidget);
    });
  });

  group('TuishButton with icon', () {
    testWidgets('renders icon alongside label', (tester) async {
      await tester.pumpWidget(buildApp(
        TuishButton.primary(
          label: 'Add',
          icon: const Icon(Icons.add),
          onPressed: () {},
        ),
      ));
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
    });
  });
}
