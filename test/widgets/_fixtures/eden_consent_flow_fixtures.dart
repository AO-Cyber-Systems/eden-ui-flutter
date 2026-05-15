// Do NOT regenerate via LLM — hand-built fixtures for EdenConsentFlow.
//
// Three consent ladders used by the widget tests: a generic 3-clause set
// (simple), a 5-clause medical informed-consent ladder with affirmations,
// and a 1x1 PNG byte sample for any test that wants raw image bytes.

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenConsentFlowFixtures {
  EdenConsentFlowFixtures._();

  /// Three clauses, no affirmations required.
  static const List<EdenConsentClause> simpleClauses = <EdenConsentClause>[
    EdenConsentClause(
      id: 'tos',
      title: 'Terms of Service',
      body: 'I agree to the terms of service.',
    ),
    EdenConsentClause(
      id: 'privacy',
      title: 'Privacy Policy',
      body: 'I acknowledge that my data is handled per the privacy policy.',
    ),
    EdenConsentClause(
      id: 'communications',
      title: 'Communications',
      body: 'I consent to receive transactional communications.',
    ),
  ];

  /// Five medical-grade clauses, two require explicit affirmation.
  static const List<EdenConsentClause> medicalClauses = <EdenConsentClause>[
    EdenConsentClause(
      id: 'procedure_explained',
      title: 'Procedure explained',
      body:
          'The proposed procedure, including risks and alternatives, has '
          'been explained to me.',
      requireAffirmation: true,
    ),
    EdenConsentClause(
      id: 'risks_disclosed',
      title: 'Risks disclosed',
      body: 'I understand the medical risks associated with this procedure.',
      requireAffirmation: true,
    ),
    EdenConsentClause(
      id: 'hipaa',
      title: 'HIPAA authorization',
      body: 'I authorize the use of my PHI per HIPAA disclosures.',
    ),
    EdenConsentClause(
      id: 'billing',
      title: 'Financial responsibility',
      body: 'I accept financial responsibility for services rendered.',
    ),
    EdenConsentClause(
      id: 'follow_up',
      title: 'Follow-up consent',
      body: 'I consent to follow-up communications regarding my care.',
    ),
  ];

  /// Single-clause minimum (used for minimal-flow edge tests).
  static const List<EdenConsentClause> singleClause = <EdenConsentClause>[
    EdenConsentClause(
      id: 'attestation',
      title: 'Attestation',
      body: 'I attest the information provided is accurate.',
    ),
  ];

  /// Minimal opaque 1x1 PNG bytes — useful when a test wants to feed bytes
  /// into a downstream serializer without actually rasterizing strokes.
  static const List<int> samplePngBytes = <int>[
    0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a,
    0x00, 0x00, 0x00, 0x0d, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1f, 0x15, 0xc4,
    0x89, 0x00, 0x00, 0x00, 0x0d, 0x49, 0x44, 0x41,
    0x54, 0x78, 0x9c, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0d, 0x0a, 0x2d, 0xb4, 0x00,
    0x00, 0x00, 0x00, 0x49, 0x45, 0x4e, 0x44, 0xae,
    0x42, 0x60, 0x82,
  ];
}
