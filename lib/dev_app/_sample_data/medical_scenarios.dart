// lib/dev_app/_sample_data/medical_scenarios.dart
//
// Hand-built sample data for the dev catalog. Do NOT regenerate via LLM —
// mutate in-place when downstream verticals shift. Real-world data has
// irregular distributions; uniform patterns (Customer 1/2/3, identical
// timestamps) are a smell that this file was AI-touched. Catch and fix.
//
// Catalog "today" anchor: DateTime(2026, 5, 16). All relative-time fixtures
// compute from this anchor for snapshot stability.

import 'package:flutter/material.dart';

import 'package:eden_ui_flutter/eden_ui.dart';

import 'cross_cutting.dart';

/// Consent clause used in EdenConsentFlow + intake demos (medical-specific
/// flavor; clause structure mirrors what the library widget accepts).
class DemoConsentClause {
  const DemoConsentClause({
    required this.id,
    required this.title,
    required this.body,
    this.required = true,
  });

  final String id;
  final String title;
  final String body;
  final bool required;
}

/// Intake question fixture used by EdenIntakeForm demos.
class DemoIntakeQuestion {
  const DemoIntakeQuestion({
    required this.id,
    required this.prompt,
    required this.type,
    this.options,
    this.required = false,
    this.visibleWhenAnswerId,
    this.visibleWhenAnswerEquals,
  });

  final String id;

  /// 'text' | 'longText' | 'singleChoice' | 'multipleChoice' | 'number' |
  /// 'date' | 'yesNo'
  final String type;
  final String prompt;
  final List<String>? options;
  final bool required;

  /// Conditional visibility: shown only if [visibleWhenAnswerId]'s response
  /// equals [visibleWhenAnswerEquals].
  final String? visibleWhenAnswerId;
  final String? visibleWhenAnswerEquals;
}

/// Medical / home-visit vertical fixtures.
///
/// Provider roster: Dr. Anjali Patel (MD), Khan (NP), Rosa Soto (RN).
/// Names are HIPAA-safe placeholders ("J. Doe", "MRN 44291").
class MedicalScenarios {
  // ---------------------------------------------------------------------------
  // REALISTIC FIXTURES
  // ---------------------------------------------------------------------------

  /// Week of provider visits. Mix of clinic appointments + home visits.
  static List<EdenSchedulerEvent> get weekVisits {
    final monday = DateTime(2026, 5, 11);
    return <EdenSchedulerEvent>[
      EdenSchedulerEvent(
        id: 'md-evt-001',
        title: 'Home visit — MRN 44291',
        description: 'Diabetes panel + medication review. Bring lancets.',
        start: monday.add(const Duration(hours: 9)),
        end: monday.add(const Duration(hours: 10)),
        assignee: 'Dr. Patel',
        color: const Color(0xFF0E7490),
        status: 'scheduled',
        type: 'home_visit',
        location: const EdenSchedulerLocation(
          name: 'Patient residence',
          address: '917 Lullwater Rd NE, Atlanta, GA',
        ),
      ),
      EdenSchedulerEvent(
        id: 'md-evt-002',
        title: 'Clinic — wellness check',
        start: monday.add(const Duration(hours: 11)),
        end: monday.add(const Duration(hours: 11, minutes: 30)),
        assignee: 'NP Khan',
        color: const Color(0xFF0F766E),
        status: 'completed',
        type: 'clinic',
      ),
      EdenSchedulerEvent(
        id: 'md-evt-003',
        title: 'Home visit — MRN 51208',
        description: 'Post-discharge follow-up day 3 of 7.',
        start: monday.add(const Duration(days: 1, hours: 8, minutes: 30)),
        end: monday.add(const Duration(days: 1, hours: 9, minutes: 30)),
        assignee: 'Rosa Soto, RN',
        color: const Color(0xFFB91C1C),
        status: 'in_progress',
        type: 'home_visit',
        readiness: EdenSchedulerEventReadiness.warning,
        dispatchIssue: 'Consent form not on file',
      ),
      EdenSchedulerEvent(
        id: 'md-evt-004',
        title: 'Telehealth visit (virtual)',
        start: monday.add(const Duration(days: 1, hours: 13)),
        end: monday.add(const Duration(days: 1, hours: 13, minutes: 30)),
        assignee: 'Dr. Patel',
        color: const Color(0xFF6366F1),
        status: 'scheduled',
        type: 'telehealth',
      ),
      EdenSchedulerEvent(
        id: 'md-evt-005',
        title: 'Wound-care visit — MRN 33870',
        start: monday.add(const Duration(days: 2, hours: 14)),
        end: monday.add(const Duration(days: 2, hours: 15)),
        assignee: 'Rosa Soto, RN',
        color: const Color(0xFFB91C1C),
        type: 'home_visit',
      ),
      EdenSchedulerEvent(
        id: 'md-evt-006',
        title: 'Care team huddle',
        start: monday.add(const Duration(days: 3, hours: 8)),
        end: monday.add(const Duration(days: 3, hours: 8, minutes: 30)),
        assignee: 'Dr. Patel',
        color: const Color(0xFF6B7280),
        type: 'meeting',
      ),
      EdenSchedulerEvent(
        id: 'md-evt-007',
        title: 'Home visit — MRN 18047',
        description: 'Initial intake. Run full panel + consent.',
        start: monday.add(const Duration(days: 4, hours: 10, minutes: 30)),
        end: monday.add(const Duration(days: 4, hours: 12)),
        assignee: 'NP Khan',
        color: const Color(0xFF0F766E),
        type: 'home_visit',
      ),
    ];
  }

