import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: Center(child: child)));
  }

  group('EdenPagination', () {
    testWidgets('renders page numbers for small page count', (tester) async {
      await tester.pumpWidget(wrap(
        EdenPagination(
          currentPage: 1,
          totalPages: 5,
          onPageChanged: (_) {},
        ),
      ));

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('renders prev and next navigation buttons', (tester) async {
      await tester.pumpWidget(wrap(
        EdenPagination(
          currentPage: 2,
          totalPages: 5,
          onPageChanged: (_) {},
        ),
      ));

      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('calls onPageChanged when page number tapped', (tester) async {
      int? selectedPage;
      await tester.pumpWidget(wrap(
        EdenPagination(
          currentPage: 1,
          totalPages: 5,
          onPageChanged: (p) => selectedPage = p,
        ),
      ));

      await tester.tap(find.text('3'));
      expect(selectedPage, 3);
    });

    testWidgets('calls onPageChanged with next page on right arrow tap',
        (tester) async {
      int? selectedPage;
      await tester.pumpWidget(wrap(
        EdenPagination(
          currentPage: 2,
          totalPages: 5,
          onPageChanged: (p) => selectedPage = p,
        ),
      ));

      await tester.tap(find.byIcon(Icons.chevron_right));
      expect(selectedPage, 3);
    });

    testWidgets('calls onPageChanged with prev page on left arrow tap',
        (tester) async {
      int? selectedPage;
      await tester.pumpWidget(wrap(
        EdenPagination(
          currentPage: 3,
          totalPages: 5,
          onPageChanged: (p) => selectedPage = p,
        ),
      ));

      await tester.tap(find.byIcon(Icons.chevron_left));
      expect(selectedPage, 2);
    });

    testWidgets('shows ellipsis for large page counts', (tester) async {
      await tester.pumpWidget(wrap(
        EdenPagination(
          currentPage: 5,
          totalPages: 20,
          onPageChanged: (_) {},
        ),
      ));

      expect(find.text('...'), findsWidgets);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
    });

    testWidgets('does not call onPageChanged when tapping current page',
        (tester) async {
      int? selectedPage;
      await tester.pumpWidget(wrap(
        EdenPagination(
          currentPage: 3,
          totalPages: 5,
          onPageChanged: (p) => selectedPage = p,
        ),
      ));

      await tester.tap(find.text('3'));
      expect(selectedPage, isNull);
    });

    testWidgets('single page renders correctly', (tester) async {
      await tester.pumpWidget(wrap(
        EdenPagination(
          currentPage: 1,
          totalPages: 1,
          onPageChanged: (_) {},
        ),
      ));

      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('has semantic labels for accessibility', (tester) async {
      await tester.pumpWidget(wrap(
        EdenPagination(
          currentPage: 1,
          totalPages: 3,
          onPageChanged: (_) {},
        ),
      ));

      expect(
        find.bySemanticsLabel('Previous page'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Next page'),
        findsOneWidget,
      );
    });
  });
}
