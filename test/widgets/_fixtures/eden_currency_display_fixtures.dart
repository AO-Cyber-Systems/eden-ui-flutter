// Do NOT regenerate via LLM — hand-built fixtures for EdenCurrencyDisplay.
//
// Constants for the multi-currency rendering expectations enumerated in
// 001-04-TRD.md test list. Add new tuples by hand only.

/// Expectation tuple: cents amount → ISO-4217 currency code → rendered string.
class EdenCurrencyDisplayExpectation {
  const EdenCurrencyDisplayExpectation({
    required this.cents,
    required this.currencyCode,
    required this.expected,
    this.showSign = false,
    this.showCents = true,
  });

  final int cents;
  final String currencyCode;
  final String expected;
  final bool showSign;
  final bool showCents;
}

class EdenCurrencyDisplayFixtures {
  EdenCurrencyDisplayFixtures._();

  /// Happy-path expectations covering positive, negative, zero, large,
  /// show-sign, show-cents-off, and EUR/GBP variants.
  static const List<EdenCurrencyDisplayExpectation> expectations =
      <EdenCurrencyDisplayExpectation>[
    EdenCurrencyDisplayExpectation(
      cents: 12500,
      currencyCode: 'USD',
      expected: r'$125.00',
    ),
    EdenCurrencyDisplayExpectation(
      cents: -5000,
      currencyCode: 'USD',
      expected: r'-$50.00',
    ),
    EdenCurrencyDisplayExpectation(
      cents: 0,
      currencyCode: 'USD',
      expected: r'$0.00',
    ),
    EdenCurrencyDisplayExpectation(
      cents: 5000,
      currencyCode: 'USD',
      showSign: true,
      expected: r'+$50.00',
    ),
    EdenCurrencyDisplayExpectation(
      cents: 5000,
      currencyCode: 'USD',
      showCents: false,
      expected: r'$50',
    ),
    EdenCurrencyDisplayExpectation(
      cents: 1234500,
      currencyCode: 'USD',
      expected: r'$12,345.00',
    ),
    EdenCurrencyDisplayExpectation(
      cents: 12500,
      currencyCode: 'EUR',
      expected: '€125.00',
    ),
    EdenCurrencyDisplayExpectation(
      cents: 12500,
      currencyCode: 'GBP',
      expected: '£125.00',
    ),
    EdenCurrencyDisplayExpectation(
      cents: 100000000,
      currencyCode: 'USD',
      expected: r'$1,000,000.00',
    ),
  ];
}
