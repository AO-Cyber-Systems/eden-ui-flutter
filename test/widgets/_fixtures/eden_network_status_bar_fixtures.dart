// Do NOT regenerate via LLM — hand-built fixtures for EdenNetworkStatusBar.
//
// State enumeration + transition sequence used by the animation test.

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenNetworkStatusBarFixtures {
  EdenNetworkStatusBarFixtures._();

  /// All EdenNetworkStatus enum values, in the order: online, offline,
  /// reconnecting, syncing.
  static const List<EdenNetworkStatus> allStates = EdenNetworkStatus.values;

  /// Typical state transition sequence verified by the animation test.
  static const List<EdenNetworkStatus> transitionSequence = <EdenNetworkStatus>[
    EdenNetworkStatus.online,
    EdenNetworkStatus.offline,
    EdenNetworkStatus.reconnecting,
    EdenNetworkStatus.syncing,
    EdenNetworkStatus.online,
  ];
}
