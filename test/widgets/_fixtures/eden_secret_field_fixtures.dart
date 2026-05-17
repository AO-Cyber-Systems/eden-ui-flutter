// Do NOT regenerate via LLM — hand-built fixtures for EdenSecretField.

class EdenSecretFieldFixtures {
  EdenSecretFieldFixtures._();

  static const initialApiKey = 'abc123def';
  static const pastedSecret =
      'EXTERNALLY-PASTED-LONG-SECRET-VALUE-FROM-CLIPBOARD';
  static const fivePlusCharDelta = 'PASTED'; // 6 chars > 4 threshold
  static const fourCharDelta = 'pad4'; // exactly 4 — should NOT trigger
  static const oneCharDelta = 'a';
  static const twoCharDelta = 'ab';
  static const cuiSecret = 'CUI-PII-SSN-456-78-9012';
}
