// Do NOT regenerate via LLM — hand-built fixtures for EdenTemplate dev catalog.

import 'package:eden_ui_flutter/eden_ui.dart';

EdenTemplateGraph buildDevCatalogDemoGraph() => const EdenTemplateGraph(
  id: 'demo-invoice',
  name: 'Sample Invoice Template',
  category: 'Invoice',
  version: 'v1.0',
  status: 'draft',
  blocks: [
    EdenTemplateBlock(
      id: 'h1',
      type: 'image',
      content: {'label': '{{company.logo}}'},
      order: 0,
      section: EdenTemplateSection.header,
    ),
    EdenTemplateBlock(
      id: 'b1',
      type: 'text',
      content: {'label': 'Invoice #{{invoice.number}}'},
      order: 0,
      section: EdenTemplateSection.body,
    ),
    EdenTemplateBlock(
      id: 'f1',
      type: 'text',
      content: {'label': 'Questions?'},
      order: 0,
      section: EdenTemplateSection.footer,
    ),
  ],
);

void registerDevCatalogVariables() {
  EdenTemplateVariablesRegistry.instance
    ..reset()
    ..register('customer', const ['name', 'email', 'phone', 'address'])
    ..register('company', const ['name', 'phone', 'logo', 'address'])
    ..register('appointment', const ['date', 'time', 'service'])
    ..register('invoice', const ['number', 'total', 'dueDate'])
    ..register('line_items', const ['description', 'quantity', 'unitPrice']);
}
