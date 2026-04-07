import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: Center(child: child)));
  }

  group('EdenStatCard', () {
    testWidgets('renders label and value', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenStatCard(label: 'Total Users', value: '1,234'),
      ));

      expect(find.text('Total Users'), findsOneWidget);
      expect(find.text('1,234'), findsOneWidget);
    });

    testWidgets('renders with icon', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenStatCard(
          label: 'Revenue',
          value: '\$42,000',
          icon: Icons.attach_money,
        ),
      ));

      expect(find.byIcon(Icons.attach_money), findsOneWidget);
      expect(find.text('\$42,000'), findsOneWidget);
    });

    testWidgets('renders up trend indicator', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenStatCard(
          label: 'Users',
          value: '500',
          trend: EdenStatTrend.up,
          trendValue: '+12%',
        ),
      ));

      expect(find.byIcon(Icons.trending_up), findsOneWidget);
      expect(find.text('+12%'), findsOneWidget);
    });

    testWidgets('renders down trend indicator', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenStatCard(
          label: 'Bounce Rate',
          value: '45%',
          trend: EdenStatTrend.down,
          trendValue: '-5%',
        ),
      ));

      expect(find.byIcon(Icons.trending_down), findsOneWidget);
      expect(find.text('-5%'), findsOneWidget);
    });

    testWidgets('renders neutral trend indicator', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenStatCard(
          label: 'Sessions',
          value: '1,000',
          trend: EdenStatTrend.neutral,
        ),
      ));

      expect(find.byIcon(Icons.trending_flat), findsOneWidget);
    });

    testWidgets('renders trend label', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenStatCard(
          label: 'Revenue',
          value: '\$50k',
          trend: EdenStatTrend.up,
          trendValue: '+8%',
          trendLabel: 'vs last month',
        ),
      ));

      expect(find.text('vs last month'), findsOneWidget);
    });

    testWidgets('renders without trend section when no trend given',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenStatCard(label: 'Items', value: '42'),
      ));

      expect(find.byIcon(Icons.trending_up), findsNothing);
      expect(find.byIcon(Icons.trending_down), findsNothing);
      expect(find.byIcon(Icons.trending_flat), findsNothing);
    });

    testWidgets('renders with custom variant color', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenStatCard(
          label: 'Errors',
          value: '3',
          icon: Icons.error,
          variant: Colors.red,
        ),
      ));

      expect(find.text('Errors'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });
  });
}
