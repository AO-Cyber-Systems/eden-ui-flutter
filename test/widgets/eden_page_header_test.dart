import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('EdenPageHeader', () {
    testWidgets(
      'renders without overflow at iPhone-narrow (390x844, dpr 1.0) with 3 ElevatedButton actions',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(wrap(EdenPageHeader(
          title: 'Settings',
          actions: [
            for (int i = 0; i < 3; i++)
              ElevatedButton(
                onPressed: () {},
                child: Text('Action $i'),
              ),
          ],
        )));

        expect(tester.takeException(), isNull);
        expect(find.text('Settings'), findsOneWidget);
        expect(find.text('Action 0'), findsOneWidget);
        expect(find.text('Action 1'), findsOneWidget);
        expect(find.text('Action 2'), findsOneWidget);
      },
    );

    testWidgets(
      'renders original Row layout at iPhone-narrow when actions is null (no breakpoint logic triggered)',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(wrap(
          const EdenPageHeader(title: 'Profile'),
        ));

        expect(tester.takeException(), isNull);
        expect(find.text('Profile'), findsOneWidget);
      },
    );

    testWidgets(
      'renders original Row layout at iPhone-narrow when actions is empty list',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(wrap(
          const EdenPageHeader(title: 'Profile', actions: []),
        ));

        expect(tester.takeException(), isNull);
        expect(find.text('Profile'), findsOneWidget);
      },
    );

    testWidgets(
      'stacks actions below title block at iPhone-narrow with leading widget + 2 actions',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(wrap(EdenPageHeader(
          title: 'Account',
          leading: const Icon(Icons.person),
          description: 'Manage your details',
          actions: [
            TextButton(
              onPressed: () {},
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Save'),
            ),
          ],
        )));

        expect(tester.takeException(), isNull);
        expect(find.byIcon(Icons.person), findsOneWidget);
        expect(find.text('Account'), findsOneWidget);
        expect(find.text('Manage your details'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Save'), findsOneWidget);
      },
    );

    testWidgets(
      'preserves side-by-side layout at desktop width (1024x768, dpr 1.0) with 3 actions',
      (tester) async {
        tester.view.physicalSize = const Size(1024, 768);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(wrap(EdenPageHeader(
          title: 'Settings',
          actions: [
            for (int i = 0; i < 3; i++)
              ElevatedButton(
                onPressed: () {},
                child: Text('Action $i'),
              ),
          ],
        )));

        expect(tester.takeException(), isNull);
        expect(find.text('Settings'), findsOneWidget);
        expect(find.text('Action 0'), findsOneWidget);
        expect(find.text('Action 1'), findsOneWidget);
        expect(find.text('Action 2'), findsOneWidget);

        // Side-by-side proof: title and first action share approximately the
        // same dy (within 50pt tolerance).
        final titleDy = tester.getTopLeft(find.text('Settings')).dy;
        final actionDy = tester.getTopLeft(find.text('Action 0')).dy;
        expect(
          (titleDy - actionDy).abs() < 50,
          true,
          reason:
              'title dy=$titleDy and action dy=$actionDy should be within 50pt (same row)',
        );
      },
    );

    testWidgets(
      'asserts actions are vertically stacked below title at iPhone-narrow (positional check)',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(wrap(EdenPageHeader(
          title: 'Settings',
          actions: [
            for (int i = 0; i < 3; i++)
              ElevatedButton(
                onPressed: () {},
                child: Text('Action $i'),
              ),
          ],
        )));

        expect(tester.takeException(), isNull);
        final titleDy = tester.getTopLeft(find.text('Settings')).dy;
        final actionDy = tester.getTopLeft(find.text('Action 0')).dy;
        expect(
          titleDy < actionDy,
          true,
          reason:
              'title dy=$titleDy should be ABOVE action dy=$actionDy (stacked vertically)',
        );
      },
    );

    testWidgets(
      'description-omitted variant renders title-only at narrow and wide',
      (tester) async {
        // Narrow first.
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(wrap(EdenPageHeader(
          title: 'No Desc',
          actions: [
            ElevatedButton(
              onPressed: () {},
              child: const Text('OK'),
            ),
          ],
        )));

        expect(tester.takeException(), isNull);
        expect(find.text('No Desc'), findsOneWidget);
        expect(find.text('OK'), findsOneWidget);

        // Now wide.
        tester.view.physicalSize = const Size(1024, 768);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(wrap(EdenPageHeader(
          title: 'No Desc',
          actions: [
            ElevatedButton(
              onPressed: () {},
              child: const Text('OK'),
            ),
          ],
        )));

        expect(tester.takeException(), isNull);
        expect(find.text('No Desc'), findsOneWidget);
        expect(find.text('OK'), findsOneWidget);
      },
    );

    testWidgets(
      'long-title variant (80+ chars) wraps within title block at narrow without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(wrap(EdenPageHeader(
          title: 'A' * 90,
          actions: [
            ElevatedButton(
              onPressed: () {},
              child: const Text('Go'),
            ),
          ],
        )));

        expect(tester.takeException(), isNull);
      },
    );
  });
}
