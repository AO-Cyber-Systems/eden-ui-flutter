// Do NOT regenerate via LLM — hand-built fixtures for EdenTippingSelector.
//
// Preset arrays per vertical archetype used by the test suite and the
// dev catalog for obj 015-01. Percent values are stored as 0..1
// fractions (0.18 == 18%); labels are the human-readable form.

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenTippingSelectorFixtures {
  /// Salon standard — 15 / 18 / 20 / 25.
  static const List<EdenTipPreset> salonStandard = <EdenTipPreset>[
    EdenTipPreset(percent: 0.15, label: '15%'),
    EdenTipPreset(percent: 0.18, label: '18%'),
    EdenTipPreset(percent: 0.20, label: '20%'),
    EdenTipPreset(percent: 0.25, label: '25%'),
  ];

  /// Restaurant standard — 18 / 20 / 22 / 25.
  static const List<EdenTipPreset> restaurantStandard = <EdenTipPreset>[
    EdenTipPreset(percent: 0.18, label: '18%'),
    EdenTipPreset(percent: 0.20, label: '20%'),
    EdenTipPreset(percent: 0.22, label: '22%'),
    EdenTipPreset(percent: 0.25, label: '25%'),
  ];

  /// Light tier — 10 / 15 / 18 / 20 (retail counter / cafe).
  static const List<EdenTipPreset> lightTier = <EdenTipPreset>[
    EdenTipPreset(percent: 0.10, label: '10%'),
    EdenTipPreset(percent: 0.15, label: '15%'),
    EdenTipPreset(percent: 0.18, label: '18%'),
    EdenTipPreset(percent: 0.20, label: '20%'),
  ];
}
