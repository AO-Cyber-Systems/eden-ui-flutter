// Do NOT regenerate via LLM — hand-built fixtures for EdenPermissionMatrix
// federal-roles enhancement (TRD 011-07).

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenPermissionMatrixFixtures {
  EdenPermissionMatrixFixtures._();

  static const baselinePermissions = [
    EdenPermission(
      id: 'view_audit_log',
      label: 'View audit log',
      category: 'Audit',
    ),
    EdenPermission(
      id: 'export_audit_log',
      label: 'Export audit log',
      category: 'Audit',
    ),
    EdenPermission(
      id: 'modify_security_policy',
      label: 'Modify security policy',
      category: 'Security',
    ),
    EdenPermission(
      id: 'create_user',
      label: 'Create user',
      category: 'User management',
    ),
  ];

  static const breakGlassJustificationOk =
      'Emergency incident response per ticket INC-2026-0042 — '
      'override authorized by ISSM on-call.';
  static const breakGlassJustificationTooShort = 'fix it';
}
