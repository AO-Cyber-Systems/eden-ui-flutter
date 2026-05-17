import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 400, height: 400, child: child),
        ),
      );

  group('EdenEdgeContextMenu', () {
    testWidgets('renders Delete Connection label + trash icon',
        (tester) async {
      await tester.pumpWidget(wrap(EdenEdgeContextMenu(
        onDelete: () {},
        onClose: () {},
      )));
      expect(find.text('Delete Connection'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('tap action fires onDelete AND onClose', (tester) async {
      bool deleted = false;
      int closeCount = 0;
      await tester.pumpWidget(wrap(EdenEdgeContextMenu(
        onDelete: () => deleted = true,
        onClose: () => closeCount += 1,
      )));
      await tester.tap(find.byKey(const ValueKey('edge-delete-action')));
      await tester.pump();
      expect(deleted, isTrue);
      expect(closeCount, 1);
    });

    testWidgets('tapping the dismiss backdrop fires onClose', (tester) async {
      int closeCount = 0;
      await tester.pumpWidget(wrap(EdenEdgeContextMenu(
        onDelete: () {},
        onClose: () => closeCount += 1,
      )));
      await tester.tap(
        find.byKey(const ValueKey('edge-context-menu-dismiss-backdrop')),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(closeCount, 1);
    });

    testWidgets('Esc dismisses', (tester) async {
      int closeCount = 0;
      await tester.pumpWidget(wrap(EdenEdgeContextMenu(
        onDelete: () {},
        onClose: () => closeCount += 1,
      )));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(closeCount, 1);
    });
  });
}
