// Do NOT regenerate via LLM — hand-built fixtures for EdenIntakeFormBuilder.
//
// These fixtures power obj 016-04 tests. Salon-context starter schema (Full
// name / DOB / Allergies / Signature) reflects the canonical new-client intake
// from MangoMint's competitive landscape — concrete, hand-touched.

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenIntakeFormBuilderFixtures {
  EdenIntakeFormBuilderFixtures._();

  static EdenIntakeFormSchema salonStarter() {
    return const EdenIntakeFormSchema(
      id: 'salon-intake-v1',
      name: 'New Client Intake',
      fields: [
        EdenIntakeFieldSchema(
          id: 'f1',
          type: EdenIntakeFieldType.shortText,
          label: 'Full name',
          required: true,
        ),
        EdenIntakeFieldSchema(
          id: 'f2',
          type: EdenIntakeFieldType.date,
          label: 'Date of birth',
          required: true,
        ),
        EdenIntakeFieldSchema(
          id: 'f3',
          type: EdenIntakeFieldType.longText,
          label: 'Known allergies or sensitivities',
        ),
        EdenIntakeFieldSchema(
          id: 'f4',
          type: EdenIntakeFieldType.signature,
          label: 'Sign here',
          required: true,
        ),
      ],
    );
  }

  static EdenIntakeFormSchema empty() {
    return const EdenIntakeFormSchema(
      id: 'empty-intake',
      name: 'Empty Intake',
    );
  }

  static EdenIntakeFormSchema withConditional() {
    return const EdenIntakeFormSchema(
      id: 'conditional-intake',
      name: 'Conditional Intake',
      fields: [
        EdenIntakeFieldSchema(
          id: 'f1',
          type: EdenIntakeFieldType.shortText,
          label: 'Trigger field',
        ),
        EdenIntakeFieldSchema(
          id: 'f2',
          type: EdenIntakeFieldType.yesNo,
          label: 'Are you pregnant?',
        ),
        EdenIntakeFieldSchema(
          id: 'f3',
          type: EdenIntakeFieldType.longText,
          label: 'Pregnancy notes',
          visibleWhen: EdenIntakeVisibilityRule(fieldId: 'f2', equals: 'yes'),
        ),
      ],
    );
  }
}
