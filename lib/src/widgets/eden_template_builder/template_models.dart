import 'package:flutter/material.dart';

/// Which page section a template block belongs to.
///
/// Closed set — donor uses String 'header' / 'body' / 'footer' for the same
/// field; library wire shape preserves the same names via [Enum.name].
enum EdenTemplateSection { header, body, footer }

/// Page size for a template's layout.
///
/// Wire shape: serialized via [Enum.name] ('letter' / 'a4' / 'legal') to
/// match donor's String-typed pageSize field.
enum EdenTemplatePageSize { letter, a4, legal }

/// Dimension getters per page size. Inches for US sizes (letter, legal); mm
/// for ISO 216 sizes (a4). Mixed-unit getters return [double.nan] when
/// queried on the wrong unit page size.
extension EdenTemplatePageSizeDimensions on EdenTemplatePageSize {
  double get widthInches {
    switch (this) {
      case EdenTemplatePageSize.letter:
      case EdenTemplatePageSize.legal:
        return 8.5;
      case EdenTemplatePageSize.a4:
        return double.nan;
    }
  }

  double get heightInches {
    switch (this) {
      case EdenTemplatePageSize.letter:
        return 11.0;
      case EdenTemplatePageSize.legal:
        return 14.0;
      case EdenTemplatePageSize.a4:
        return double.nan;
    }
  }

  double get widthMm {
    switch (this) {
      case EdenTemplatePageSize.a4:
        return 210.0;
      case EdenTemplatePageSize.letter:
      case EdenTemplatePageSize.legal:
        return double.nan;
    }
  }

  double get heightMm {
    switch (this) {
      case EdenTemplatePageSize.a4:
        return 297.0;
      case EdenTemplatePageSize.letter:
      case EdenTemplatePageSize.legal:
        return double.nan;
    }
  }
}

/// Page orientation for a template.
enum EdenTemplateOrientation { portrait, landscape }

/// A single block within a template — vertical-agnostic content slot.
///
/// `type` is a String, not an enum — the locked design decision is
/// registry-driven block types ([EdenTemplateBlockRegistry] validates ids at
/// lookup time, NOT at value construction). Arbitrary strings are accepted
/// at this layer.
///
/// `content` is `Map<String, dynamic>` — the consumer fills it per block
/// type (e.g. `{'label': 'Hello'}` for text, `{'rows': [...], 'columns': [...]}`
/// for table). The library never inspects content shape.
@immutable
class EdenTemplateBlock {
  const EdenTemplateBlock({
    required this.id,
    required this.type,
    required this.content,
    required this.order,
    required this.section,
  });

