// Do NOT regenerate via LLM — hand-built fixtures for EdenCaseFileShell.

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenCaseFileShellFixtures {
  EdenCaseFileShellFixtures._();

  static final sampleDocs = [
    EdenCaseFileDocument(
      id: 'doc-1',
      name: 'intake-form.pdf',
      sizeBytes: 1024 * 80,
      uploadedAt: DateTime(2026, 5, 10, 9, 14),
      uploadedBy: 'caseworker.jones@dhhs.gov',
    ),
    EdenCaseFileDocument(
      id: 'doc-2',
      name: 'medical-history.pdf',
      sizeBytes: 1024 * 240,
      uploadedAt: DateTime(2026, 5, 11, 11, 30),
      uploadedBy: 'caseworker.jones@dhhs.gov',
    ),
  ];

  static const sampleContacts = [
    EdenCaseFileContact(
      id: 'c-1',
      name: 'Alex Subject',
      role: 'Subject',
      contactInfo: {'phone': '555-0101', 'email': 'alex@example.com'},
    ),
    EdenCaseFileContact(
      id: 'c-2',
      name: 'Dana Counsel',
      role: 'Counsel',
      contactInfo: {'phone': '555-0202'},
    ),
  ];

  static final sampleNotes = [
    EdenCaseFileNote(
      id: 'n-1',
      author: 'caseworker.jones@dhhs.gov',
      timestamp: DateTime(2026, 5, 10, 10, 0),
      content: 'Initial intake interview completed. No follow-up issues raised.',
    ),
    EdenCaseFileNote(
      id: 'n-2',
      author: 'counsel.smith@law.dhhs.gov',
      timestamp: DateTime(2026, 5, 12, 14, 30),
      content: 'Attorney-client confidential strategy note — do not share.',
      isPrivileged: true,
    ),
  ];

  static final sampleAuditEntries = [
    EdenAuditLogEntry(
      id: 'evt-001',
      timestamp: DateTime(2026, 5, 10, 9, 0),
      actor: 'caseworker.jones@dhhs.gov',
      action: 'created',
      target: 'case-file/CASE-2026-0042',
      category: 'lifecycle',
    ),
    EdenAuditLogEntry(
      id: 'evt-002',
      timestamp: DateTime(2026, 5, 11, 12, 0),
      actor: 'supervisor@dhhs.gov',
      action: 'reviewed',
      target: 'case-file/CASE-2026-0042',
      category: 'review',
    ),
  ];

  static EdenCaseFileData dhhsCase = EdenCaseFileData(
    caseId: 'CASE-2026-0042',
    caseTitle: 'Smith Family — Social services intake',
    status: 'Open',
    openedAt: DateTime(2026, 5, 10),
    assignedTo: 'caseworker.jones@dhhs.gov',
    headerMetadata: const {
      'County': 'Cobb',
      'Program': 'Child welfare',
      'Priority': 'Standard',
    },
    documents: sampleDocs,
    contacts: sampleContacts,
    notes: sampleNotes,
    auditEntries: sampleAuditEntries,
  );

  static EdenCaseFileData classifiedCase = EdenCaseFileData(
    caseId: 'CASE-2026-S-0099',
    caseTitle: 'Classified inquiry',
    status: 'Under Review',
    openedAt: DateTime(2026, 5, 1),
    classification: EdenClassificationLevel.secret,
    documents: const [],
    contacts: const [],
    notes: const [],
    auditEntries: const [],
  );

  static final emptyCase = EdenCaseFileData(
    caseId: 'CASE-EMPTY',
    caseTitle: 'Empty case demo',
    status: 'Open',
    openedAt: DateTime(2026, 5, 17),
  );
}
