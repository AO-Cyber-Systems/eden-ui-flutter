import 'package:flutter/material.dart';

import '../../eden_ui.dart';

/// Dev-catalog screen for the A4-c template-block-builder (obj 021).
///
/// Demonstrates [EdenVisualTemplateBuilder] with a hand-built sample invoice
/// template (3 sections, 14 blocks), 5 registered variable groups, and a
/// layout-engine toggle (vertical-stack ↔ freeform).
class TemplateBuilderScreen extends StatefulWidget {
  const TemplateBuilderScreen({super.key});

  @override
  State<TemplateBuilderScreen> createState() => _TemplateBuilderScreenState();
}

class _TemplateBuilderScreenState extends State<TemplateBuilderScreen> {
  late EdenTemplateGraph _graph;
  late EdenTemplateStyleSettings _style;
  late EdenTemplateLayoutSettings _layout;
  EdenTemplateLayoutEngine _engine = const EdenTemplateVerticalStackLayout();

  @override
  void initState() {
    super.initState();
    _graph = _buildInitialDemoGraph();
    _style = const EdenTemplateStyleSettings();
    _layout = const EdenTemplateLayoutSettings();
    _registerSampleVariables();
  }

  void _resetDemo() {
    setState(() {
      _graph = _buildInitialDemoGraph();
      _style = const EdenTemplateStyleSettings();
      _layout = const EdenTemplateLayoutSettings();
      _engine = const EdenTemplateVerticalStackLayout();
    });
  }

  void _registerSampleVariables() {
    EdenTemplateVariablesRegistry.instance
      ..reset()
      ..register('customer', const ['name', 'email', 'phone', 'address'])
      ..register('company', const ['name', 'phone', 'logo', 'address'])
      ..register('appointment', const ['date', 'time', 'service'])
      ..register('invoice', const ['number', 'total', 'dueDate'])
      ..register(
        'line_items',
        const ['description', 'quantity', 'unitPrice'],
      );
  }

