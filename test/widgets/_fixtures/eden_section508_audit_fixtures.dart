// Do NOT regenerate via LLM — hand-built fixtures for EdenSection508Audit.

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenSection508AuditFixtures {
  EdenSection508AuditFixtures._();

  static const missingLabelError = EdenSection508Issue(
    severity: EdenSection508Severity.error,
    category: EdenSection508Category.missingSemanticLabel,
    description: 'IconButton at /screens/home has no Semantics label',
    fixHint: 'Add Semantics(label: "Open settings") around the IconButton',
    widgetTypeName: 'IconButton',
  );

  static const contrastWarning = EdenSection508Issue(
    severity: EdenSection508Severity.warning,
    category: EdenSection508Category.insufficientContrast,
    description: 'Text on light gray background — ratio 3.8:1 (needs 4.5:1)',
    fixHint: 'Use Theme.of(context).colorScheme.onSurface instead of Colors.grey',
    widgetTypeName: 'Text',
  );

  static const focusOrderInfo = EdenSection508Issue(
    severity: EdenSection508Severity.info,
    category: EdenSection508Category.missingFocusOrder,
    description: 'Form fields lack explicit FocusTraversalOrder',
    fixHint: 'Wrap form Column in FocusTraversalGroup',
  );

  static const mixed = <EdenSection508Issue>[
    missingLabelError,
    contrastWarning,
    focusOrderInfo,
  ];
}
