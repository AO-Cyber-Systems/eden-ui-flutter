// Do NOT regenerate via LLM — hand-built fixtures for EdenTemplateCanvas.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

EdenTemplateGraph buildCanvasGraphFixture() => const EdenTemplateGraph(
  id: 'demo',
  name: 'Demo Template',
  category: 'Invoice',
  version: 'v1.0',
  status: 'draft',
  blocks: [
    EdenTemplateBlock(
      id: 'h1',
      type: 'text',
      content: {'label': 'Header text'},
      order: 0,
      section: EdenTemplateSection.header,
    ),
    EdenTemplateBlock(
      id: 'h2',
      type: 'image',
      content: {'label': 'Logo'},
      order: 1,
      section: EdenTemplateSection.header,
    ),
    EdenTemplateBlock(
      id: 'h3',
      type: 'divider',
      content: {},
      order: 2,
      section: EdenTemplateSection.header,
    ),
    EdenTemplateBlock(
      id: 'b1',
      type: 'text',
      content: {'label': 'Greeting'},
      order: 0,
      section: EdenTemplateSection.body,
    ),
    EdenTemplateBlock(
      id: 'b2',
      type: 'table',
      content: {'label': 'Line items'},
      order: 1,
      section: EdenTemplateSection.body,
    ),
    EdenTemplateBlock(
      id: 'b3',
      type: 'signature',
      content: {'label': 'Sign here'},
      order: 2,
      section: EdenTemplateSection.body,
    ),
    EdenTemplateBlock(
      id: 'b4',
      type: 'spacer',
      content: {},
      order: 3,
      section: EdenTemplateSection.body,
    ),
    EdenTemplateBlock(
      id: 'b5',
      type: 'text',
      content: {'label': 'Closing'},
      order: 4,
      section: EdenTemplateSection.body,
    ),
    EdenTemplateBlock(
      id: 'f1',
      type: 'text',
      content: {'label': 'Page footer text'},
      order: 0,
      section: EdenTemplateSection.footer,
    ),
    EdenTemplateBlock(
      id: 'f2',
      type: 'qrCode',
      content: {},
      order: 1,
      section: EdenTemplateSection.footer,
    ),
  ],
);

EdenTemplateBlock buildCanvasBlockFixture({
  String id = 'fb1',
  String type = 'text',
  Map<String, dynamic> content = const {'label': 'fixture'},
  int order = 0,
  EdenTemplateSection section = EdenTemplateSection.body,
}) => EdenTemplateBlock(
  id: id,
  type: type,
  content: content,
  order: order,
  section: section,
);

Future<void> pumpCanvas(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(1400, 900),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}