  static const EdenInsightContent readmissionRiskInsight = EdenInsightContent(
    id: 'md-insight-readmit',
    type: EdenInsightType.alert,
    severity: EdenInsightSeverity.warning,
    title: '3 patients flagged 30-day readmission risk',
    subtitle: 'Highest: MRN 51208 (post-CABG, day 3 of 7).',
  );

  static const EdenInsightContent labResultsInsight = EdenInsightContent(
    id: 'md-insight-labs',
    type: EdenInsightType.summary,
    title: 'Labs ready · 4 new',
    subtitle: 'A1C, CMP, CBC, urinalysis. 1 abnormal (A1C 9.2).',
  );

  static const List<EdenBlockingAlertData> blockingAlerts =
      <EdenBlockingAlertData>[
    EdenBlockingAlertData(
      task: 'Home visit — MRN 51208',
      context: 'Post-discharge protocol',
      reason: 'HIPAA consent + ROI not yet on file.',
    ),
    EdenBlockingAlertData(
      task: 'Wound care — MRN 33870',
      context: 'Visit kit / supplies',
      reason: '25G needles below reorder threshold (4 in kit, need 6).',
      severity: EdenBlockingSeverity.amber,
    ),
    EdenBlockingAlertData(
      task: 'Telehealth — Dr. Patel',
      context: 'Pre-visit',
      reason: 'Patient labs from external lab not yet faxed.',
      severity: EdenBlockingSeverity.amber,
    ),
  ];

  /// Patient fixtures — HIPAA-safe placeholders.
  static List<DemoCustomer> get patients => <DemoCustomer>[
        CrossCuttingFixtures.customers[4], // J. Doe (MRN 44291)
        const DemoCustomer(
          id: 'cust-141',
          name: 'M. Garcia',
          email: 'patient-mrn-51208@portal.local',
          phone: '+1 (404) 555-0512',
          address: EdenAddress(
            streetLine1: '2402 Kirkwood Ave SE',
            city: 'Atlanta',
            regionCode: 'GA',
            postalCode: '30317',
            countryCode: 'US',
          ),
          vertical: 'medical',
          notes: 'MRN 51208 · Post-CABG follow-up week 1',
        ),
        const DemoCustomer(
          id: 'cust-142',
          name: 'K. Vandermark',
          email: 'patient-mrn-33870@portal.local',
          phone: '+1 (404) 555-0338',
          address: EdenAddress(
            streetLine1: '1188 W Marietta St NW',
            city: 'Atlanta',
            regionCode: 'GA',
            postalCode: '30318',
            countryCode: 'US',
          ),
          vertical: 'medical',
          notes: 'MRN 33870 · Wound care, twice weekly',
        ),
      ];

