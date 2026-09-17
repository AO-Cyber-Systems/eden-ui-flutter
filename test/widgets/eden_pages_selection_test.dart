// test/widgets/eden_pages_selection_test.dart
//
// TRD 40-06 — every page shipped by this library renders its content inside a
// selection region, so a page used standalone (i.e. not hosted in an Eden
// layout) is still selectable and copyable.
//
// Fixtures are hand-written inline on purpose: no generated sample data, no
// property-based library. `ownsScaffold` records the structural split the TRD
// asks the SUMMARY to report — 7 pages wrap their own `Scaffold.body`, 3 render
// into a parent's scaffold and wrap the root returned from `build`.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// One library page under test.
class _PageCase {
  const _PageCase({
    required this.name,
    required this.build,
    required this.ownsScaffold,
    required this.marker,
  });

  /// Display name for the test case.
  final String name;

  /// Builds the page with its minimum required arguments.
  final Widget Function() build;

  /// True when the page supplies its own [Scaffold] (wrapper went on
  /// `Scaffold.body`); false when it renders into a parent's scaffold (wrapper
  /// went on the root returned from `build`).
  final bool ownsScaffold;

  /// A string the page renders inside its content area.
  final String marker;
}

final List<_PageCase> _cases = <_PageCase>[
  _PageCase(
    name: 'EdenLoginPage',
    ownsScaffold: true,
    marker: 'Welcome back',
    build: () => EdenLoginPage(onLogin: (String e, String p) async {}),
  ),
  _PageCase(
    name: 'EdenSignUpPage',
    ownsScaffold: true,
    marker: 'Create an account',
    build: () =>
        EdenSignUpPage(onSignUp: (String n, String e, String p) async {}),
  ),
  _PageCase(
    name: 'EdenResetPasswordPage',
    ownsScaffold: true,
    marker: 'Set new password',
    build: () =>
        EdenResetPasswordPage(onResetPassword: (String p) async {}),
  ),
  _PageCase(
    name: 'EdenForgotPasswordPage',
    ownsScaffold: true,
    marker: 'Reset your password',
    build: () =>
        EdenForgotPasswordPage(onSendResetLink: (String e) async {}),
  ),
  _PageCase(
    name: 'EdenOnboardingPage',
    ownsScaffold: true,
    marker: 'Welcome aboard',
    build: () => EdenOnboardingPage(
      steps: const <EdenOnboardingStep>[
        EdenOnboardingStep(title: 'Welcome aboard'),
      ],
      onComplete: () {},
    ),
  ),
  _PageCase(
    name: 'EdenSplashPage',
    ownsScaffold: true,
    marker: 'Eden',
    build: () => const EdenSplashPage(
      logo: FlutterLogo(),
      appName: 'Eden',
      tagline: 'a tagline',
      version: 'v1.2.3',
    ),
  ),
  _PageCase(
    name: 'EdenSupportPanelDemoPage',
    ownsScaffold: true,
    marker: 'Support Panel Demo',
    build: () => const EdenSupportPanelDemoPage(),
  ),
  _PageCase(
    name: 'EdenMaintenancePage',
    ownsScaffold: false,
    marker: "We'll be back soon",
    build: () => const EdenMaintenancePage(),
  ),
  _PageCase(
    name: 'EdenProfilePage',
    ownsScaffold: false,
    marker: 'Ada Lovelace',
    build: () => const EdenProfilePage(
      name: 'Ada Lovelace',
      email: 'ada@example.com',
    ),
  ),
  _PageCase(
    name: 'EdenSettingsPage',
    ownsScaffold: false,
    marker: 'Settings',
    build: () => const EdenSettingsPage(),
  ),
];

void main() {
  /// Hosts [page] the way it is really used: pages that own a [Scaffold] go
  /// straight under [MaterialApp]; the three that render into a parent's
  /// scaffold get one supplied here.
  Widget host(_PageCase c) {
    final Widget page = c.build();
    return MaterialApp(
      home: c.ownsScaffold ? page : Scaffold(body: page),
    );
  }

  group('library pages are selectable', () {
    // Guards against a page being dropped from the table — the table IS the
    // coverage claim, so its size is asserted rather than assumed.
    test('covers all 10 library pages', () {
      expect(_cases.length, 10);
    });

    for (final _PageCase c in _cases) {
      testWidgets('${c.name} renders its content inside a SelectableRegion',
          (tester) async {
        await tester.pumpWidget(host(c));
        // Not pumpAndSettle: the splash page runs a spinner that never
        // settles. Two elapsing pumps instead, so a debounce scheduled during
        // the first build still gets drained.
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));

        expect(find.byType(SelectableRegion), findsAtLeastNWidgets(1),
            reason: '${c.name} must install a selection region');
        expect(find.text(c.marker), findsAtLeastNWidgets(1),
            reason: '${c.name} must still render its content');
        expect(
          find.descendant(
            of: find.byType(SelectableRegion),
            matching: find.text(c.marker),
          ),
          findsAtLeastNWidgets(1),
          reason: '${c.name} content must be INSIDE the region, not merely '
              'beside one',
        );
      });
    }
  });

  group('EdenSplashPage is visually unchanged by the region', () {
    testWidgets('renders identically with the region', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EdenSplashPage(
            logo: FlutterLogo(),
            appName: 'Eden',
            tagline: 'a tagline',
            version: 'v1.2.3',
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));

      // Same finder paths as before the wrapper: SelectionArea renders its
      // child directly, so nothing moves.
      expect(find.byType(FlutterLogo), findsOneWidget);
      expect(find.text('Eden'), findsOneWidget);
      expect(find.text('a tagline'), findsOneWidget);
      expect(find.text('v1.2.3'), findsOneWidget);
      expect(find.byType(EdenSpinner), findsOneWidget);

      // The wrapper went INSIDE the Scaffold, on `body`. If it had been put
      // around the whole page the Scaffold — and its backgroundColor — would
      // sit inside the region instead.
      expect(
        find.descendant(
          of: find.byType(EdenSelectableRegion),
          matching: find.byType(Scaffold),
        ),
        findsNothing,
        reason: 'the region wraps Scaffold.body, not the Scaffold',
      );
    });
  });
}
