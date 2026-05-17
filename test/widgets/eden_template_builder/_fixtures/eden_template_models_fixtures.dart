// Do NOT regenerate via LLM — hand-built fixtures for EdenTemplateModels.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';

EdenTemplateBlock buildBlockFixture({
  String id = 'b1',
  String type = 'text',
  Map<String, dynamic> content = const {'label': 'Sample'},
  int order = 0,
  EdenTemplateSection section = EdenTemplateSection.body,
}) => EdenTemplateBlock(
  id: id,
  type: type,
  content: content,
  order: order,
  section: section,
);

EdenTemplateGraph buildGraphFixture({
  String id = 't1',
  String name = 'Invoice Template',
  String category = 'Invoice',
  String version = 'v1.0',
  String status = 'draft',
  List<EdenTemplateBlock> blocks = const [],
  DateTime? createdAt,
  DateTime? updatedAt,
}) => EdenTemplateGraph(
  id: id,
  name: name,
  category: category,
  version: version,
  status: status,
  blocks: blocks,
  createdAt: createdAt,
  updatedAt: updatedAt,
);

EdenTemplateLayoutSettings buildLayoutFixture({
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

EdenTemplateStyleSettings buildStyleFixture({
  Color brandColor = const Color(0xFFD4A853),
  String fontFamily = 'Plus Jakarta Sans',
  double headerFontSize = 16.0,
  double bodyFontSize = 11.0,
}) => EdenTemplateStyleSettings(
  brandColor: brandColor,
  fontFamily: fontFamily,
  headerFontSize: headerFontSize,
  bodyFontSize: bodyFontSize,
);

EdenTemplateBlockDescriptor buildDescriptorFixture({
  String id = 'text',
  String displayName = 'Text',
  String description = 'Static text content',
  IconData icon = Icons.text_fields,
  String category = 'Content',
  bool isAdvanced = false,
  Widget Function(BuildContext, EdenTemplateBlock)? placeholderBuilder,
}) => EdenTemplateBlockDescriptor(
  id: id,
  displayName: displayName,
  description: description,
  icon: icon,
  category: category,
  isAdvanced: isAdvanced,
  placeholderBuilder: placeholderBuilder,
);

EdenTemplateVariableGroup buildVariableGroupFixture({
  String groupName = 'customer',
  List<String> fields = const ['name', 'email'],
}) => EdenTemplateVariableGroup(groupName: groupName, fields: fields);
