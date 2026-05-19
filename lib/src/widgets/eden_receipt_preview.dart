import 'package:flutter/material.dart';

import '../tokens/spacing.dart';
import 'eden_authenticated_image.dart';
import 'eden_currency_display.dart';

// ───────────────────────────────────────────────────────────────────────────
// Value classes — shipped under EdenReceiptPreview's surface so consumers
// can construct receipts via plain `const EdenReceiptData(...)` without
// extra import lines.
// ───────────────────────────────────────────────────────────────────────────

/// Top-level receipt data; consumer maps domain (sales / invoices /
/// tickets / orders) onto this shape.
@immutable
class EdenReceiptData {
  const EdenReceiptData({
    required this.storeHeader,
    required this.lineItems,
    required this.subtotalCents,
    required this.taxCents,
    required this.totalCents,
    required this.tenderSummary,
    this.discountCents,
    this.promo,
    this.tipCents,
    this.footer,
    this.currency = 'USD',
    this.receiptNumber,
    this.timestamp,
  });

  final EdenReceiptStoreHeader storeHeader;
  final List<EdenReceiptLineItem> lineItems;
  final int subtotalCents;

  /// Positive magnitude. Widget prepends a `-` sign at render time.
  final int? discountCents;

  final EdenReceiptPromo? promo;
  final int taxCents;

  /// Tip in cents. When non-null and > 0, a 'Tip' row is rendered between
  /// Tax and Total in the breakdown section. Null and 0 both suppress the row.
  final int? tipCents;

  final int totalCents;
  final List<EdenReceiptTender> tenderSummary;
  final EdenReceiptFooter? footer;
  final String currency;
  final String? receiptNumber;
  final DateTime? timestamp;
}

@immutable
class EdenReceiptStoreHeader {
  const EdenReceiptStoreHeader({
    required this.storeName,
    this.address,
    this.phone,
    this.logoUrl,
  });

  final String storeName;
  final String? address;
  final String? phone;
  final String? logoUrl;
}

@immutable
class EdenReceiptLineItem {
  const EdenReceiptLineItem({
    required this.name,
    required this.qty,
    required this.unitPriceCents,
    this.sku,
    this.notes,
  });

  final String name;
  final num qty;
  final int unitPriceCents;
  final String? sku;
  final String? notes;

  int get subtotalCents => (unitPriceCents * qty).round();
}

@immutable
class EdenReceiptPromo {
  const EdenReceiptPromo({required this.code, required this.amountCents});

  final String code;

  /// Positive magnitude. Rendered with a `-` sign.
  final int amountCents;
}

@immutable
class EdenReceiptTender {
  const EdenReceiptTender({
    required this.method,
    required this.amountCents,
    this.cashGivenCents,
    this.last4,
  });

  final EdenReceiptTenderMethod method;
  final int amountCents;

  /// Cash given (in cents). When `> amountCents` (and `method == cash`), the
  /// widget renders an additional 'Change due' row.
  final int? cashGivenCents;

  /// Last 4 digits of the card number — consumer pre-masks; widget renders
  /// verbatim. No PAN masking inside this widget (see obj 011 EdenSecretField
  /// for PAN entry).
  final String? last4;
}

enum EdenReceiptTenderMethod { cash, card, check, account, giftCard, other }

@immutable
class EdenReceiptFooter {
  const EdenReceiptFooter({
    this.returnPolicy,
    this.taxId,
    this.thankYouMessage,
  });

  final String? returnPolicy;
  final String? taxId;
  final String? thankYouMessage;
}

/// Output mode for [EdenReceiptPreview]. Drives the widget's structural
/// choices (constrained-width container for thermal print preview;
/// SelectableText with plain text for SMS clipboard share; etc.).
enum EdenReceiptPreviewMode { web, print, email, sms }

