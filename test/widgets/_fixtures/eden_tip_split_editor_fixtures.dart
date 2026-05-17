// Do NOT regenerate via LLM — hand-built fixtures for EdenTipSplitEditor.
//
// Recipient + allocation fixtures used across the test suite and dev
// catalog for obj 015-01. Splits are stored as percent shares 0..1.

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenTipSplitEditorFixtures {
  /// 2-way split — primary + assistant.
  static const List<EdenTipRecipient> twoWayStaff = <EdenTipRecipient>[
    EdenTipRecipient(
      id: 'sarah',
      displayName: 'Sarah',
      roleLabel: 'Primary stylist',
    ),
    EdenTipRecipient(
      id: 'mia',
      displayName: 'Mia',
      roleLabel: 'Assistant',
    ),
  ];

  /// 3-way split — primary + assistant + shampoo.
  static const List<EdenTipRecipient> threeWayStaff = <EdenTipRecipient>[
    EdenTipRecipient(
      id: 'sarah',
      displayName: 'Sarah',
      roleLabel: 'Primary stylist',
    ),
    EdenTipRecipient(
      id: 'mia',
      displayName: 'Mia',
      roleLabel: 'Assistant',
    ),
    EdenTipRecipient(
      id: 'amy',
      displayName: 'Amy',
      roleLabel: 'Shampoo',
    ),
  ];

  /// Even 50/50 for two recipients (in percent mode).
  static const List<EdenTipSplitAllocation> fiftyFiftyAllocations =
      <EdenTipSplitAllocation>[
    EdenTipSplitAllocation(
      recipient: EdenTipRecipient(
        id: 'sarah',
        displayName: 'Sarah',
        roleLabel: 'Primary stylist',
      ),
      share: 0.50,
    ),
    EdenTipSplitAllocation(
      recipient: EdenTipRecipient(
        id: 'mia',
        displayName: 'Mia',
        roleLabel: 'Assistant',
      ),
      share: 0.50,
    ),
  ];

  /// 60 / 25 / 15 across three recipients (in percent mode).
  static const List<EdenTipSplitAllocation> sixtyTwentyFiveFifteenAllocations =
      <EdenTipSplitAllocation>[
    EdenTipSplitAllocation(
      recipient: EdenTipRecipient(
        id: 'sarah',
        displayName: 'Sarah',
        roleLabel: 'Primary stylist',
      ),
      share: 0.60,
    ),
    EdenTipSplitAllocation(
      recipient: EdenTipRecipient(
        id: 'mia',
        displayName: 'Mia',
        roleLabel: 'Assistant',
      ),
      share: 0.25,
    ),
    EdenTipSplitAllocation(
      recipient: EdenTipRecipient(
        id: 'amy',
        displayName: 'Amy',
        roleLabel: 'Shampoo',
      ),
      share: 0.15,
    ),
  ];
}
