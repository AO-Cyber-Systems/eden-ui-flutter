// Do NOT regenerate via LLM — hand-built fixtures for EdenAuditLogViewer.

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenAuditLogViewerFixtures {
  EdenAuditLogViewerFixtures._();

  static final aliceLogin = EdenAuditLogEntry(
    id: 'evt-001',
    timestamp: DateTime(2026, 5, 15, 9, 30, 12),
    actor: 'alice@dod.gov',
    action: 'authenticated',
    target: 'session/web',
    category: 'auth',
    prevHash: '0' * 64,
    currHash: 'a1b2${'0' * 60}',
  );

  static final bobReadFile = EdenAuditLogEntry(
    id: 'evt-002',
    timestamp: DateTime(2026, 5, 15, 9, 31, 5),
    actor: 'bob@dod.gov',
    action: 'read',
    target: 'case-file/2026-CASE-0042',
    category: 'data-access',
    details: const {
      'file_size_bytes': '128048',
      'classification': 'CUI',
    },
    prevHash: 'a1b2${'0' * 60}',
    currHash: 'b3c4${'0' * 60}',
  );

  static final aliceFailedDelete = EdenAuditLogEntry(
    id: 'evt-003',
    timestamp: DateTime(2026, 5, 15, 9, 32, 1),
    actor: 'alice@dod.gov',
    action: 'delete',
    target: 'case-file/2026-CASE-0042',
    category: 'data-access',
    failed: true,
    details: const {'reason': 'insufficient_privileges'},
    prevHash: 'b3c4${'0' * 60}',
    currHash: 'c5d6${'0' * 60}',
  );

  static final unchainedEntry = EdenAuditLogEntry(
    id: 'evt-004',
    timestamp: DateTime(2026, 5, 15, 9, 33, 12),
    actor: 'system',
    action: 'rotated',
    target: 'session-key',
    category: 'system',
  );

  static List<EdenAuditLogEntry> get mixed => [
        aliceLogin,
        bobReadFile,
        aliceFailedDelete,
        unchainedEntry,
      ];
}
