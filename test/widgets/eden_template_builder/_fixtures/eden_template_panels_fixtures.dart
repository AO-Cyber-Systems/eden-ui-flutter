// Do NOT regenerate via LLM — hand-built fixtures for EdenTemplate panels.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void registerVariablesFixture() {
  EdenTemplateVariablesRegistry.instance
    ..register('customer', const ['name', 'email', 'phone'])
    ..register('company', const ['name', 'phone', 'address']);
}

EdenTemplateLayoutSettings buildPanelLayoutFixture({
  EdenTemplatePageSize pageSize = EdenTemplatePageSize.letter,
  EdenTemplateOrientation orientation = EdenTemplateOrientation.portrait,
  double marginTop = 0.75,
  double marginRight = 0.5,
  double marginBottom = 0.75,
  double marginLeft = 0.5,
  bool differentFirstPageHeader = true,
  bool pageNumbersInFooter = false,
}) => EdenTemplateLayoutSettings(
  pageSize: pageSize,
  orientation: orientation,
  marginTop: marginTop,
  marginRight: marginRight,
  marginBottom: marginBottom,
  marginLeft: marginLeft,
  differentFirstPageHeader: differentFirstPageHeader,
  pageNumbersInFooter: pageNumbersInFooter,
);

EdenTemplateStyleSettings buildPanelStyleFixture({
  Color brandColor = const Color(0xFFD4A853),
  String fontFamily = 'Plus Jakarta Sans',
  double headerFontSize = 16,
  double bodyFontSize = 11,
}) => EdenTemplateStyleSettings(
  brandColor: brandColor,
  fontFamily: fontFamily,
  headerFontSize: headerFontSize,
  bodyFontSize: bodyFontSize,
);

Future<void> pumpPanel(
  WidgetTester tester,
  Widget child, {
  double width = 360,
}) async {
  await tester.binding.setSurfaceSize(const Size(1200, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: SizedBox(width: width, child: child)),
    ),
  );
}
