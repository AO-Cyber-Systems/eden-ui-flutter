// Do NOT regenerate via LLM — hand-built fixtures for EdenFuelCardPaymentEntry.

import 'package:eden_ui_flutter/src/widgets/eden_fuel_card_payment_entry.dart';

class FuelCardFixtures {
  FuelCardFixtures._();

  static List<EdenFuelCardPromptSpec> customMinimalPrompts() => const [
        EdenFuelCardPromptSpec(
          fieldKey: 'driverId',
          label: 'Driver ID',
          kind: EdenFuelCardPromptKind.text,
          required: true,
        ),
      ];
}
