import 'package:eden_ui_flutter/dev_app/dev_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('EdenDevApp renders the explorer shell', (tester) async {
    // The dev app is now the Flutter component explorer (TRD 38-03): EdenDevApp
    // routes to the StoryShell, whose toolbar is always present even before any
    // stories are registered (the landing canvas shows "Select a story").
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const EdenDevApp());
    await tester.pumpAndSettle();

    // Toolbar group label proves the explorer shell rendered.
    expect(find.text('Profile'), findsOneWidget);
    tester.takeException();
  });
}
