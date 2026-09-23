// Tests for the UI Oracle `wrap()` pump helper.
//
// IMPORT CONVENTION: `test_support/` is a top-level directory, not part of the
// package's `lib/`, so there is no `package:eden_ui_flutter/...` URI for it.
// These tests reach the helpers by RELATIVE import. 23-03's generated story
// tests follow the same convention.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_support/ui_oracle/wrap.dart';

void main() {
  group('wrap()', () {
    testWidgets('case 1: pumps the child at the requested width', (
      WidgetTester tester,
    ) async {
      await wrap(
        tester,
        const SizedBox(key: ValueKey<String>('probe'), height: 40),
        width: 360,
      );

      final Size size = tester.getSize(find.byKey(const ValueKey<String>('probe')));
      expect(size.width, 360);
    });

    testWidgets('case 2: themeMode.dark resolves a dark Theme', (
      WidgetTester tester,
    ) async {
      late Brightness resolved;
      await wrap(
        tester,
        Builder(
          builder: (BuildContext context) {
            resolved = Theme.of(context).brightness;
            return const SizedBox(height: 40);
          },
        ),
        themeMode: ThemeMode.dark,
      );

      expect(resolved, Brightness.dark);
    });

    testWidgets('case 3: themeMode.light resolves a light Theme', (
      WidgetTester tester,
    ) async {
      late Brightness resolved;
      await wrap(
        tester,
        Builder(
          builder: (BuildContext context) {
            resolved = Theme.of(context).brightness;
            return const SizedBox(height: 40);
          },
        ),
        themeMode: ThemeMode.light,
      );

      expect(resolved, Brightness.light);
    });
  });
}
