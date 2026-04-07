import 'dart:typed_data';

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: Center(child: child)));
  }

  group('EdenAvatar', () {
    testWidgets('renders initials when provided', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenAvatar(initials: 'JD'),
      ));
      expect(find.text('JD'), findsOneWidget);
    });

    testWidgets('renders with each size variant', (tester) async {
      for (final size in EdenAvatarSize.values) {
        await tester.pumpWidget(wrap(
          EdenAvatar(initials: 'AB', size: size),
        ));
        expect(find.text('AB'), findsOneWidget);
      }
    });

    testWidgets('handles missing initials gracefully', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenAvatar(),
      ));
      // Should show '?' fallback
      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('renders CircleAvatar with image', (tester) async {
      // Use a MemoryImage to avoid asset loading issues in tests
      final bytes = Uint8List.fromList([
        // Minimal valid 1x1 transparent PNG
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00,
        0x0D, 0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00,
        0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89,
        0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x62,
        0x00, 0x00, 0x00, 0x02, 0x00, 0x01, 0xE5, 0x27, 0xDE, 0xFC, 0x00,
        0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
      ]);
      await tester.pumpWidget(wrap(
        EdenAvatar(image: MemoryImage(bytes)),
      ));
      // Should have a CircleAvatar with backgroundImage
      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('truncates initials to 2 characters', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenAvatar(initials: 'ABC'),
      ));
      expect(find.text('AB'), findsOneWidget);
    });

    testWidgets('renders single character initials', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenAvatar(initials: 'J'),
      ));
      expect(find.text('J'), findsOneWidget);
    });

    testWidgets('renders with status indicator', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenAvatar(initials: 'JD', status: EdenAvatarStatus.online),
      ));
      // With status, the avatar wraps CircleAvatar + Positioned in a Stack
      expect(find.byType(Positioned), findsOneWidget);
    });

    testWidgets('renders all status types without error', (tester) async {
      for (final status in EdenAvatarStatus.values) {
        await tester.pumpWidget(wrap(
          EdenAvatar(initials: 'JD', status: status),
        ));
        expect(find.byType(Positioned), findsOneWidget);
      }
    });

    testWidgets('no status indicator when no status', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenAvatar(initials: 'JD'),
      ));
      expect(find.byType(Positioned), findsNothing);
    });

    testWidgets('renders with custom background color', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenAvatar(initials: 'AB', backgroundColor: Colors.red),
      ));
      expect(find.text('AB'), findsOneWidget);
    });
  });
}