  final String id;
  final String type;
  final Map<String, dynamic> content;
  final int order;
  final EdenTemplateSection section;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'type': type,
        'content': content,
        'order': order,
        'section': section.name,
      };

  factory EdenTemplateBlock.fromJson(Map<String, dynamic> json) {
    final sectionRaw = json['section'] as String? ?? 'body';
    return EdenTemplateBlock(
      id: json['id'] as String,
      type: json['type'] as String,
      content: Map<String, dynamic>.from(
        (json['content'] as Map?) ?? const <String, dynamic>{},
      ),
      order: (json['order'] as num?)?.toInt() ?? 0,
      section: EdenTemplateSection.values.firstWhere(
        (s) => s.name == sectionRaw,
        orElse: () => EdenTemplateSection.body,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is EdenTemplateBlock && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// The root template document — composed of [EdenTemplateBlock]s ordered
/// within header / body / footer sections.
///
/// `status` is a String (NOT enum) — donor uses 'draft' / 'published';
/// library preserves the shape. [isPublished] is the convenience getter.
@immutable
class EdenTemplateGraph {
  const EdenTemplateGraph({
    required this.id,
    required this.name,
    required this.category,
    required this.version,
    required this.status,
    required this.blocks,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String category;
  final String version;
  final String status;
  final List<EdenTemplateBlock> blocks;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isPublished => status == 'published';

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'category': category,
        'version': version,
        'status': status,
        'blocks': blocks.map((b) => b.toJson()).toList(),
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };

  factory EdenTemplateGraph.fromJson(Map<String, dynamic> json) {
    return EdenTemplateGraph(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      version: json['version'] as String,
      status: json['status'] as String,
      blocks: ((json['blocks'] as List?) ?? const [])
          .cast<Map>()
          .map((m) => EdenTemplateBlock.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is EdenTemplateGraph && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Page layout settings — page size, orientation, margins.
///
/// Margins are double (in inches when pageSize is letter/legal; the unit
/// interpretation is consumer's responsibility when pageSize is a4 which is
/// metric). Defaults match donor: 0.75" top/bottom, 0.5" left/right.
@immutable
class EdenTemplateLayoutSettings {
  const EdenTemplateLayoutSettings({
    this.pageSize = EdenTemplatePageSize.letter,
    this.orientation = EdenTemplateOrientation.portrait,
    this.marginTop = 0.75,
    this.marginRight = 0.5,
    this.marginBottom = 0.75,
    this.marginLeft = 0.5,
    this.differentFirstPageHeader = true,
    this.pageNumbersInFooter = false,
  });

  final EdenTemplatePageSize pageSize;
  final EdenTemplateOrientation orientation;
  final double marginTop;
  final double marginRight;
  final double marginBottom;
  final double marginLeft;
  final bool differentFirstPageHeader;
  final bool pageNumbersInFooter;

  EdenTemplateLayoutSettings copyWith({
    EdenTemplatePageSize? pageSize,
    EdenTemplateOrientation? orientation,
    double? marginTop,
    double? marginRight,
    double? marginBottom,
    double? marginLeft,
    bool? differentFirstPageHeader,
    bool? pageNumbersInFooter,
  }) =>
      EdenTemplateLayoutSettings(
        pageSize: pageSize ?? this.pageSize,
        orientation: orientation ?? this.orientation,
        marginTop: marginTop ?? this.marginTop,
        marginRight: marginRight ?? this.marginRight,
        marginBottom: marginBottom ?? this.marginBottom,
        marginLeft: marginLeft ?? this.marginLeft,
        differentFirstPageHeader:
            differentFirstPageHeader ?? this.differentFirstPageHeader,
        pageNumbersInFooter: pageNumbersInFooter ?? this.pageNumbersInFooter,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'pageSize': pageSize.name,
        'orientation': orientation.name,
        'marginTop': marginTop,
        'marginRight': marginRight,
        'marginBottom': marginBottom,
        'marginLeft': marginLeft,
        'differentFirstPageHeader': differentFirstPageHeader,
        'pageNumbersInFooter': pageNumbersInFooter,
      };

  factory EdenTemplateLayoutSettings.fromJson(Map<String, dynamic> json) {
    return EdenTemplateLayoutSettings(
      pageSize: EdenTemplatePageSize.values.firstWhere(
        (e) => e.name == (json['pageSize'] as String? ?? 'letter'),
        orElse: () => EdenTemplatePageSize.letter,
      ),
      orientation: EdenTemplateOrientation.values.firstWhere(
        (e) => e.name == (json['orientation'] as String? ?? 'portrait'),
        orElse: () => EdenTemplateOrientation.portrait,
      ),
      marginTop: (json['marginTop'] as num?)?.toDouble() ?? 0.75,
      marginRight: (json['marginRight'] as num?)?.toDouble() ?? 0.5,
      marginBottom: (json['marginBottom'] as num?)?.toDouble() ?? 0.75,
      marginLeft: (json['marginLeft'] as num?)?.toDouble() ?? 0.5,
      differentFirstPageHeader:
          json['differentFirstPageHeader'] as bool? ?? true,
      pageNumbersInFooter: json['pageNumbersInFooter'] as bool? ?? false,
    );
  }
}

/// Visual style settings — brand color, fonts, sizes.
///
/// Default [brandColor] is `Color(0xFFD4A853)` (donor color — keep until
/// token system has an equivalent). Consumers SHOULD override per-tenant.
/// Default font family is 'Plus Jakarta Sans' (matches obj theme tokens).
@immutable
class EdenTemplateStyleSettings {
  const EdenTemplateStyleSettings({
    // donor color — keep until token system has equivalent
    this.brandColor = const Color(0xFFD4A853),
    this.fontFamily = 'Plus Jakarta Sans',
    this.headerFontSize = 16.0,
    this.bodyFontSize = 11.0,
  });

  final Color brandColor;
  final String fontFamily;
  final double headerFontSize;
  final double bodyFontSize;

  EdenTemplateStyleSettings copyWith({
    Color? brandColor,
    String? fontFamily,
    double? headerFontSize,
    double? bodyFontSize,
  }) =>
      EdenTemplateStyleSettings(
        brandColor: brandColor ?? this.brandColor,
        fontFamily: fontFamily ?? this.fontFamily,
        headerFontSize: headerFontSize ?? this.headerFontSize,
        bodyFontSize: bodyFontSize ?? this.bodyFontSize,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'brandColor': brandColor.toARGB32(),
        'fontFamily': fontFamily,
        'headerFontSize': headerFontSize,
        'bodyFontSize': bodyFontSize,
      };

  factory EdenTemplateStyleSettings.fromJson(Map<String, dynamic> json) {
    return EdenTemplateStyleSettings(
      brandColor: Color(
        (json['brandColor'] as num?)?.toInt() ?? 0xFFD4A853,
      ),
      fontFamily: json['fontFamily'] as String? ?? 'Plus Jakarta Sans',
      headerFontSize: (json['headerFontSize'] as num?)?.toDouble() ?? 16.0,
      bodyFontSize: (json['bodyFontSize'] as num?)?.toDouble() ?? 11.0,
    );
  }
}

/// Descriptor metadata for a registered block type.
///
/// Lives in [EdenTemplateBlockRegistry]. Consumed by the palette (icon +
/// displayName + description grid), the canvas (default placeholder
/// rendering), and the editor panels (category filtering).
///
/// [placeholderBuilder] is the consumer's hook for rendering domain-specific
/// blocks (e.g. PaymentLine, VitalsBlock). When null, the canvas renders a
/// default placeholder (icon + label + subtext).
///
/// Note: the donor distinguished `BlockPaletteItem` (palette render config)
/// from the implicit BlockType. The library collapses both: the palette
/// reads `EdenTemplateBlockDescriptor` instances directly.
@immutable
class EdenTemplateBlockDescriptor {
  const EdenTemplateBlockDescriptor({
    required this.id,
    required this.displayName,
    required this.description,
    required this.icon,
    required this.category,
    this.isAdvanced = false,
    this.placeholderBuilder,
  });

  final String id;
  final String displayName;
  final String description;
  final IconData icon;
  final String category;
  final bool isAdvanced;
  final Widget Function(BuildContext, EdenTemplateBlock)? placeholderBuilder;

  @override
  bool operator ==(Object other) =>
      other is EdenTemplateBlockDescriptor && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// A merge-variable group — the variables panel renders these as group
/// headers with field rows beneath.
@immutable
class EdenTemplateVariableGroup {
  const EdenTemplateVariableGroup({
    required this.groupName,
    required this.fields,
  });

  final String groupName;
  final List<String> fields;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'groupName': groupName,
        'fields': fields,
      };

  factory EdenTemplateVariableGroup.fromJson(Map<String, dynamic> json) {
    return EdenTemplateVariableGroup(
      groupName: json['groupName'] as String,
      fields: ((json['fields'] as List?) ?? const [])
          .map((e) => e as String)
          .toList(),
    );
  }
}

/// Thrown by [EdenTemplateVariablesResolver.resolve] when `throwOnMissing`
/// is true and a token path cannot be resolved against the data map.
class EdenTemplateMissingVariableException implements Exception {
  const EdenTemplateMissingVariableException(this.path);

  final String path;

  @override
  String toString() =>
      'EdenTemplateMissingVariableException: Variable not found: $path';
}
