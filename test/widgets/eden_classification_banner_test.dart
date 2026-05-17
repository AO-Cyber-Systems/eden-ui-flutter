import 'dart:math' as math;

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_classification_banner_fixtures.dart';

Widget wrap(Widget child, {double width = 400}) =>
    MaterialApp(home: Scaffold(body: SizedBox(width: width, child: child)));

void main() {
  group('EdenClassificationBanner — bar mode federal palette (ICD 710)', () {
    testWidgets('UNCLASSIFIED renders ICD green bg + white fg + bold 14pt', (tester) async {
      await tester.pumpWidget(wrap(const EdenClassificationBanner(
        level: EdenClassificationLevel.unclassified,
      )));
      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.color, EdenClassificationBannerFixtures.icdGreen);
      final text = tester.widget<Text>(find.text('UNCLASSIFIED'));
      expect(text.style?.color, EdenClassificationBannerFixtures.white);
      expect(text.style?.fontWeight, FontWeight.w700);
      expect(text.style?.fontSize, 14);
    });

    testWidgets('CUI renders ICD purple bg + white fg', (tester) async {
      await tester.pumpWidget(wrap(const EdenClassificationBanner(
        level: EdenClassificationLevel.controlledUnclassified,
      )));
      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.color, EdenClassificationBannerFixtures.icdPurple);
      final text = tester.widget<Text>(find.text('CUI'));
      expect(text.style?.color, EdenClassificationBannerFixtures.white);
    });

    testWidgets('SECRET renders ICD red bg + white fg', (tester) async {
      await tester.pumpWidget(wrap(const EdenClassificationBanner(
        level: EdenClassificationLevel.secret,
      )));
      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.color, EdenClassificationBannerFixtures.icdRed);
      final text = tester.widget<Text>(find.text('SECRET'));
      expect(text.style?.color, EdenClassificationBannerFixtures.white);
    });

    testWidgets('TOP SECRET renders ICD orange bg + BLACK fg', (tester) async {
      await tester.pumpWidget(wrap(const EdenClassificationBanner(
        level: EdenClassificationLevel.topSecret,
      )));
      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.color, EdenClassificationBannerFixtures.icdOrange);
      final text = tester.widget<Text>(find.text('TOP SECRET'));
      expect(text.style?.color, EdenClassificationBannerFixtures.black);
    });

    testWidgets('bar minHeight >= 28pt per ICD 710', (tester) async {
      await tester.pumpWidget(wrap(const EdenClassificationBanner(
        level: EdenClassificationLevel.secret,
      )));
      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.constraints?.minHeight, greaterThanOrEqualTo(28));
    });
  });

  group('EdenClassificationBanner — civilian custom level', () {
    testWidgets('custom level uses passed label + bg + fg', (tester) async {
      await tester.pumpWidget(wrap(const EdenClassificationBanner(
        level: EdenClassificationLevel.custom,
        labelText: 'CONFIDENTIAL',
        backgroundColor: Color(0xFFF59E0B),
        foregroundColor: Color(0xFFFFFFFF),
      )));
      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.color, const Color(0xFFF59E0B));
      final text = tester.widget<Text>(find.text('CONFIDENTIAL'));
      expect(text.style?.color, const Color(0xFFFFFFFF));
    });

    testWidgets('lowercase labelText is uppercased', (tester) async {
      await tester.pumpWidget(wrap(const EdenClassificationBanner(
        level: EdenClassificationLevel.custom,
        labelText: 'secret',
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      )));
      expect(find.text('SECRET'), findsOneWidget);
      expect(find.text('secret'), findsNothing);
    });

    testWidgets('EdenSensitivityBanner typedef renders identically', (tester) async {
      await tester.pumpWidget(wrap(const EdenSensitivityBanner(
        level: EdenClassificationLevel.custom,
        labelText: 'INTERNAL USE ONLY',
        backgroundColor: Color(0xFF1F2937),
        foregroundColor: Color(0xFFFFFFFF),
      )));
      expect(find.text('INTERNAL USE ONLY'), findsOneWidget);
      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.color, const Color(0xFF1F2937));
    });
  });

  group('EdenClassificationBanner — watermark mode', () {
    testWidgets('watermark renders Stack with child below + label overlay', (tester) async {
      await tester.pumpWidget(wrap(const EdenClassificationBanner(
        level: EdenClassificationLevel.secret,
        display: EdenClassificationDisplay.watermark,
        child: SizedBox(height: 100, child: Text('payload')),
      )));
      expect(find.byType(Stack), findsAtLeastNWidgets(1));
      expect(find.text('payload'), findsOneWidget);
      expect(find.text('SECRET'), findsOneWidget);
    });

    testWidgets('watermark text is rotated -π/4', (tester) async {
      await tester.pumpWidget(wrap(const EdenClassificationBanner(
        level: EdenClassificationLevel.secret,
        display: EdenClassificationDisplay.watermark,
        child: SizedBox(height: 100, child: Text('payload')),
      )));
      final transforms = tester.widgetList<Transform>(find.byType(Transform));
      // Find the rotation matrix matching -π/4 within tolerance.
      final expected = Matrix4.rotationZ(-math.pi / 4);
      final matches = transforms.where((t) {
        for (var i = 0; i < 16; i++) {
          if ((t.transform.storage[i] - expected.storage[i]).abs() > 0.001) {
            return false;
          }
        }
        return true;
      });
      expect(matches, isNotEmpty,
          reason: 'Expected at least one Transform with -π/4 rotation');
    });

    testWidgets('watermark Opacity ≈ 0.16', (tester) async {
      await tester.pumpWidget(wrap(const EdenClassificationBanner(
        level: EdenClassificationLevel.secret,
        display: EdenClassificationDisplay.watermark,
        child: SizedBox(height: 100, child: Text('payload')),
      )));
      final opacities = tester.widgetList<Opacity>(find.byType(Opacity));
      final hasMatch = opacities.any((o) => (o.opacity - 0.16).abs() < 0.01);
      expect(hasMatch, isTrue);
    });

    testWidgets('watermark mode wraps overlay in IgnorePointer', (tester) async {
      await tester.pumpWidget(wrap(const EdenClassificationBanner(
        level: EdenClassificationLevel.secret,
        display: EdenClassificationDisplay.watermark,
        child: SizedBox(height: 100, child: Text('payload')),
      )));
      expect(find.byType(IgnorePointer), findsAtLeastNWidgets(1));
    });
  });

  group('EdenClassificationBannerScaffold — dual marking', () {
    testWidgets('scaffold renders top banner + child + no bottom by default', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 400,
            child: EdenClassificationBannerScaffold(
              level: EdenClassificationLevel.secret,
              child: Placeholder(),
            ),
          ),
        ),
      ));
      expect(find.text('SECRET'), findsOneWidget);
      expect(find.byType(Placeholder), findsOneWidget);
    });

    testWidgets('scaffold with showBottomBanner renders top + child + bottom', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 400,
            child: EdenClassificationBannerScaffold(
              level: EdenClassificationLevel.secret,
              showBottomBanner: true,
              child: Placeholder(),
            ),
          ),
        ),
      ));
      expect(find.text('SECRET'), findsNWidgets(2));
      expect(find.byType(Placeholder), findsOneWidget);
    });
  });

  group('EdenClassificationBanner — Section 508 a11y', () {
    testWidgets('Semantics label format: "<LABEL> classification banner"', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(const EdenClassificationBanner(
        level: EdenClassificationLevel.secret,
      )));
      final semantics = tester.getSemantics(find.byType(EdenClassificationBanner));
      expect(semantics.label, contains('SECRET'));
      expect(semantics.label, contains('classification banner'));
      handle.dispose();
    });
  });

  group('EdenClassificationBanner — WCAG 2.1 contrast ≥ 4.5 (federal palettes)', () {
    test('sanity: black vs white ratio is 21:1', () {
      final ratio = EdenClassificationBannerFixtures.contrastRatio(
        EdenClassificationBannerFixtures.black,
        EdenClassificationBannerFixtures.white,
      );
      expect(ratio, closeTo(21.0, 0.01));
    });

    test('UNCLASSIFIED green vs white ≥ 4.5', () {
      final ratio = EdenClassificationBannerFixtures.contrastRatio(
        EdenClassificationBannerFixtures.icdGreen,
        EdenClassificationBannerFixtures.white,
      );
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('CUI purple vs white ≥ 4.5', () {
      final ratio = EdenClassificationBannerFixtures.contrastRatio(
        EdenClassificationBannerFixtures.icdPurple,
        EdenClassificationBannerFixtures.white,
      );
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('SECRET red vs white ≥ 4.5', () {
      final ratio = EdenClassificationBannerFixtures.contrastRatio(
        EdenClassificationBannerFixtures.icdRed,
        EdenClassificationBannerFixtures.white,
      );
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('TOP SECRET orange vs BLACK ≥ 4.5', () {
      final ratio = EdenClassificationBannerFixtures.contrastRatio(
        EdenClassificationBannerFixtures.icdOrange,
        EdenClassificationBannerFixtures.black,
      );
      expect(ratio, greaterThanOrEqualTo(4.5));
    });
  });

  group('EdenClassificationBanner — iPhone-narrow (390pt) safety', () {
    testWidgets('TOP SECRET at 390pt: no overflow', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenClassificationBanner(level: EdenClassificationLevel.topSecret),
        width: 390,
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets('extremely long custom label at 390pt: no overflow', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenClassificationBanner(
          level: EdenClassificationLevel.custom,
          labelText: 'EXTREMELY LONG CLASSIFICATION LABEL THAT EXCEEDS NARROW VIEWPORT',
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        width: 390,
      ));
      expect(tester.takeException(), isNull);
    });
  });
}