/// Thermal printer width preset; only meaningful when
/// [EdenReceiptPreview.mode] == [EdenReceiptPreviewMode.print].
enum EdenReceiptPrintWidth { mm80, mm58 }

// ───────────────────────────────────────────────────────────────────────────
// EdenReceiptPreview
// ───────────────────────────────────────────────────────────────────────────

/// Signature for a consumer-supplied currency formatter used by
/// [EdenReceiptPreview]. When provided, every money value in the receipt
/// (line items, breakdown, tender summary) is routed through this function
/// instead of [EdenCurrencyDisplay].
///
/// Parameters:
/// - `cents` — amount in cents (may be negative for discounts/promos).
/// - `currencyCode` — ISO-4217 code from [EdenReceiptData.currency].
///
/// Example — EU locale formatting:
/// ```dart
/// String euroFmt(int cents, String code) {
///   final whole = cents ~/ 100;
///   final frac = (cents % 100).toString().padLeft(2, '0');
///   return '$whole,$frac €';
/// }
/// ```
typedef EdenReceiptCurrencyFormatter = String Function(
  int cents,
  String currencyCode,
);

/// Configurable receipt rendering widget with 4 output modes (web / print /
/// email / sms) for retail POS, trades invoice preview, salon ticket preview,
/// fuel delivery receipt, restaurant check, and any structured-transaction
/// receipt UX.
///
/// Sections, top-to-bottom:
/// 1. **Header** — store name + optional address / phone / logo.
/// 2. **Line items** — qty × name × subtotal rows.
/// 3. **Breakdown** — subtotal / optional discount / optional promo / tax /
///    optional tip / total. Discount + promo render with a `-` sign (stored as
///    positive magnitude in [EdenReceiptData]).
/// 4. **Tender summary** — one row per [EdenReceiptTender] with method label
///    + amount. Cash tenders with `cashGivenCents > amountCents` emit an
///    additional 'Change due' row.
/// 5. **Footer** — optional return policy / tax id / thank-you message.
///
/// Mode rendering rules:
/// - `web` — scrollable single-column [ListView] in the parent layout.
/// - `print` — constrained [ConstrainedBox] (80mm ≈ 302pt or 58mm ≈ 219pt)
///   centered horizontally. Body keyed `ValueKey('eden-receipt-body')` for
///   width assertions in tests + consumer print drivers.
/// - `email` — single-column [ListView] with no fixed-width wrapper; renders
///   as plain Material widgets so HTML-stripping email clients still get a
///   reasonable layout when rendered to images server-side.
/// - `sms` — plain-text [SelectableText] containing the receipt body so the
///   consumer can copy + paste into an SMS body.
///
/// The widget knows nothing about retail. Consumer maps any domain to
/// [EdenReceiptData].
///
/// **Currency formatting.** Supply [currencyFormatter] to override the default
/// [EdenCurrencyDisplay] rendering — useful for non-USD locales or custom
/// symbol placement. When null, the default formatter is used.
///
/// **Obj-012 dependency strategy.** The line-items section composes a
/// private `_ReadOnlyLineItemTable` shim. When [EdenLineItemEditor]'s
/// generic readOnly mode is widely adopted across the codebase, swap the
/// shim for an `EdenLineItemEditor` of `EdenReceiptLineItem` with
/// `readOnly: true`. Tracked by the `TODO(obj-014->obj-012 swap):` marker
/// in [_LineItemsSection].
class EdenReceiptPreview extends StatelessWidget {
  const EdenReceiptPreview({
    super.key,
    required this.data,
    this.mode = EdenReceiptPreviewMode.web,
    this.printWidth = EdenReceiptPrintWidth.mm80,
    this.currencyFormatter,
  });

  final EdenReceiptData data;
  final EdenReceiptPreviewMode mode;
  final EdenReceiptPrintWidth printWidth;

