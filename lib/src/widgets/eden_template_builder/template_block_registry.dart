import 'package:flutter/material.dart';

import 'template_models.dart';

/// Singleton registry of [EdenTemplateBlockDescriptor]s — parity row R-1.
///
/// Library ships 12 defaults pre-registered (10 Content + 2 Advanced),
/// matching donor's most-used block types. Verticals register additional
/// block types (e.g. trades registers `payment_line`, medical registers
/// `vitals_block`, etc).
///
/// Test isolation: call `resetToDefaults()` in `setUp()` to restore the 12
/// defaults and clear any test-registered descriptors.
class EdenTemplateBlockRegistry {
  EdenTemplateBlockRegistry._() {
    _registerDefaults();
  }

  static final EdenTemplateBlockRegistry instance =
      EdenTemplateBlockRegistry._();

  final Map<String, EdenTemplateBlockDescriptor> _descriptors = {};

  static const List<EdenTemplateBlockDescriptor> _defaults = [
    EdenTemplateBlockDescriptor(
      id: 'text',
      displayName: 'Text',
      description: 'Static text content',
      icon: Icons.text_fields,
      category: 'Content',
    ),
    EdenTemplateBlockDescriptor(
      id: 'field',
      displayName: 'Field',
      description: 'Merge field placeholder',
      icon: Icons.input,
      category: 'Content',
    ),
    EdenTemplateBlockDescriptor(
      id: 'table',
      displayName: 'Table',
      description: 'Data table layout',
      icon: Icons.table_chart_outlined,
      category: 'Content',
    ),
    EdenTemplateBlockDescriptor(
      id: 'list',
      displayName: 'List',
      description: 'Bulleted or numbered',
      icon: Icons.format_list_bulleted,
      category: 'Content',
    ),
    EdenTemplateBlockDescriptor(
      id: 'photoGrid',
      displayName: 'Photo Grid',
      description: 'Image gallery grid',
      icon: Icons.grid_view,
      category: 'Content',
    ),
    EdenTemplateBlockDescriptor(
      id: 'signature',
      displayName: 'Signature',
      description: 'Signature capture area',
      icon: Icons.draw_outlined,
      category: 'Content',
    ),
    EdenTemplateBlockDescriptor(
      id: 'divider',
      displayName: 'Divider',
      description: 'Horizontal separator',
      icon: Icons.horizontal_rule,
      category: 'Content',
    ),
    EdenTemplateBlockDescriptor(
      id: 'spacer',
      displayName: 'Spacer',
      description: 'Vertical whitespace',
      icon: Icons.expand,
      category: 'Content',
    ),
    EdenTemplateBlockDescriptor(
      id: 'image',
      displayName: 'Image',
      description: 'Uploaded image',
      icon: Icons.image_outlined,
      category: 'Content',
    ),
    EdenTemplateBlockDescriptor(
      id: 'qrCode',
      displayName: 'QR Code',
      description: 'Generated QR code',
      icon: Icons.qr_code,
      category: 'Content',
    ),
    EdenTemplateBlockDescriptor(
      id: 'conditional',
      displayName: 'Conditional',
      description: 'Show/hide by rule',
      icon: Icons.alt_route,
      category: 'Advanced',
      isAdvanced: true,
    ),
    EdenTemplateBlockDescriptor(
      id: 'repeater',
      displayName: 'Repeater',
      description: 'Repeating row group',
      icon: Icons.repeat,
      category: 'Advanced',
      isAdvanced: true,
    ),
  ];

  void _registerDefaults() {
    for (final d in _defaults) {
      _descriptors[d.id] = d;
    }
  }

  /// Register a descriptor — adds (or overwrites by id).
  void register(EdenTemplateBlockDescriptor descriptor) {
    _descriptors[descriptor.id] = descriptor;
  }

  /// Look up a descriptor by id. Returns null when missing.
  EdenTemplateBlockDescriptor? lookup(String id) => _descriptors[id];

  /// All registered descriptors, sorted by category then displayName.
  List<EdenTemplateBlockDescriptor> all() {
    final list = _descriptors.values.toList()
      ..sort((a, b) {
        final c = a.category.compareTo(b.category);
        if (c != 0) return c;
        return a.displayName.compareTo(b.displayName);
      });
    return List.unmodifiable(list);
  }

  /// Descriptors in [category], sorted by displayName.
  List<EdenTemplateBlockDescriptor> byCategory(String category) {
    final list = _descriptors.values
        .where((d) => d.category == category)
        .toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
    return List.unmodifiable(list);
  }

  /// Clear all registrations (including library defaults). Use sparingly.
  void reset() => _descriptors.clear();

  /// Reset to the 12 library defaults. Use this in test `setUp()`.
  void resetToDefaults() {
    _descriptors.clear();
    _registerDefaults();
  }
}
