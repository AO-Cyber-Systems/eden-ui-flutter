// Do NOT regenerate via LLM — hand-built fixtures for EdenWarrantyClaim.

import 'package:eden_ui_flutter/src/widgets/eden_warranty_claim.dart';

class WarrantyClaimFixtures {
  WarrantyClaimFixtures._();

  /// Three realistic part candidates for an HVAC compressor.
  static List<EdenWarrantyClaimPartCandidate> hvacParts() => const [
        EdenWarrantyClaimPartCandidate(
          sku: 'HVAC-CAP-45-5',
          label: 'Run capacitor 45/5 µF 370V',
        ),
        EdenWarrantyClaimPartCandidate(
          sku: 'HVAC-CONT-24V',
          label: 'Contactor 24V coil 30A',
        ),
        EdenWarrantyClaimPartCandidate(
          sku: 'HVAC-COMP-XC25',
          label: 'Compressor scroll XC25-048',
        ),
      ];
}