  /// Optional consumer-controlled currency formatter. When null, every money
  /// value renders via [EdenCurrencyDisplay] using the built-in USD/EUR/GBP/CAD/AUD
  /// symbol map. Supply this to handle non-standard locales (e.g. comma-decimal
  /// EUR formatting) or to inject test-controlled output.
  final EdenReceiptCurrencyFormatter? currencyFormatter;

  @override
  Widget build(BuildContext context) {
    if (mode == EdenReceiptPreviewMode.sms) {
      return _SmsBody(data: data, currencyFormatter: currencyFormatter);
    }
    final body = _ReceiptBody(data: data, currencyFormatter: currencyFormatter);
    if (mode == EdenReceiptPreviewMode.print) {
      final mm = printWidth == EdenReceiptPrintWidth.mm80 ? 302.0 : 219.0;
      return Center(
        child: ConstrainedBox(
          key: const ValueKey('eden-receipt-body'),
          constraints: BoxConstraints(maxWidth: mm),
          child: body,
        ),
      );
    }
    return body;
  }
}

class _ReceiptBody extends StatelessWidget {
  const _ReceiptBody({
    required this.data,
    this.currencyFormatter,
  });
  final EdenReceiptData data;
  final EdenReceiptCurrencyFormatter? currencyFormatter;

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(EdenSpacing.space3),
      children: [
        _Header(header: data.storeHeader),
        const SizedBox(height: EdenSpacing.space2),
        _LineItemsSection(
          items: data.lineItems,
          currency: data.currency,
          currencyFormatter: currencyFormatter,
        ),
        const Divider(),
        _BreakdownSection(data: data, currencyFormatter: currencyFormatter),
        const Divider(),
        _TenderSection(
          tenders: data.tenderSummary,
          currency: data.currency,
          currencyFormatter: currencyFormatter,
        ),
        if (data.footer != null) ...[
          const Divider(),
          _Footer(footer: data.footer!),
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.header});
  final EdenReceiptStoreHeader header;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (header.logoUrl != null) ...[
          SizedBox(
            width: 80,
            height: 80,
            child: EdenAuthenticatedImage(
              url: header.logoUrl!,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: EdenSpacing.space1),
        ],
        Text(
          header.storeName,
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        if (header.address != null)
          Text(
            header.address!,
            style: theme.textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        if (header.phone != null)
          Text(
            header.phone!,
            style: theme.textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}

class _LineItemsSection extends StatelessWidget {
  const _LineItemsSection({
    required this.items,
    required this.currency,
    this.currencyFormatter,
  });
  final List<EdenReceiptLineItem> items;
  final String currency;
  final EdenReceiptCurrencyFormatter? currencyFormatter;

  @override
  Widget build(BuildContext context) {
    // TODO(obj-014→obj-012 swap): when EdenLineItemEditor<EdenReceiptLineItem>
    // readOnly mode is the established compose path, replace this shim with
    //   EdenLineItemEditor<EdenReceiptLineItem>(items: items, readOnly: true,
    //     columns: const [qty, name, unitPrice, subtotal]);
    return _ReadOnlyLineItemTable(
      items: items,
      currency: currency,
      currencyFormatter: currencyFormatter,
    );
  }
}

class _ReadOnlyLineItemTable extends StatelessWidget {
  const _ReadOnlyLineItemTable({
    required this.items,
    required this.currency,
    this.currencyFormatter,
  });

  final List<EdenReceiptLineItem> items;
  final String currency;
  final EdenReceiptCurrencyFormatter? currencyFormatter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final li in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 36,
                  child: Text(
                    '${li.qty}x',
                    style: theme.textTheme.labelMedium,
                  ),
                ),
                Expanded(
                  child: Text(
                    li.name,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (currencyFormatter != null)
                  Text(
                    currencyFormatter!(li.subtotalCents, currency),
                    style: theme.textTheme.bodyMedium,
                  )
                else
                  EdenCurrencyDisplay(
                    cents: li.subtotalCents,
                    currencyCode: currency,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _BreakdownSection extends StatelessWidget {
  const _BreakdownSection({
    required this.data,
    this.currencyFormatter,
  });
  final EdenReceiptData data;
  final EdenReceiptCurrencyFormatter? currencyFormatter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _BreakdownRow(
          label: 'Subtotal',
          cents: data.subtotalCents,
          currency: data.currency,
          currencyFormatter: currencyFormatter,
        ),
        if (data.discountCents != null && data.discountCents! > 0)
          _BreakdownRow(
            label: 'Discount',
            cents: -data.discountCents!,
            currency: data.currency,
            color: theme.colorScheme.error,
            currencyFormatter: currencyFormatter,
          ),
        if (data.promo != null)
          _BreakdownRow(
            label: 'Promo (${data.promo!.code})',
            cents: -data.promo!.amountCents,
            currency: data.currency,
            color: theme.colorScheme.primary,
            currencyFormatter: currencyFormatter,
          ),
        _BreakdownRow(
          label: 'Tax',
          cents: data.taxCents,
          currency: data.currency,
          currencyFormatter: currencyFormatter,
        ),
        if (data.tipCents != null && data.tipCents! > 0)
          _BreakdownRow(
            label: 'Tip',
            cents: data.tipCents!,
            currency: data.currency,
            currencyFormatter: currencyFormatter,
          ),
        _BreakdownRow(
          label: 'Total',
          cents: data.totalCents,
          currency: data.currency,
          bold: true,
          currencyFormatter: currencyFormatter,
        ),
      ],
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.cents,
    required this.currency,
    this.color,
    this.bold = false,
    this.currencyFormatter,
  });

  final String label;
  final int cents;
  final String currency;
  final Color? color;
  final bool bold;
  final EdenReceiptCurrencyFormatter? currencyFormatter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = bold
        ? theme.textTheme.titleMedium
        : theme.textTheme.bodyMedium;
    final effectiveStyle = baseStyle?.copyWith(
      color: color,
      fontWeight: bold ? FontWeight.bold : null,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: baseStyle?.copyWith(
                fontWeight: bold ? FontWeight.bold : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (currencyFormatter != null)
            Text(
              currencyFormatter!(cents, currency),
              style: effectiveStyle,
            )
          else
            DefaultTextStyle.merge(
              style: TextStyle(
                color: color,
                fontWeight: bold ? FontWeight.bold : null,
              ),
              child: EdenCurrencyDisplay(
                cents: cents,
                currencyCode: currency,
                style: baseStyle,
              ),
            ),
        ],
      ),
    );
  }
}

class _TenderSection extends StatelessWidget {
  const _TenderSection({
    required this.tenders,
    required this.currency,
    this.currencyFormatter,
  });
  final List<EdenReceiptTender> tenders;
  final String currency;
  final EdenReceiptCurrencyFormatter? currencyFormatter;

  String _methodLabel(EdenReceiptTender t) {
    switch (t.method) {
      case EdenReceiptTenderMethod.cash:
        return 'Cash';
      case EdenReceiptTenderMethod.card:
        return t.last4 != null ? 'Card **** ${t.last4}' : 'Card';
      case EdenReceiptTenderMethod.check:
        return 'Check';
      case EdenReceiptTenderMethod.account:
        return 'Account';
      case EdenReceiptTenderMethod.giftCard:
        return 'Gift card';
      case EdenReceiptTenderMethod.other:
        return 'Other';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final t in tenders) ...[
          _BreakdownRow(
            label: _methodLabel(t),
            cents: t.amountCents,
            currency: currency,
            currencyFormatter: currencyFormatter,
          ),
          if (t.method == EdenReceiptTenderMethod.cash &&
              t.cashGivenCents != null &&
              t.cashGivenCents! > t.amountCents)
            _BreakdownRow(
              label: 'Change due',
              cents: t.cashGivenCents! - t.amountCents,
              currency: currency,
              currencyFormatter: currencyFormatter,
            ),
        ],
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.footer});
  final EdenReceiptFooter footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        if (footer.returnPolicy != null)
          Text(
            footer.returnPolicy!,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        if (footer.taxId != null)
          Text(
            footer.taxId!,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        if (footer.thankYouMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: EdenSpacing.space1),
            child: Text(
              footer.thankYouMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}

class _SmsBody extends StatelessWidget {
  const _SmsBody({
    required this.data,
    this.currencyFormatter,
  });
  final EdenReceiptData data;
  final EdenReceiptCurrencyFormatter? currencyFormatter;

  String _fmt(int cents, String currency) {
    if (currencyFormatter != null) {
      return currencyFormatter!(cents, currency);
    }
    final sign = cents < 0 ? '-' : '';
    final abs = cents.abs();
    final dollars = abs ~/ 100;
    final centsRem = abs % 100;
    final symbol = currency == 'USD' ? r'$' : '$currency ';
    return '$sign$symbol$dollars.${centsRem.toString().padLeft(2, '0')}';
  }

  String _render() {
    final buf = StringBuffer();
    buf.writeln(data.storeHeader.storeName);
    if (data.storeHeader.address != null) buf.writeln(data.storeHeader.address);
    if (data.storeHeader.phone != null) buf.writeln(data.storeHeader.phone);
    buf.writeln('-' * 32);
    for (final li in data.lineItems) {
      buf.writeln('${li.qty}x ${li.name}');
      buf.writeln('   ${_fmt(li.subtotalCents, data.currency)}');
    }
    buf.writeln('-' * 32);
    buf.writeln('Subtotal: ${_fmt(data.subtotalCents, data.currency)}');
    if (data.discountCents != null && data.discountCents! > 0) {
      buf.writeln('Discount: ${_fmt(-data.discountCents!, data.currency)}');
    }
    if (data.promo != null) {
      buf.writeln(
        'Promo (${data.promo!.code}): '
        '${_fmt(-data.promo!.amountCents, data.currency)}',
      );
    }
    buf.writeln('Tax: ${_fmt(data.taxCents, data.currency)}');
    if (data.tipCents != null && data.tipCents! > 0) {
      buf.writeln('Tip: ${_fmt(data.tipCents!, data.currency)}');
    }
    buf.writeln('Total: ${_fmt(data.totalCents, data.currency)}');
    for (final t in data.tenderSummary) {
      final label = switch (t.method) {
        EdenReceiptTenderMethod.cash => 'Cash',
        EdenReceiptTenderMethod.card =>
          t.last4 != null ? 'Card **** ${t.last4}' : 'Card',
        EdenReceiptTenderMethod.check => 'Check',
        EdenReceiptTenderMethod.account => 'Account',
        EdenReceiptTenderMethod.giftCard => 'Gift card',
        EdenReceiptTenderMethod.other => 'Other',
      };
      buf.writeln('$label: ${_fmt(t.amountCents, data.currency)}');
      if (t.method == EdenReceiptTenderMethod.cash &&
          t.cashGivenCents != null &&
          t.cashGivenCents! > t.amountCents) {
        buf.writeln(
          'Change due: '
          '${_fmt(t.cashGivenCents! - t.amountCents, data.currency)}',
        );
      }
    }
    if (data.footer != null) {
      buf.writeln('-' * 32);
      if (data.footer!.returnPolicy != null) {
        buf.writeln(data.footer!.returnPolicy);
      }
      if (data.footer!.taxId != null) buf.writeln(data.footer!.taxId);
      if (data.footer!.thankYouMessage != null) {
        buf.writeln(data.footer!.thankYouMessage);
      }
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(EdenSpacing.space3),
      child: SelectableText(
        _render(),
        style: const TextStyle(fontFamily: 'monospace'),
      ),
    );
  }
}
