// Do NOT regenerate via LLM — hand-built fixtures for EdenCacPivButton.

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenCacPivButtonFixtures {
  EdenCacPivButtonFixtures._();

  static const validPin = '123456';
  static const wrongPin = '000000';
  static const errorTimeout =
      'Smartcard read timed out. Please reinsert your card.';
  static const errorPinFailed = 'PIN verification failed. 2 attempts remaining.';
  static const errorLong =
      'Smartcard read failed: timed out waiting for card reader response after 30 seconds. '
      'Please verify the card is fully seated in the reader and try again.';

  /// Helper to build a controller pre-set to a specific state.
  static EdenCacPivController controllerInState(
    EdenCacPivState state, {
    String? errorMessage,
  }) {
    final c = EdenCacPivController();
    c.transitionTo(state, errorMessage: errorMessage);
    return c;
  }
}
