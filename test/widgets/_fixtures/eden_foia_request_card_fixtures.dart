// Do NOT regenerate via LLM — hand-built fixtures for EdenFoiaRequestCard.

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenFoiaRequestCardFixtures {
  EdenFoiaRequestCardFixtures._();

  static final fixedNow = DateTime(2026, 5, 15, 12, 0);

  static final farFuture = EdenFoiaRequest(
    id: 'FOIA-2026-0042',
    requesterName: 'Jane Citizen',
    submittedAt: DateTime(2026, 5, 1),
    dueAt: DateTime(2026, 6, 14), // ~30 days from fixedNow
    subject: 'Records concerning policy memo X-2025',
    assignedTo: 'analyst.foia@agency.gov',
    responseDocCount: 12,
  );

  static final dueIn10Days = EdenFoiaRequest(
    id: 'FOIA-2026-0043',
    requesterName: 'John Public',
    submittedAt: DateTime(2026, 5, 1),
    dueAt: DateTime(2026, 5, 25), // 10 days from fixedNow
    subject: 'Emails between agency leadership Q1 2026',
    assignedTo: 'analyst.foia@agency.gov',
    redactionPassStatus: EdenFoiaRedactionStatus.inProgress,
  );

  static final dueIn5Days = EdenFoiaRequest(
    id: 'FOIA-2026-0044',
    requesterName: 'Press Corp',
    submittedAt: DateTime(2026, 5, 1),
    dueAt: DateTime(2026, 5, 20),
    subject: 'Budget allocation Q1',
    exemptionCodes: const ['b1', 'b5', 'b7'],
    redactionPassStatus: EdenFoiaRedactionStatus.complete,
  );

  static final overdue = EdenFoiaRequest(
    id: 'FOIA-2026-0010',
    requesterName: 'Watchdog NGO',
    submittedAt: DateTime(2026, 3, 1),
    dueAt: DateTime(2026, 5, 12), // 3 days BEFORE fixedNow
    subject: 'Personnel records for Director Smith',
    exemptionCodes: const ['b6'],
    redactionPassStatus: EdenFoiaRedactionStatus.blocked,
  );

  static final withClassification = EdenFoiaRequest(
    id: 'FOIA-2026-0099',
    requesterName: 'Inter-agency',
    submittedAt: DateTime(2026, 5, 1),
    dueAt: DateTime(2026, 5, 30),
    subject: 'Classified materials review',
    classification: EdenClassificationLevel.secret,
    exemptionCodes: const ['b1'],
  );
}
