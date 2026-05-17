// Do NOT regenerate via LLM — hand-built fixtures for EdenTemplatePalette tests.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';

EdenTemplateBlockDescriptor buildPaletteFixture({
  String id = 'fixture_block',
  String displayName = 'Fixture',
  String description = 'Test fixture',
  IconData icon = Icons.extension,
  String category = 'Content',
  bool isAdvanced = false,
}) => EdenTemplateBlockDescriptor(
  id: id,
  displayName: displayName,
  description: description,
  icon: icon,
  category: category,
  isAdvanced: isAdvanced,
);

Widget wrap(Widget child, {double? width}) {
  Widget body = child;
  if (width != null) {
    body = SizedBox(width: width, child: child);
  }
  return MaterialApp(home: Scaffold(body: body));
}
