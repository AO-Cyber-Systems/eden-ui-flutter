// Composition slots on EdenDesktopLayout — TRD 23-06 Task 1, cases 6-9.
//
// The point of these cases is that a consumer expresses new rail behaviour
// WITHOUT a library change and a pin bump: it passes an `itemBuilder` /
// `sectionBuilder` instead of waiting for another flag on `EdenNavItem`.
//
// The back-compat proof for "a consumer that passes no builders renders
// unchanged" lives in test/widgets/eden_desktop_layout_test.dart, which must
// stay byte-unmodified.
import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// --- hand-built fixtures (no generated data) -------------------------------

const _home = EdenNavItem(id: 'home', label: 'Home', icon: Icons.home);
const _settings =
    EdenNavItem(id: 'settings', label: 'Settings', icon: Icons.settings);

List<EdenNavItem> _twoLeaves() => const [_home, _settings];

Widget _host(Widget layout) => MaterialApp(home: layout);

void main() {
  group('EdenDesktopLayout composition slots', () {
    testWidgets(
        'case 6: itemBuilder replaces ONE item and leaves the others on the '
        'default renderer', (tester) async {
      await tester.pumpWidget(_host(EdenDesktopLayout(
        navItems: _twoLeaves(),
        selectedId: 'home',
        onNavChanged: (_) {},
        body: const Text('Body'),
        itemBuilder: (context, item, state) {
          if (item.id != 'settings') return null;
          return const Text('CUSTOM SETTINGS ROW');
        },
      )));
      await tester.pumpAndSettle();

      // The consumer's widget replaced exactly that one row...
      expect(find.text('CUSTOM SETTINGS ROW'), findsOneWidget);
      expect(find.text('Settings'), findsNothing);

      // ...and the untouched item still renders through the default builder,
      // icon and all.
      expect(find.text('Home'), findsOneWidget);
      expect(find.byIcon(Icons.home), findsOneWidget);
    });
  });
}
