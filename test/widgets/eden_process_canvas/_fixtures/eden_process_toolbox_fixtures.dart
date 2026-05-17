// Do NOT regenerate via LLM — hand-built fixtures for EdenProcessToolbox.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';

List<EdenProcessToolboxCategory> defaultToolboxCategoriesFixture() =>
    EdenProcessToolbox.defaultCategories;

List<EdenProcessToolboxCategory> richToolboxCategoriesFixture() => const [
      EdenProcessToolboxCategory(
        key: 'structure',
        label: 'Structure',
        items: [
          EdenProcessToolboxItem(
            dragType: 'phase',
            label: 'Phase',
            icon: Icons.layers,
            description: 'A stage in your process',
          ),
        ],
      ),
      EdenProcessToolboxCategory(
        key: 'task',
        label: 'Tasks',
        items: [
          EdenProcessToolboxItem(
            dragType: 'task',
            label: 'Task',
            icon: Icons.check_box,
            description: 'Drop on a task to group them',
          ),
          EdenProcessToolboxItem(
            dragType: 'task',
            label: 'Photo gallery',
            icon: Icons.image,
            description: 'Photo task',
            taskConfig: {'runtimeComponent': 'photo_gallery'},
          ),
        ],
      ),
      EdenProcessToolboxCategory(
        key: 'ai',
        label: 'AI Powered',
        items: [
          EdenProcessToolboxItem(
            dragType: 'custom_ai_classify',
            label: 'AI Classify',
            icon: Icons.auto_awesome,
            description: 'AI classifier task',
          ),
          EdenProcessToolboxItem(
            dragType: 'custom_ai_extract',
            label: 'AI Extract',
            icon: Icons.auto_fix_high,
            description: 'AI field extraction',
          ),
        ],
      ),
    ];

List<EdenProcessToolboxTemplate> sampleTemplatesFixture() => const [
      EdenProcessToolboxTemplate(
        id: 1,
        name: 'Onboarding',
        workCategoryId: 100,
        taskCount: 5,
      ),
      EdenProcessToolboxTemplate(
        id: 2,
        name: 'Closeout',
        workCategoryId: 200,
        taskCount: 3,
      ),
      EdenProcessToolboxTemplate(
        id: 3,
        name: 'Inspection',
        workCategoryId: 100,
        taskCount: 8,
      ),
    ];

/// Wraps a toolbox in a MaterialApp + Scaffold with a stub DragTarget that
/// captures any dropped `EdenProcessDragPayload`.
Widget toolboxTestHarness(
  Widget toolbox, {
  void Function(EdenProcessDragPayload)? onDrop,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 600,
        height: 600,
        child: Row(
          children: [
            toolbox,
            Expanded(
              child: DragTarget<EdenProcessDragPayload>(
                onAcceptWithDetails: (details) =>
                    onDrop?.call(details.data),
                builder: (context, candidate, rejected) => Container(
                  color: candidate.isNotEmpty
                      ? Colors.blue.shade50
                      : Colors.grey.shade100,
                  child: const Center(child: Text('Drop here')),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
