// Do NOT regenerate via LLM — hand-built fixtures for EdenDelayNode + EdenMergeNode.

import 'package:eden_ui_flutter/eden_ui.dart';

EdenDiagramNodeContext delayNodeContextFixture({
  String delayType = 'fixed',
  int minutes = 30,
  Map<String, dynamic> delayConfig = const {},
  bool selected = false,
}) {
  return EdenDiagramNodeContext(
    node: EdenDiagramNode(
      id: 'delay-0',
      x: 0,
      y: 0,
      width: 180,
      height: 80,
      label: 'Delay',
      data: {
        'nodeType': 'delay',
        'delayType': delayType,
        'delayMinutes': minutes,
        'delayConfig': delayConfig,
      },
    ),
    selected: selected,
  );
}

EdenDiagramNodeContext mergeNodeContextFixture({bool selected = false}) {
  return EdenDiagramNodeContext(
    node: EdenDiagramNode(
      id: 'merge-0',
      x: 0,
      y: 0,
      width: 160,
      height: 80,
      label: 'Merge',
      data: const {'nodeType': 'merge'},
    ),
    selected: selected,
  );
}