  EdenTemplateGraph _replaceBlocks(List<EdenTemplateBlock> blocks) {
    return EdenTemplateGraph(
      id: _graph.id,
      name: _graph.name,
      category: _graph.category,
      version: _graph.version,
      status: _graph.status,
      blocks: blocks,
      createdAt: _graph.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  void _handleAddBlock(
    EdenTemplateBlockDescriptor descriptor,
    EdenTemplateSection section,
    int? insertIndex,
  ) {
    setState(() {
      final sectionBlocks =
          _graph.blocks.where((b) => b.section == section).length;
      final newBlock = EdenTemplateBlock(
        id: 'b${DateTime.now().microsecondsSinceEpoch}',
        type: descriptor.id,
        content: {'label': '${descriptor.displayName} (added)'},
        order: sectionBlocks,
        section: section,
      );
      _graph = _replaceBlocks([..._graph.blocks, newBlock]);
    });
  }

  void _handleDeleteBlock(String blockId) {
    setState(() {
      _graph = _replaceBlocks(
        _graph.blocks.where((b) => b.id != blockId).toList(),
      );
    });
  }

  void _handleReorderBlock(
    EdenTemplateSection section,
    int oldIndex,
    int newIndex,
  ) {
    setState(() {
      final sectionBlocks =
          _graph.blocks.where((b) => b.section == section).toList()
            ..sort((a, b) => a.order.compareTo(b.order));
      if (oldIndex < 0 ||
          oldIndex >= sectionBlocks.length ||
          newIndex < 0 ||
          newIndex >= sectionBlocks.length) {
        return;
      }
      final moved = sectionBlocks.removeAt(oldIndex);
      sectionBlocks.insert(newIndex, moved);
      final reordered = sectionBlocks
          .asMap()
          .entries
          .map(
            (e) => EdenTemplateBlock(
              id: e.value.id,
              type: e.value.type,
              content: e.value.content,
              order: e.key,
              section: e.value.section,
            ),
          )
          .toList();
      final others = _graph.blocks.where((b) => b.section != section).toList();
      _graph = _replaceBlocks([...others, ...reordered]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Template Builder'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _engine is EdenTemplateFreeformLayout
                    ? 'freeform'
                    : 'vertical',
                items: const [
                  DropdownMenuItem(
                    value: 'vertical',
                    child: Text('Vertical Stack'),
                  ),
                  DropdownMenuItem(
                    value: 'freeform',
                    child: Text('Freeform'),
                  ),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _engine = v == 'freeform'
                        ? const EdenTemplateFreeformLayout()
                        : const EdenTemplateVerticalStackLayout();
                  });
                },
              ),
            ),
          ),
          TextButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Reset Demo'),
            onPressed: _resetDemo,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: EdenVisualTemplateBuilder(
        graph: _graph,
        styleSettings: _style,
        layoutSettings: _layout,
        layout: _engine,
        onAddBlock: _handleAddBlock,
        onDeleteBlock: _handleDeleteBlock,
        onUpdateBlock: (_, __) {/* stub — full editor out of scope */},
        onReorderBlock: _handleReorderBlock,
        onChangeStyle: (s) => setState(() => _style = s),
        onChangeLayout: (l) => setState(() => _layout = l),
        onInsertField: (_) {/* stub — wire to editor when available */},
      ),
    );
  }

  static EdenTemplateGraph _buildInitialDemoGraph() {
    return const EdenTemplateGraph(
      id: 'demo-invoice',
      name: 'Sample Invoice Template',
      category: 'Invoice',
      version: 'v1.0',
      status: 'draft',
      blocks: [
        // Header
        EdenTemplateBlock(
          id: 'h1',
          type: 'image',
          content: {'label': '{{company.logo}}'},
          order: 0,
          section: EdenTemplateSection.header,
        ),
        EdenTemplateBlock(
          id: 'h2',
          type: 'text',
          content: {'label': '{{company.name}}'},
          order: 1,
          section: EdenTemplateSection.header,
        ),
        EdenTemplateBlock(
          id: 'h3',
          type: 'text',
          content: {'label': '{{company.address}}'},
          order: 2,
          section: EdenTemplateSection.header,
        ),
        EdenTemplateBlock(
          id: 'h4',
          type: 'divider',
          content: {},
          order: 3,
          section: EdenTemplateSection.header,
        ),
        // Body
        EdenTemplateBlock(
          id: 'b1',
          type: 'text',
          content: {'label': 'Invoice #{{invoice.number}}'},
          order: 0,
          section: EdenTemplateSection.body,
        ),
        EdenTemplateBlock(
          id: 'b2',
          type: 'text',
          content: {'label': 'Bill to: {{customer.name}}'},
          order: 1,
          section: EdenTemplateSection.body,
        ),
        EdenTemplateBlock(
          id: 'b3',
          type: 'text',
          content: {'label': '{{customer.address}}'},
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
          type: 'table',
          content: {'label': 'Line items table'},
          order: 4,
          section: EdenTemplateSection.body,
        ),
        EdenTemplateBlock(
          id: 'b6',
          type: 'text',
          content: {'label': 'Total: {{invoice.total}}'},
          order: 5,
          section: EdenTemplateSection.body,
        ),
        EdenTemplateBlock(
          id: 'b7',
          type: 'text',
          content: {'label': 'Due: {{invoice.dueDate}}'},
          order: 6,
          section: EdenTemplateSection.body,
        ),
        EdenTemplateBlock(
          id: 'b8',
          type: 'signature',
          content: {'label': 'Customer signature'},
          order: 7,
          section: EdenTemplateSection.body,
        ),
        // Footer
        EdenTemplateBlock(
          id: 'f1',
          type: 'text',
          content: {'label': 'Questions? Contact {{company.phone}}'},
          order: 0,
          section: EdenTemplateSection.footer,
        ),
        EdenTemplateBlock(
          id: 'f2',
          type: 'qrCode',
          content: {'label': 'Verification QR'},
          order: 1,
          section: EdenTemplateSection.footer,
        ),
      ],
    );
  }
}