  /// 5 realistic consent clauses (HIPAA, treatment, photo/video, telehealth,
  /// emergency contact).
  static const List<DemoConsentClause> consentClauses = <DemoConsentClause>[
    DemoConsentClause(
      id: 'cl-hipaa',
      title: 'HIPAA Notice of Privacy Practices',
      body:
          'I acknowledge receipt of the practice\'s Notice of Privacy '
          'Practices, which explains how my protected health information '
          '(PHI) may be used or disclosed.',
    ),
    DemoConsentClause(
      id: 'cl-treatment',
      title: 'Consent to Treatment',
      body:
          'I voluntarily consent to medical care that may include diagnostic '
          'tests, exams, and treatment by the assigned provider. I understand '
          'that no guarantee has been made regarding outcome.',
    ),
    DemoConsentClause(
      id: 'cl-telehealth',
      title: 'Consent to Telehealth Services',
      body:
          'I understand that telehealth involves the use of audio/video '
          'technology to receive care, and I accept its inherent limitations '
          '(e.g. cannot perform physical exam, possible technical interruption).',
      required: false,
    ),
    DemoConsentClause(
      id: 'cl-photo',
      title: 'Photo / Video Documentation',
      body:
          'I consent to having clinical photos taken solely for inclusion in '
          'my medical record (e.g. wound progression). Images are not shared '
          'externally without separate written authorization.',
      required: false,
    ),
    DemoConsentClause(
      id: 'cl-emergency',
      title: 'Emergency Contact Authorization',
      body:
          'I authorize the practice to contact the emergency contact listed '
          'on my intake form should I be unable to make decisions about my '
          'own care.',
    ),
  ];

  /// 8 intake questions including branching logic (yesNo gates 2 follow-ups).
  static const List<DemoIntakeQuestion> intakeQuestions =
      <DemoIntakeQuestion>[
    DemoIntakeQuestion(
      id: 'q-name',
      prompt: 'Legal name (as on insurance card)',
      type: 'text',
      required: true,
    ),
    DemoIntakeQuestion(
      id: 'q-dob',
      prompt: 'Date of birth',
      type: 'date',
      required: true,
    ),
    DemoIntakeQuestion(
      id: 'q-reason',
      prompt: 'Reason for visit',
      type: 'longText',
      required: true,
    ),
    DemoIntakeQuestion(
      id: 'q-meds',
      prompt: 'Are you currently taking any prescription medications?',
      type: 'yesNo',
      required: true,
    ),
    DemoIntakeQuestion(
      id: 'q-meds-list',
      prompt: 'Please list your current medications (include dosage)',
      type: 'longText',
      visibleWhenAnswerId: 'q-meds',
      visibleWhenAnswerEquals: 'yes',
    ),
    DemoIntakeQuestion(
      id: 'q-allergies',
      prompt: 'Known allergies (check all that apply)',
      type: 'multipleChoice',
      options: <String>[
        'Penicillin',
        'Sulfa drugs',
        'Latex',
        'Iodine / contrast',
        'Food (peanuts, shellfish, etc.)',
        'None known',
      ],
    ),
    DemoIntakeQuestion(
      id: 'q-pain',
      prompt: 'Pain level today (0 = none, 10 = worst imaginable)',
      type: 'number',
    ),
    DemoIntakeQuestion(
      id: 'q-history',
      prompt: 'Have you been hospitalized in the past 12 months?',
      type: 'yesNo',
    ),
  ];

  static const List<EdenActivityFeedItemData> activityFeed =
      <EdenActivityFeedItemData>[
    EdenActivityFeedItemData(
      actorName: 'Rosa Soto, RN',
      actorInitials: 'RS',
      action: 'completed visit for',
      entityName: 'MRN 51208',
      timeAgo: '14m ago',
      variant: EdenActivityVariant.success,
    ),
    EdenActivityFeedItemData(
      actorName: 'Dr. Anjali Patel',
      actorInitials: 'AP',
      action: 'signed visit note for',
      entityName: 'MRN 44291',
      timeAgo: '38m ago',
      variant: EdenActivityVariant.info,
    ),
    EdenActivityFeedItemData(
      actorName: 'Front desk',
      actorInitials: 'FD',
      action: 'flagged missing consent for',
      entityName: 'MRN 51208',
      timeAgo: '1h ago',
      variant: EdenActivityVariant.warning,
    ),
    EdenActivityFeedItemData(
      actorName: 'Lab (Quest)',
      actorInitials: 'LB',
      action: 'returned abnormal result for',
      entityName: 'A1C — MRN 18047 (9.2)',
      timeAgo: '3h ago',
      variant: EdenActivityVariant.danger,
    ),
  ];
}
