// Do NOT regenerate via LLM — hand-built fixtures for EdenIntakeForm.
//
// Three representative schemas covering: text/longText/yesNo/singleChoice/
// multipleChoice/number/date types + a branching predicate + a required-
// validation example. These schemas are stable across vertical demos.

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenIntakeFormFixtures {
  EdenIntakeFormFixtures._();

  /// 8-question medical intake including a branching follow-up.
  ///
  /// Q-A 'takingMeds' (yesNo) gates Q-B 'meds_list' (longText): the
  /// medication list is only asked when the answer is "yes".
  static final List<EdenIntakeQuestion> medicalIntake = <EdenIntakeQuestion>[
    const EdenIntakeQuestion(
      id: 'fullName',
      label: 'Full name',
      type: EdenIntakeQuestionType.text,
      required: true,
    ),
    const EdenIntakeQuestion(
      id: 'dob',
      label: 'Date of birth',
      type: EdenIntakeQuestionType.date,
      required: true,
    ),
    const EdenIntakeQuestion(
      id: 'allergies',
      label: 'Known allergies',
      type: EdenIntakeQuestionType.longText,
      placeholder: 'List any drug, food, or environmental allergies',
    ),
    const EdenIntakeQuestion(
      id: 'takingMeds',
      label: 'Currently taking medications?',
      type: EdenIntakeQuestionType.yesNo,
      required: true,
    ),
    EdenIntakeQuestion(
      id: 'meds_list',
      label: 'List your current medications',
      type: EdenIntakeQuestionType.longText,
      required: true,
      visibleWhen: (Map<String, dynamic> answers) =>
          answers['takingMeds'] == true,
    ),
    const EdenIntakeQuestion(
      id: 'insurance',
      label: 'Insurance carrier',
      type: EdenIntakeQuestionType.singleChoice,
      options: <String>['Aetna', 'BCBS', 'Cigna', 'Self-pay', 'Other'],
    ),
    const EdenIntakeQuestion(
      id: 'complaint',
      label: 'Primary complaint',
      type: EdenIntakeQuestionType.longText,
      required: true,
    ),
    const EdenIntakeQuestion(
      id: 'consent_followup',
      label: 'Consent to follow-up communications?',
      type: EdenIntakeQuestionType.yesNo,
    ),
  ];

  /// 5-question legal-style intake.
  static const List<EdenIntakeQuestion> legalIntake = <EdenIntakeQuestion>[
    EdenIntakeQuestion(
      id: 'clientName',
      label: 'Client name',
      type: EdenIntakeQuestionType.text,
      required: true,
    ),
    EdenIntakeQuestion(
      id: 'matterType',
      label: 'Matter type',
      type: EdenIntakeQuestionType.singleChoice,
      required: true,
      options: <String>['Litigation', 'Transactional', 'IP', 'Estate'],
    ),
    EdenIntakeQuestion(
      id: 'partyCount',
      label: 'Number of adverse parties',
      type: EdenIntakeQuestionType.number,
    ),
    EdenIntakeQuestion(
      id: 'jurisdictions',
      label: 'Jurisdictions involved',
      type: EdenIntakeQuestionType.multipleChoice,
      options: <String>['Federal', 'State', 'Local', 'International'],
    ),
    EdenIntakeQuestion(
      id: 'summary',
      label: 'Matter summary',
      type: EdenIntakeQuestionType.longText,
      required: true,
    ),
  ];

  /// 4-question salon onboarding (simpler).
  static const List<EdenIntakeQuestion> salonOnboarding =
      <EdenIntakeQuestion>[
    EdenIntakeQuestion(
      id: 'name',
      label: 'Full name',
      type: EdenIntakeQuestionType.text,
      required: true,
    ),
    EdenIntakeQuestion(
      id: 'phone',
      label: 'Phone number',
      type: EdenIntakeQuestionType.text,
      required: true,
    ),
    EdenIntakeQuestion(
      id: 'services',
      label: 'Services interested in',
      type: EdenIntakeQuestionType.multipleChoice,
      options: <String>['Haircut', 'Color', 'Treatment', 'Style'],
    ),
    EdenIntakeQuestion(
      id: 'marketing',
      label: 'Receive marketing emails?',
      type: EdenIntakeQuestionType.yesNo,
    ),
  ];
}
