import 'package:flutter/material.dart';

/// Internal currency format descriptor — symbol + decimal/thousand separators.
class _CurrencyFormat {
  const _CurrencyFormat({
    required this.symbol,
    required this.decimal,
    required this.thousand,
  });

  final String symbol;
  final String decimal;
  final String thousand;
}

/// Multi-currency money rendering widget.
///
/// Stores money as integer cents. Renders with a hard-coded symbol/separator
/// map for USD/EUR/GBP/CAD/AUD. For broader locale support, file a follow-up
/// adding the `intl` dependency.
///
/// Example:
/// ```dart
/// EdenCurrencyDisplay(cents: 12500)                       // $125.00
/// EdenCurrencyDisplay(cents: -5000)                       // -$50.00
/// EdenCurrencyDisplay(cents: 5000, showSign: true)        // +$50.00
/// EdenCurrencyDisplay(cents: 12500, currencyCode: 'EUR')  // €125.00
/// ```
///
/// Reused by invoicing, POS, payroll, expenses, portal payments,
/// fuel pricing, legal billing.
class EdenCurrencyDisplay extends StatelessWidget {
  const EdenCurrencyDisplay({
    super.key,
    required this.cents,
    this.currencyCode = 'USD',
    this.style,
    this.positiveColor,
    this.negativeColor,
    this.colorize = false,
    this.showSign = false,
    this.showCents = true,
  });

  /// Amount in cents (e.g., 12500 = $125.00).
  final int cents;

  /// ISO-4217 currency code. Defaults to 'USD'. Supported v1 set:
  /// USD, EUR, GBP, CAD, AUD. Unknown codes fall back to USD formatting
  /// with the unknown code rendered as a prefix.
  final String currencyCode;

  /// Text style override.
  final TextStyle? style;

  /// Color for positive values when [colorize] is true. Defaults to
  /// theme.colorScheme.primary.
  final Color? positiveColor;

  /// Color for negative values when [colorize] is true. Defaults to
  /// theme.colorScheme.error.
  final Color? negativeColor;

  /// Whether to apply color based on sign. Defaults to false.
  final bool colorize;

  /// Whether to show explicit `+` sign for positive values.
  final bool showSign;

  /// Whether to show cents (e.g., $125 vs $125.00). Defaults to true.
  final bool showCents;

  /// Hard-coded v1 currency format map. Add new entries by hand only.
  static const Map<String, _CurrencyFormat> _formats = {
    'USD': _CurrencyFormat(symbol: r'$', decimal: '.', thousand: ','),
    'CAD': _CurrencyFormat(symbol: r'$', decimal: '.', thousand: ','),
    'AUD': _CurrencyFormat(symbol: r'$', decimal: '.', thousand: ','),
    'EUR': _CurrencyFormat(symbol: '€', decimal: '.', thousand: ','),
    'GBP': _CurrencyFormat(symbol: '£', decimal: '.', thousand: ','),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final format = _formats[currencyCode] ??
        _CurrencyFormat(
          symbol: '$currencyCode ',
          decimal: '.',
          thousand: ',',
        );

    final absCents = cents.abs();
    final whole = absCents ~/ 100;
    final fraction = absCents % 100;

    final wholeFormatted = _formatThousands(whole, format.thousand);
    final amount = showCents
        ? '$wholeFormatted${format.decimal}${fraction.toString().padLeft(2, '0')}'
        : wholeFormatted;
    final formatted = '${format.symbol}$amount';

    String display;
    if (cents < 0) {
      display = '-$formatted';
    } else if (showSign && cents > 0) {
      display = '+$formatted';
    } else {
      display = formatted;
    }

    Color? color;
    if (colorize) {
      if (cents > 0) {
        color = positiveColor ?? theme.colorScheme.primary;
      } else if (cents < 0) {
        color = negativeColor ?? theme.colorScheme.error;
      }
    }

    final base = style ?? theme.textTheme.bodyMedium;
    final effectiveStyle = color == null ? base : base?.copyWith(color: color);

    return Text(
      display,
      style: effectiveStyle,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Insert thousand-separators into an integer's decimal representation.
  static String _formatThousands(int value, String separator) {
    final raw = value.toString();
    if (raw.length <= 3) return raw;
    final buf = StringBuffer();
    var count = 0;
    for (var i = raw.length - 1; i >= 0; i--) {
      buf.write(raw[i]);
      count++;
      if (count == 3 && i > 0) {
        buf.write(separator);
        count = 0;
      }
    }
    return buf.toString().split('').reversed.join();
  }
}
