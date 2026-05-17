// Do NOT regenerate via LLM — hand-built tests for EdenTemplateModels.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_template_models_fixtures.dart';

void main() {
  group('EdenTemplateSection enum', () {
    test('values are [header, body, footer]', () {
      expect(EdenTemplateSection.values, [
        EdenTemplateSection.header,
        EdenTemplateSection.body,
        EdenTemplateSection.footer,
      ]);
    });

    test('name property', () {
      expect(EdenTemplateSection.header.name, 'header');
      expect(EdenTemplateSection.body.name, 'body');
      expect(EdenTemplateSection.footer.name, 'footer');
    });

    test('round-trip via name', () {
      final s = EdenTemplateSection.values
          .firstWhere((s) => s.name == 'body');
      expect(s, EdenTemplateSection.body);
    });
  });

  group('EdenTemplatePageSize enum', () {
    test('values are [letter, a4, legal]', () {
      expect(EdenTemplatePageSize.values, [
        EdenTemplatePageSize.letter,
        EdenTemplatePageSize.a4,
        EdenTemplatePageSize.legal,
      ]);
    });

    test('letter dimensions (inches)', () {
      expect(EdenTemplatePageSize.letter.widthInches, 8.5);
      expect(EdenTemplatePageSize.letter.heightInches, 11.0);
    });

    test('a4 dimensions (mm)', () {
      expect(EdenTemplatePageSize.a4.widthMm, 210.0);
      expect(EdenTemplatePageSize.a4.heightMm, 297.0);
    });

    test('legal dimensions (inches)', () {
      expect(EdenTemplatePageSize.legal.widthInches, 8.5);
      expect(EdenTemplatePageSize.legal.heightInches, 14.0);
    });

    test('name property', () {
      expect(EdenTemplatePageSize.letter.name, 'letter');
      expect(EdenTemplatePageSize.a4.name, 'a4');
      expect(EdenTemplatePageSize.legal.name, 'legal');
    });
  });

  group('EdenTemplateOrientation enum', () {
    test('values are [portrait, landscape]', () {
      expect(EdenTemplateOrientation.values, [
        EdenTemplateOrientation.portrait,
        EdenTemplateOrientation.landscape,
      ]);
    });

    test('name property', () {
      expect(EdenTemplateOrientation.portrait.name, 'portrait');
      expect(EdenTemplateOrientation.landscape.name, 'landscape');
    });
  });

  group('EdenTemplateBlock value class', () {
    test('constructs with all fields exposed', () {
      const block = EdenTemplateBlock(
        id: 'b1',
        type: 'text',
        content: {'label': 'Hello'},
        order: 0,
        section: EdenTemplateSection.body,
      );
      expect(block.id, 'b1');
      expect(block.type, 'text');
      expect(block.content, {'label': 'Hello'});
      expect(block.order, 0);
      expect(block.section, EdenTemplateSection.body);
    });

    test('accepts arbitrary string type (no enum lock)', () {
      const block = EdenTemplateBlock(
        id: 'b2',
        type: 'made_up_future_type',
        content: {},
        order: 1,
        section: EdenTemplateSection.body,
      );
      expect(block.type, 'made_up_future_type');
    });

    test('content supports nested data', () {
      final block = buildBlockFixture(content: {
        'rows': [
          {'a': 1},
        ],
        'columns': ['c1', 'c2'],
      });
      expect((block.content['rows'] as List).length, 1);
      expect((block.content['columns'] as List).length, 2);
    });

    test('toJson / fromJson round-trip losslessly', () {
      final block = buildBlockFixture(
        id: 'b9',
        type: 'table',
        content: const {'headers': ['A', 'B']},
        order: 3,
        section: EdenTemplateSection.footer,
      );
      final json = block.toJson();
      expect(json['section'], 'footer');
      final restored = EdenTemplateBlock.fromJson(json);
      expect(restored.id, block.id);
      expect(restored.type, block.type);
      expect(restored.order, block.order);
      expect(restored.section, block.section);
      expect(restored.content['headers'], const ['A', 'B']);
    });

    test('equality based on id', () {
      const a = EdenTemplateBlock(
        id: 'b1',
        type: 'text',
        content: {},
        order: 0,
        section: EdenTemplateSection.body,
      );
      const b = EdenTemplateBlock(
        id: 'b1',
        type: 'field',
        content: {'k': 'v'},
        order: 9,
        section: EdenTemplateSection.footer,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('EdenTemplateGraph value class', () {
    test('constructs with all fields exposed', () {
      const graph = EdenTemplateGraph(
        id: 't1',
        name: 'Invoice Template',
        category: 'Invoice',
        version: 'v1.0',
        status: 'draft',
        blocks: [],
      );
      expect(graph.id, 't1');
      expect(graph.name, 'Invoice Template');
      expect(graph.category, 'Invoice');
      expect(graph.version, 'v1.0');
      expect(graph.status, 'draft');
      expect(graph.blocks, isEmpty);
    });

    test('isPublished is false for draft, true for published', () {
      final draft = buildGraphFixture(status: 'draft');
      final pub = buildGraphFixture(status: 'published');
      expect(draft.isPublished, isFalse);
      expect(pub.isPublished, isTrue);
    });

    test('createdAt / updatedAt default null and are settable', () {
      final g0 = buildGraphFixture();
      expect(g0.createdAt, isNull);
      expect(g0.updatedAt, isNull);
      final now = DateTime.utc(2026, 5, 17, 12, 0, 0);
      final g1 = buildGraphFixture(createdAt: now, updatedAt: now);
      expect(g1.createdAt, now);
      expect(g1.updatedAt, now);
    });

    test('round-trips through toJson / fromJson losslessly', () {
      final block = buildBlockFixture(
        id: 'b-r',
        type: 'field',
        content: const {'key': 'name'},
        order: 0,
        section: EdenTemplateSection.body,
      );
      final created = DateTime.utc(2026, 5, 17, 12, 0, 0);
      final graph = buildGraphFixture(
        id: 't42',
        name: 'Receipt',
        category: 'Retail',
        version: 'v0.1',
        status: 'published',
        blocks: [block],
        createdAt: created,
        updatedAt: created,
      );
      final json = graph.toJson();
      expect(json['status'], 'published');
      expect((json['blocks'] as List).length, 1);
      final restored = EdenTemplateGraph.fromJson(json);
      expect(restored.id, graph.id);
      expect(restored.name, graph.name);
      expect(restored.category, graph.category);
      expect(restored.version, graph.version);
      expect(restored.status, graph.status);
      expect(restored.blocks.length, 1);
      expect(restored.blocks.first.id, 'b-r');
      expect(restored.createdAt, created);
      expect(restored.updatedAt, created);
    });

    test('round-trip preserves null timestamps', () {
      final g = buildGraphFixture();
      final restored = EdenTemplateGraph.fromJson(g.toJson());
      expect(restored.createdAt, isNull);
      expect(restored.updatedAt, isNull);
    });

    test('equality based on id', () {
      final a = buildGraphFixture(id: 'x', name: 'A');
      final b = buildGraphFixture(id: 'x', name: 'B');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('EdenTemplateLayoutSettings value class', () {
    test('defaults', () {
      const settings = EdenTemplateLayoutSettings();
      expect(settings.pageSize, EdenTemplatePageSize.letter);
      expect(settings.orientation, EdenTemplateOrientation.portrait);
      expect(settings.marginTop, 0.75);
      expect(settings.marginRight, 0.5);
      expect(settings.marginBottom, 0.75);
      expect(settings.marginLeft, 0.5);
      expect(settings.differentFirstPageHeader, isTrue);
      expect(settings.pageNumbersInFooter, isFalse);
    });

    test('all fields settable via named params', () {
      const settings = EdenTemplateLayoutSettings(
        pageSize: EdenTemplatePageSize.a4,
        orientation: EdenTemplateOrientation.landscape,
        marginTop: 1.0,
        marginRight: 1.0,
        marginBottom: 1.0,
        marginLeft: 1.0,
        differentFirstPageHeader: false,
        pageNumbersInFooter: true,
      );
      expect(settings.pageSize, EdenTemplatePageSize.a4);
      expect(settings.orientation, EdenTemplateOrientation.landscape);
      expect(settings.marginTop, 1.0);
      expect(settings.pageNumbersInFooter, isTrue);
      expect(settings.differentFirstPageHeader, isFalse);
    });

    test('round-trips through toJson / fromJson', () {
      final s = buildLayoutFixture(
        pageSize: EdenTemplatePageSize.legal,
        orientation: EdenTemplateOrientation.landscape,
      );
      final json = s.toJson();
      expect(json['pageSize'], 'legal');
      expect(json['orientation'], 'landscape');
      final restored = EdenTemplateLayoutSettings.fromJson(json);
      expect(restored.pageSize, s.pageSize);
      expect(restored.orientation, s.orientation);
      expect(restored.marginTop, s.marginTop);
      expect(restored.marginRight, s.marginRight);
      expect(restored.marginBottom, s.marginBottom);
      expect(restored.marginLeft, s.marginLeft);
      expect(restored.differentFirstPageHeader, s.differentFirstPageHeader);
      expect(restored.pageNumbersInFooter, s.pageNumbersInFooter);
    });
  });

  group('EdenTemplateStyleSettings value class', () {
    test('defaults', () {
      const settings = EdenTemplateStyleSettings();
      expect(
        settings.brandColor.toARGB32(),
        const Color(0xFFD4A853).toARGB32(),
      );
      expect(settings.fontFamily, 'Plus Jakarta Sans');
      expect(settings.headerFontSize, 16.0);
      expect(settings.bodyFontSize, 11.0);
    });

    test('all fields settable', () {
      const settings = EdenTemplateStyleSettings(
        brandColor: Color(0xFF0000FF),
        fontFamily: 'Roboto',
        headerFontSize: 24.0,
        bodyFontSize: 13.0,
      );
      expect(settings.brandColor, const Color(0xFF0000FF));
      expect(settings.fontFamily, 'Roboto');
      expect(settings.headerFontSize, 24.0);
      expect(settings.bodyFontSize, 13.0);
    });

    test('round-trip via toJson / fromJson', () {
      final s = buildStyleFixture(
        brandColor: const Color(0xFF112233),
        fontFamily: 'Outfit',
        headerFontSize: 20.0,
        bodyFontSize: 12.0,
      );
      final json = s.toJson();
      expect(json['brandColor'], const Color(0xFF112233).toARGB32());
      final restored = EdenTemplateStyleSettings.fromJson(json);
      expect(restored.brandColor.toARGB32(), s.brandColor.toARGB32());
      expect(restored.fontFamily, s.fontFamily);
      expect(restored.headerFontSize, s.headerFontSize);
      expect(restored.bodyFontSize, s.bodyFontSize);
    });
  });

  group('EdenTemplateBlockDescriptor value class', () {
    test('constructs with required fields', () {
      const d = EdenTemplateBlockDescriptor(
        id: 'text',
        displayName: 'Text',
        description: 'Static text content',
        icon: Icons.text_fields,
        category: 'Content',
      );
      expect(d.id, 'text');
      expect(d.displayName, 'Text');
      expect(d.description, 'Static text content');
      expect(d.icon, Icons.text_fields);
      expect(d.category, 'Content');
      expect(d.isAdvanced, isFalse);
      expect(d.placeholderBuilder, isNull);
    });

    test('isAdvanced settable', () {
      final d = buildDescriptorFixture(
        id: 'conditional',
        category: 'Advanced',
        isAdvanced: true,
      );
      expect(d.isAdvanced, isTrue);
    });

    test('placeholderBuilder settable', () {
      Widget builder(BuildContext c, EdenTemplateBlock b) =>
          const SizedBox.shrink();
      final d = buildDescriptorFixture(placeholderBuilder: builder);
      expect(d.placeholderBuilder, isNotNull);
    });
  });

  group('EdenTemplateVariableGroup value class', () {
    test('constructs', () {
      const g = EdenTemplateVariableGroup(
        groupName: 'customer',
        fields: ['name', 'email'],
      );
      expect(g.groupName, 'customer');
      expect(g.fields, const ['name', 'email']);
    });

    test('round-trips through toJson / fromJson', () {
      final g = buildVariableGroupFixture();
      final json = g.toJson();
      final restored = EdenTemplateVariableGroup.fromJson(json);
      expect(restored.groupName, g.groupName);
      expect(restored.fields, g.fields);
    });
  });

  group('copyWith — settings classes (TRD-04 ergonomics)', () {
    test('EdenTemplateLayoutSettings.copyWith preserves untouched fields', () {
      const original = EdenTemplateLayoutSettings();
      final modified = original.copyWith(pageSize: EdenTemplatePageSize.a4);
      expect(modified.pageSize, EdenTemplatePageSize.a4);
      expect(modified.orientation, original.orientation);
      expect(modified.marginTop, original.marginTop);
      expect(modified.marginRight, original.marginRight);
      expect(modified.marginBottom, original.marginBottom);
      expect(modified.marginLeft, original.marginLeft);
      expect(
        modified.differentFirstPageHeader,
        original.differentFirstPageHeader,
      );
      expect(modified.pageNumbersInFooter, original.pageNumbersInFooter);
    });

    test('EdenTemplateStyleSettings.copyWith preserves untouched fields', () {
      const original = EdenTemplateStyleSettings();
      final modified = original.copyWith(brandColor: const Color(0xFF000000));
      expect(modified.brandColor, const Color(0xFF000000));
      expect(modified.fontFamily, original.fontFamily);
      expect(modified.headerFontSize, original.headerFontSize);
      expect(modified.bodyFontSize, original.bodyFontSize);
    });
  });

  group('EdenTemplateMissingVariableException', () {
    test('carries path', () {
      const e = EdenTemplateMissingVariableException('customer.name');
      expect(e.path, 'customer.name');
    });

    test('toString contains path', () {
      const e = EdenTemplateMissingVariableException('customer.name');
      expect(e.toString(), contains('customer.name'));
      expect(e.toString(), contains('Variable not found'));
    });
  });
}
