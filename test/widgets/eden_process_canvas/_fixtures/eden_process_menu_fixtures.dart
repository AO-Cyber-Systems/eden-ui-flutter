// Do NOT regenerate via LLM — hand-built fixtures for EdenProcess context
// menus (objective 006 TRD 006-11).

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';

List<EdenNodeContextMenuAction> phaseMenuActionsFixture({
  void Function()? onAddTask,
  void Function()? onAddTaskGroup,
  void Function()? onEdit,
  void Function()? onDelete,
}) =>
    [
      EdenNodeContextMenuAction(
        label: 'Add Task',
        icon: Icons.check_box,
        onTap: onAddTask ?? () {},
      ),
      EdenNodeContextMenuAction(
        label: 'Add Task Group',
        icon: Icons.folder,
        onTap: onAddTaskGroup ?? () {},
      ),
      EdenNodeContextMenuAction(
        label: 'Edit',
        icon: Icons.edit,
        onTap: onEdit ?? () {},
      ),
      EdenNodeContextMenuAction(
        label: 'Delete',
        icon: Icons.delete,
        destructive: true,
        onTap: onDelete ?? () {},
      ),
    ];

List<EdenNodeContextMenuAction> phaseMenuActionsWithTemplatesFixture({
  void Function(String templateId)? onApplyTemplate,
}) =>
    [
      EdenNodeContextMenuAction(
        label: 'Add Task',
        icon: Icons.check_box,
        onTap: () {},
      ),
      EdenNodeContextMenuAction(
        label: 'Apply Template',
        icon: Icons.menu_book,
        onTap: () {},
        submenuItems: [
          EdenNodeContextMenuAction(
            label: 'Onboarding',
            icon: Icons.description,
            onTap: () => onApplyTemplate?.call('onboarding'),
          ),
          EdenNodeContextMenuAction(
            label: 'Closeout',
            icon: Icons.description,
            onTap: () => onApplyTemplate?.call('closeout'),
          ),
        ],
      ),
      EdenNodeContextMenuAction(
        label: 'Delete',
        icon: Icons.delete,
        destructive: true,
        onTap: () {},
      ),
    ];

List<EdenNodeContextMenuAction> orphanMenuActionsFixture({
  void Function()? onDelete,
}) =>
    [
      EdenNodeContextMenuAction(
        label: 'Delete',
        icon: Icons.delete,
        destructive: true,
        onTap: onDelete ?? () {},
      ),
    ];
