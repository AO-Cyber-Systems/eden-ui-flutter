// Hand-built fixtures for EdenSchemaForm tests.
//
// No LLM-generated test data. Schemas are small, deterministic, and
// shaped after the CmsFrontmatterForm donor so the intent is readable.
//
// Do NOT regenerate via LLM. Extend by hand when adding new field types.

import 'package:eden_ui_flutter/src/widgets/eden_schema_form.dart';

/// Fixture factory for EdenSchemaForm tests.
class EdenSchemaFormFixtures {
  EdenSchemaFormFixtures._();

  // ---------------------------------------------------------------------------
  // Schemas
  // ---------------------------------------------------------------------------

  /// Minimal schema: one text field, no required constraint.
  static List<EdenSchemaField> get singleTextField => const [
        EdenSchemaField(
          key: 'title',
          label: 'Title',
          type: EdenSchemaFieldType.text,
        ),
      ];

  /// Schema with a required text field — used for validation tests.
  static List<EdenSchemaField> get requiredTextField => const [
        EdenSchemaField(
          key: 'name',
          label: 'Name',
          type: EdenSchemaFieldType.text,
          required: true,
        ),
      ];

  /// Schema with a select field (3 options).
  static List<EdenSchemaField> get selectField => const [
        EdenSchemaField(
          key: 'status',
          label: 'Status',
          type: EdenSchemaFieldType.select,
          selectOptions: ['Draft', 'Published', 'Archived'],
        ),
      ];

  /// Schema with a toggle field.
  static List<EdenSchemaField> get toggleField => const [
        EdenSchemaField(
          key: 'visible',
          label: 'Visible',
          type: EdenSchemaFieldType.toggle,
        ),
      ];

  /// Schema with a number field.
  static List<EdenSchemaField> get numberField => const [
        EdenSchemaField(
          key: 'sort_order',
          label: 'Sort Order',
          type: EdenSchemaFieldType.number,
        ),
      ];

  /// Schema with a mediaUrl field.
  static List<EdenSchemaField> get mediaUrlField => const [
        EdenSchemaField(
          key: 'hero_image',
          label: 'Hero Image',
          type: EdenSchemaFieldType.mediaUrl,
        ),
      ];

  /// Multi-field schema: text + select + toggle + number.
  static List<EdenSchemaField> get multiFieldSchema => const [
        EdenSchemaField(
          key: 'title',
          label: 'Title',
          type: EdenSchemaFieldType.text,
        ),
        EdenSchemaField(
          key: 'category',
          label: 'Category',
          type: EdenSchemaFieldType.select,
          selectOptions: ['News', 'Blog', 'Event'],
        ),
        EdenSchemaField(
          key: 'published',
          label: 'Published',
          type: EdenSchemaFieldType.toggle,
        ),
        EdenSchemaField(
          key: 'priority',
          label: 'Priority',
          type: EdenSchemaFieldType.number,
        ),
      ];

  /// Schema with a locked field key — used for locked-field tests.
  static List<EdenSchemaField> get schemaWithSlug => const [
        EdenSchemaField(
          key: 'slug',
          label: 'Slug',
          type: EdenSchemaFieldType.text,
        ),
        EdenSchemaField(
          key: 'title',
          label: 'Title',
          type: EdenSchemaFieldType.text,
        ),
      ];

  // ---------------------------------------------------------------------------
  // Initial values
  // ---------------------------------------------------------------------------

  /// Pre-filled values for singleTextField.
  static Map<String, dynamic> get singleTextInitialValues => const {
        'title': 'Hello World',
      };

  /// Pre-filled values for multiFieldSchema.
  static Map<String, dynamic> get multiFieldInitialValues => const {
        'title': 'My Post',
        'category': 'Blog',
        'published': true,
        'priority': 5,
      };

  /// Pre-filled values for schemaWithSlug.
  static Map<String, dynamic> get slugInitialValues => const {
        'slug': 'hello-world',
        'title': 'Hello World',
      };
}
