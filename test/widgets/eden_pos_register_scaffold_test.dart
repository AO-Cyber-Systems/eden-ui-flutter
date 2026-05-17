import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_pos_register_scaffold_fixtures.dart';

Widget wrap(Widget child, {double width = 1200, double height = 800}) =>
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: width, height: height, child: child),
        ),
      ),
    );

void main() {
  group('EdenPOSRegisterScaffold — wide-mode (≥1024pt) 3-zone layout', () {
    Future<void> pump(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      await tester.pumpWidget(
        wrap(
          EdenPOSRegisterScaffold(
            session: EdenPosSessionFixtures.empty,
            products: EdenPosSessionFixtures.sampleProducts(),
            categories: EdenPosSessionFixtures.sampleCategories,
            animationDuration: Duration.zero,
          ),
          width: 1200,
        ),
      );
    }

    testWidgets('renders 3-zone Row at wide width', (tester) async {
      await pump(tester);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      expect(find.byKey(const ValueKey('eden-pos-3-zone')), findsOneWidget);
      expect(find.byKey(const ValueKey('eden-pos-tabbed')), findsNothing);
    });

    testWidgets('LEFT zone contains EdenQuickAddProductGrid', (tester) async {
      await pump(tester);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      expect(find.byType(EdenQuickAddProductGrid), findsOneWidget);
    });

    testWidgets('LEFT zone contains a search-input AND scan icon button',
        (tester) async {
      await pump(tester);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      expect(find.byType(EdenSearchInput), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_scanner), findsOneWidget);
    });

    testWidgets('CENTER zone shows Attach customer button when no customer',
        (tester) async {
      await pump(tester);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      expect(find.text('Attach customer'), findsOneWidget);
    });

    testWidgets('RIGHT zone shows tender title + Show receipt button',
        (tester) async {
      await pump(tester);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      expect(find.text('Tender'), findsOneWidget);
      expect(find.text('Show receipt'), findsOneWidget);
    });
  });

  group('EdenPOSRegisterScaffold — narrow-mode (<1024pt) tabbed layout', () {
    Future<void> pump(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1100));
      await tester.pumpWidget(
        wrap(
          EdenPOSRegisterScaffold(
            session: EdenPosSessionFixtures.empty,
            products: EdenPosSessionFixtures.sampleProducts(),
            categories: EdenPosSessionFixtures.sampleCategories,
            animationDuration: Duration.zero,
          ),
          width: 800,
          height: 1000,
        ),
      );
    }

    testWidgets('renders tabbed layout at narrow width', (tester) async {
      await pump(tester);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      expect(find.byKey(const ValueKey('eden-pos-tabbed')), findsOneWidget);
      expect(find.byKey(const ValueKey('eden-pos-3-zone')), findsNothing);
    });

    testWidgets('3 tabs visible — Products / Cart / Tender', (tester) async {
      await pump(tester);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      expect(find.widgetWithText(Tab, 'Products'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Cart'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Tender'), findsOneWidget);
    });

    testWidgets('default tab is Products (LEFT zone visible)', (tester) async {
      await pump(tester);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      expect(find.byType(EdenQuickAddProductGrid), findsOneWidget);
    });
  });

  group('EdenPOSRegisterScaffold — mode override', () {
    testWidgets('forceCompact: true at 1200pt → tabbed layout',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1300, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(
          EdenPOSRegisterScaffold(
            session: EdenPosSessionFixtures.empty,
            products: EdenPosSessionFixtures.sampleProducts(),
            categories: EdenPosSessionFixtures.sampleCategories,
            forceCompact: true,
            animationDuration: Duration.zero,
          ),
          width: 1200,
        ),
      );
      expect(find.byKey(const ValueKey('eden-pos-tabbed')), findsOneWidget);
    });

    testWidgets('forceExpanded: true at 800pt → 3-zone layout',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(
          EdenPOSRegisterScaffold(
            session: EdenPosSessionFixtures.empty,
            products: EdenPosSessionFixtures.sampleProducts(),
            categories: EdenPosSessionFixtures.sampleCategories,
            forceExpanded: true,
            animationDuration: Duration.zero,
          ),
          width: 800,
        ),
      );
      expect(find.byKey(const ValueKey('eden-pos-3-zone')), findsOneWidget);
    });
  });

  group('EdenPOSRegisterScaffold — customer attach affordance', () {
    testWidgets('no customer → Attach customer button visible',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1300, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(
          EdenPOSRegisterScaffold(
            session: EdenPosSessionFixtures.empty,
            products: EdenPosSessionFixtures.sampleProducts(),
            animationDuration: Duration.zero,
          ),
          width: 1200,
        ),
      );
      expect(find.text('Attach customer'), findsOneWidget);
    });

    testWidgets('tap Attach customer fires onAttachCustomerRequest',
        (tester) async {
      int fired = 0;
      await tester.binding.setSurfaceSize(const Size(1300, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(
          EdenPOSRegisterScaffold(
            session: EdenPosSessionFixtures.empty,
            products: EdenPosSessionFixtures.sampleProducts(),
            onAttachCustomerRequest: () => fired++,
            animationDuration: Duration.zero,
          ),
          width: 1200,
        ),
      );
      await tester.tap(find.text('Attach customer'));
      await tester.pump();
      expect(fired, 1);
    });

    testWidgets('attached customer → EdenMembershipTierBadge + name visible',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1300, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(
          EdenPOSRegisterScaffold(
            session: EdenPosSessionFixtures.withCustomer,
            products: EdenPosSessionFixtures.sampleProducts(),
            animationDuration: Duration.zero,
          ),
          width: 1200,
        ),
      );
      expect(find.byType(EdenMembershipTierBadge), findsOneWidget);
      expect(find.text('Jane Doe'), findsOneWidget);
      expect(find.text('Attach customer'), findsNothing);
    });

    testWidgets('tap close icon on attached customer fires EdenPosCustomerDetached',
        (tester) async {
      EdenPosSessionEvent? captured;
      await tester.binding.setSurfaceSize(const Size(1300, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(
          EdenPOSRegisterScaffold(
            session: EdenPosSessionFixtures.withCustomer,
            products: EdenPosSessionFixtures.sampleProducts(),
            onSessionEvent: (e) => captured = e,
            animationDuration: Duration.zero,
          ),
          width: 1200,
        ),
      );
      await tester.tap(find.byTooltip('Detach customer'));
      await tester.pump();
      expect(captured, isA<EdenPosCustomerDetached>());
    });
  });

  group('EdenPOSRegisterScaffold — receipt slide-out drawer', () {
    testWidgets('drawer hidden by default; tap Show receipt opens it',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(
          EdenPOSRegisterScaffold(
            session: EdenPosSessionFixtures.midTransaction,
            products: EdenPosSessionFixtures.sampleProducts(),
            animationDuration: Duration.zero,
          ),
          width: 1300,
        ),
      );
      // Initially the drawer is off-screen (Receipt AppBar title not visible).
      expect(find.widgetWithText(AppBar, 'Receipt'), findsNothing);
      await tester.tap(find.text('Show receipt'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Receipt'), findsOneWidget);
      expect(find.byType(EdenReceiptPreview), findsOneWidget);
    });

    testWidgets('drawer close icon hides the drawer', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(
          EdenPOSRegisterScaffold(
            session: EdenPosSessionFixtures.midTransaction,
            products: EdenPosSessionFixtures.sampleProducts(),
            animationDuration: Duration.zero,
          ),
          width: 1300,
        ),
      );
      await tester.tap(find.text('Show receipt'));
      await tester.pumpAndSettle();
      // Receipt drawer's AppBar action close icon.
      await tester.tap(find.descendant(
        of: find.widgetWithText(AppBar, 'Receipt'),
        matching: find.byIcon(Icons.close),
      ));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Receipt'), findsNothing);
    });
  });

  group('EdenPOSRegisterScaffold — session event emission', () {
    testWidgets('tap on a product tile fires EdenPosProductAdded',
        (tester) async {
      EdenPosSessionEvent? captured;
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(
          EdenPOSRegisterScaffold(
            session: EdenPosSessionFixtures.empty,
            products: EdenPosSessionFixtures.sampleProducts(),
            onSessionEvent: (e) => captured = e,
            animationDuration: Duration.zero,
          ),
          width: 1300,
        ),
      );
      await tester.tap(find.text('Espresso Single').first);
      await tester.pump();
      expect(captured, isA<EdenPosProductAdded>());
      expect((captured! as EdenPosProductAdded).product.id, 'p-1');
    });
  });

  group('EdenPOSRegisterScaffold — PCI compliance', () {
    testWidgets('selecting card tender renders EdenSecretField with classified clipboard mode',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(
          EdenPOSRegisterScaffold(
            session: EdenPosSessionFixtures.empty,
            products: EdenPosSessionFixtures.sampleProducts(),
            animationDuration: Duration.zero,
          ),
          width: 1300,
        ),
      );
      // Default tender method is cash; select Card.
      await tester.tap(find.widgetWithText(ChoiceChip, 'card'));
      await tester.pump();
      expect(find.byType(EdenSecretField), findsOneWidget);
      final secret = tester.widget<EdenSecretField>(find.byType(EdenSecretField));
      expect(secret.clipboardMode, EdenSecretClipboardMode.classified);
    });
  });

  group('EdenPOSRegisterScaffold — iPhone-narrow safety', () {
    testWidgets('390pt → tabbed layout + no RenderFlex overflow',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EdenPOSRegisterScaffold(
              session: EdenPosSessionFixtures.empty,
              products: EdenPosSessionFixtures.sampleProducts(),
              animationDuration: Duration.zero,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('eden-pos-tabbed')), findsOneWidget);
    });
  });
}
