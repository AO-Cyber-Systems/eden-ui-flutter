import 'package:flutter/material.dart';

import '../tokens/spacing.dart';
import 'eden_adaptive_layout.dart';
import 'eden_button.dart';
import 'eden_currency_display.dart';
import 'eden_membership_tier_badge.dart';
import 'eden_quick_add_product_grid.dart';
import 'eden_receipt_preview.dart';
import 'eden_search_input.dart';
import 'eden_secret_field.dart';

// ───────────────────────────────────────────────────────────────────────────
// Value classes — POS session payload + cart + customer + tender + event
// stream.
// ───────────────────────────────────────────────────────────────────────────

@immutable
class EdenPosSession {
  const EdenPosSession({
    this.cartItems = const <EdenPosCartItem>[],
    this.customer,
    this.appliedPromos = const <EdenPosPromo>[],
    this.tenderState,
    this.currency = 'USD',
  });

  final List<EdenPosCartItem> cartItems;
  final EdenPosCustomer? customer;
  final List<EdenPosPromo> appliedPromos;
  final EdenPosTenderState? tenderState;
  final String currency;
}

@immutable
class EdenPosCartItem {
  const EdenPosCartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.qty,
    required this.unitPriceCents,
    this.sku,
    this.notes,
  });

  final String id;
  final String productId;
  final String name;
  final num qty;
  final int unitPriceCents;
  final String? sku;
  final String? notes;

  int get subtotalCents => (unitPriceCents * qty).round();
}

@immutable
class EdenPosCustomer {
  const EdenPosCustomer({
    required this.id,
    required this.name,
    this.tier,
    this.points,
    this.phone,
    this.email,
  });

  final String id;
  final String name;

  /// Lowercased tier label (e.g. `'bronze' | 'silver' | 'gold' | 'platinum' |
  /// 'vip'`). Mapped to [EdenMembershipTier] at render time; unknown values
  /// fall back to [EdenMembershipTierBadge.custom] with a neutral palette.
  final String? tier;
  final int? points;
  final String? phone;
  final String? email;
}

@immutable
class EdenPosPromo {
  const EdenPosPromo({required this.code, required this.amountCents});
  final String code;
  final int amountCents;
}

@immutable
class EdenPosTenderState {
  const EdenPosTenderState({
    required this.method,
    required this.amountCents,
    this.cashGivenCents,
    this.last4,
    this.panClassified,
  });

  final EdenPosTenderMethod method;
  final int amountCents;
  final int? cashGivenCents;
  final String? last4;

  /// Captured via [EdenSecretField] in classified clipboard mode. Opaque
  /// pass-through to the consumer's payment processor — widget never
  /// displays this back.
  final String? panClassified;
}

enum EdenPosTenderMethod { cash, card, check, account, giftCard, split }

// ───────────────────────────────────────────────────────────────────────────
// Session events — sealed hierarchy emitted via onSessionEvent.
// ───────────────────────────────────────────────────────────────────────────

sealed class EdenPosSessionEvent {}

class EdenPosProductAdded extends EdenPosSessionEvent {
  EdenPosProductAdded(this.product);
  final EdenQuickAddProduct product;
}

class EdenPosCustomerAttached extends EdenPosSessionEvent {
  EdenPosCustomerAttached(this.customer);
  final EdenPosCustomer customer;
}

class EdenPosCustomerDetached extends EdenPosSessionEvent {}

class EdenPosPromoApplied extends EdenPosSessionEvent {
  EdenPosPromoApplied(this.promo);
  final EdenPosPromo promo;
}

class EdenPosTenderUpdated extends EdenPosSessionEvent {
  EdenPosTenderUpdated(this.state);
  final EdenPosTenderState state;
}

class EdenPosPaymentSubmitted extends EdenPosSessionEvent {
  EdenPosPaymentSubmitted(this.session);
  final EdenPosSession session;
}

// ───────────────────────────────────────────────────────────────────────────
// EdenPOSRegisterScaffold
// ───────────────────────────────────────────────────────────────────────────

/// The headline retail POS register surface — 3-zone (web + iPad-native)
/// when width is ≥1024pt, collapsing to a single-zone tabbed layout
/// (`Products | Cart | Tender`) at < 1024pt. Per locked decision B-R1
/// (web + iPad/POS terminal from v1).
///
/// **Zones:**
/// - **LEFT** — [EdenSearchInput] + barcode scan icon button + [EdenQuickAddProductGrid].
/// - **CENTER** — customer-attach affordance ([EdenMembershipTierBadge] when
///   attached) + cart shim. TODO swap to obj-012 EdenLineItemEditor when
///   widely adopted.
/// - **RIGHT** — tender method picker + [EdenSecretField.classified] for
///   PAN entry (PCI-aware; no hand-rolled card UI) + Submit payment +
///   Show receipt trigger. TODO swap to obj-012 EdenSplitTender.
///
/// **Receipt slide-out** uses [AnimatedPositioned] over the main content
/// (not a Scaffold-managed Drawer) so it composes inside parent Scaffolds
/// without conflict. The drawer renders [EdenReceiptPreview] (TRD 014-03)
/// with [EdenReceiptData] derived from the current session.
///
/// **PCI compliance:** Card-number entry uses [EdenSecretField] with
/// `clipboardMode: EdenSecretClipboardMode.classified`. Test asserts the
/// classified mode is set; this source file does not directly use
/// `flutter/material.dart`'s raw text-field widget for PAN entry.
///
/// **Touch targets** enforced ≥48pt via SizedBox constraints on all
/// tappable elements (Apple HIG POS guidance).
///
/// **No backend bind:** no Stripe / Square / Toast imports. Consumer wires
/// callbacks ([onSessionEvent], [onAttachCustomerRequest],
/// [onBarcodeScanRequest]) to their backend.
class EdenPOSRegisterScaffold extends StatefulWidget {
  const EdenPOSRegisterScaffold({
    super.key,
    required this.session,
    required this.products,
    this.categories,
    this.onSessionEvent,
    this.onAttachCustomerRequest,
    this.onBarcodeScanRequest,
    this.forceCompact,
    this.forceExpanded,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  final EdenPosSession session;
  final List<EdenQuickAddProduct> products;
  final List<EdenQuickAddCategory>? categories;
  final void Function(EdenPosSessionEvent event)? onSessionEvent;
  final VoidCallback? onAttachCustomerRequest;

  /// When provided, the LEFT-zone scan icon button calls this and forwards
  /// the scanned value into the search input.
  final Future<String?> Function()? onBarcodeScanRequest;

  /// Explicit override → tabbed layout regardless of width.
  final bool? forceCompact;

  /// Explicit override → 3-zone layout regardless of width.
  final bool? forceExpanded;

  /// Pass `Duration.zero` in tests to avoid pumping through an animation
  /// frame.
  final Duration animationDuration;

  @override
  State<EdenPOSRegisterScaffold> createState() =>
      _EdenPOSRegisterScaffoldState();
}

class _EdenPOSRegisterScaffoldState extends State<EdenPOSRegisterScaffold> {
  bool _receiptOpen = false;
  String? _selectedCategoryId;

  bool _resolveExpanded(BuildContext context, double maxWidth) {
    if (widget.forceCompact == true) return false;
    if (widget.forceExpanded == true) return true;
    final tier = EdenAdaptiveTierScope.maybeOf(context);
    if (tier == EdenAdaptiveTier.compact) return false;
    return maxWidth >=
        1024; // breakpoint: 1024 — POS register requires landscape tablet
  }

  void _emit(EdenPosSessionEvent ev) {
    final cb = widget.onSessionEvent;
    if (cb != null) cb(ev);
  }

  EdenReceiptData _deriveReceiptData() {
    final session = widget.session;
    final subtotal =
        session.cartItems.fold<int>(0, (s, i) => s + i.subtotalCents);
    const tax = 0;
    final tenders = <EdenReceiptTender>[];
    final t = session.tenderState;
    if (t != null) {
      tenders.add(EdenReceiptTender(
        method: _toReceiptTender(t.method),
        amountCents: t.amountCents,
        cashGivenCents: t.cashGivenCents,
        last4: t.last4,
      ));
    }
    return EdenReceiptData(
      storeHeader: const EdenReceiptStoreHeader(storeName: 'POS preview'),
      lineItems: [
        for (final c in session.cartItems)
          EdenReceiptLineItem(
            name: c.name,
            qty: c.qty,
            unitPriceCents: c.unitPriceCents,
            sku: c.sku,
          ),
      ],
      subtotalCents: subtotal,
      taxCents: tax,
      totalCents: subtotal + tax,
      tenderSummary: tenders,
      currency: session.currency,
    );
  }

  EdenReceiptTenderMethod _toReceiptTender(EdenPosTenderMethod m) {
    switch (m) {
      case EdenPosTenderMethod.cash:
        return EdenReceiptTenderMethod.cash;
      case EdenPosTenderMethod.card:
        return EdenReceiptTenderMethod.card;
      case EdenPosTenderMethod.check:
        return EdenReceiptTenderMethod.check;
      case EdenPosTenderMethod.account:
        return EdenReceiptTenderMethod.account;
      case EdenPosTenderMethod.giftCard:
        return EdenReceiptTenderMethod.giftCard;
      case EdenPosTenderMethod.split:
        return EdenReceiptTenderMethod.other;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = _resolveExpanded(context, constraints.maxWidth);
        final main = isWide ? _build3Zone() : _buildTabbed();
        return Stack(
          children: [
            Positioned.fill(child: main),
            AnimatedPositioned(
              duration: widget.animationDuration,
              right: _receiptOpen ? 0 : -380,
              top: 0,
              bottom: 0,
              width: 380,
              child: Material(
                elevation: 16,
                child: _receiptOpen
                    ? _ReceiptDrawer(
                        data: _deriveReceiptData(),
                        onClose: () => setState(() => _receiptOpen = false),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _build3Zone() {
    return Row(
      key: const ValueKey('eden-pos-3-zone'),
      children: [
        Expanded(flex: 44, child: _leftZone()),
        const VerticalDivider(width: 1),
        Expanded(flex: 32, child: _centerZone()),
        const VerticalDivider(width: 1),
        Expanded(flex: 24, child: _rightZone()),
      ],
    );
  }

  Widget _buildTabbed() {
    return DefaultTabController(
      length: 3,
      child: Column(
        key: const ValueKey('eden-pos-tabbed'),
        children: [
          const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.grid_view), text: 'Products'),
              Tab(icon: Icon(Icons.shopping_cart_outlined), text: 'Cart'),
              Tab(icon: Icon(Icons.payment), text: 'Tender'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _leftZone(),
                _centerZone(),
                _rightZone(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _leftZone() {
    return _LeftZone(
      products: widget.products,
      categories: widget.categories,
      selectedCategoryId: _selectedCategoryId,
      onCategorySelected: (id) => setState(() => _selectedCategoryId = id),
      onScanRequest: widget.onBarcodeScanRequest,
      onProductTap: (p) => _emit(EdenPosProductAdded(p)),
    );
  }

  Widget _centerZone() {
    return _CenterZone(
      session: widget.session,
      onAttach: widget.onAttachCustomerRequest,
      onDetach: () => _emit(EdenPosCustomerDetached()),
    );
  }

  Widget _rightZone() {
    return _RightZone(
      session: widget.session,
      onShowReceipt: () => setState(() => _receiptOpen = true),
      onTenderUpdated: (t) => _emit(EdenPosTenderUpdated(t)),
      onPaymentSubmitted: () => _emit(EdenPosPaymentSubmitted(widget.session)),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// LEFT zone — search + scan + product grid.
// ───────────────────────────────────────────────────────────────────────────

class _LeftZone extends StatefulWidget {
  const _LeftZone({
    required this.products,
    required this.onProductTap,
    this.categories,
    this.selectedCategoryId,
    this.onCategorySelected,
    this.onScanRequest,
  });

  final List<EdenQuickAddProduct> products;
  final void Function(EdenQuickAddProduct p) onProductTap;
  final List<EdenQuickAddCategory>? categories;
  final String? selectedCategoryId;
  final ValueChanged<String?>? onCategorySelected;
  final Future<String?> Function()? onScanRequest;

  @override
  State<_LeftZone> createState() => _LeftZoneState();
}

class _LeftZoneState extends State<_LeftZone> {
  final _searchCtl = TextEditingController();

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(EdenSpacing.space2),
          child: Row(
            children: [
              Expanded(
                child: EdenSearchInput(
                  controller: _searchCtl,
                  hint: 'Search products',
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  tooltip: 'Scan barcode',
                  onPressed: widget.onScanRequest == null
                      ? null
                      : () async {
                          final code = await widget.onScanRequest!();
                          if (code != null && mounted) {
                            _searchCtl.text = code;
                          }
                        },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: EdenQuickAddProductGrid(
            products: widget.products,
            categories: widget.categories,
            selectedCategoryId: widget.selectedCategoryId,
            onCategorySelected: widget.onCategorySelected,
            onTap: widget.onProductTap,
          ),
        ),
      ],
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// CENTER zone — customer header + cart shim.
// ───────────────────────────────────────────────────────────────────────────

class _CenterZone extends StatelessWidget {
  const _CenterZone({required this.session, this.onAttach, this.onDetach});
  final EdenPosSession session;
  final VoidCallback? onAttach;
  final VoidCallback? onDetach;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(EdenSpacing.space2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CustomerHeader(
            session: session,
            onAttach: onAttach,
            onDetach: onDetach,
          ),
          const SizedBox(height: 8),
          Expanded(
            // TODO(obj-014->obj-012 swap): replace with
            // EdenLineItemEditor<EdenPosCartItem>(items: session.cartItems,
            //   onQtyChanged: ..., onRemove: ...) once obj-012's generic
            // editable readOnly API is widely adopted.
            child: _CartShim(
              cartItems: session.cartItems,
              currency: session.currency,
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerHeader extends StatelessWidget {
  const _CustomerHeader({required this.session, this.onAttach, this.onDetach});

  final EdenPosSession session;
  final VoidCallback? onAttach;
  final VoidCallback? onDetach;

  EdenMembershipTier? _tierFromString(String? t) {
    switch (t?.toLowerCase()) {
      case 'bronze':
        return EdenMembershipTier.bronze;
      case 'silver':
        return EdenMembershipTier.silver;
      case 'gold':
        return EdenMembershipTier.gold;
      case 'platinum':
        return EdenMembershipTier.platinum;
      case 'vip':
        return EdenMembershipTier.vip;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = session.customer;
    if (c == null) {
      return SizedBox(
        height: 48,
        child: EdenButton(
          label: 'Attach customer',
          onPressed: onAttach,
        ),
      );
    }
    final theme = Theme.of(context);
    final tierEnum = _tierFromString(c.tier);
    return Row(
      children: [
        if (tierEnum != null)
          EdenMembershipTierBadge(tier: tierEnum)
        else if (c.tier != null)
          EdenMembershipTierBadge.custom(
            label: c.tier!,
            backgroundColor: theme.colorScheme.secondaryContainer,
            foregroundColor: theme.colorScheme.onSecondaryContainer,
          ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            c.name,
            style: theme.textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(
          width: 48,
          height: 48,
          child: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Detach customer',
            onPressed: onDetach,
          ),
        ),
      ],
    );
  }
}

class _CartShim extends StatelessWidget {
  const _CartShim({required this.cartItems, required this.currency});

  final List<EdenPosCartItem> cartItems;
  final String currency;

  @override
  Widget build(BuildContext context) {
    if (cartItems.isEmpty) {
      return Center(
        child: Text(
          'Cart is empty',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    return ListView.builder(
      itemCount: cartItems.length,
      itemBuilder: (ctx, i) {
        final item = cartItems[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 36,
                child: Text('${item.qty}x'),
              ),
              Expanded(
                child: Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              EdenCurrencyDisplay(
                cents: item.subtotalCents,
                currencyCode: currency,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// RIGHT zone — tender method picker + classified PAN entry + Submit.
// ───────────────────────────────────────────────────────────────────────────

class _RightZone extends StatelessWidget {
  const _RightZone({
    required this.session,
    required this.onShowReceipt,
    required this.onTenderUpdated,
    required this.onPaymentSubmitted,
  });

  final EdenPosSession session;
  final VoidCallback onShowReceipt;
  final void Function(EdenPosTenderState) onTenderUpdated;
  final VoidCallback onPaymentSubmitted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(EdenSpacing.space2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Tender', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          // TODO(obj-014->obj-012 swap): replace with
          // EdenSplitTender(...) once obj-012's tender widget's generic
          // API is widely adopted.
          Expanded(
            child: _TenderShim(
              session: session,
              onTenderUpdated: onTenderUpdated,
              onSubmit: onPaymentSubmitted,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.receipt_long),
              label: const Text('Show receipt'),
              onPressed: onShowReceipt,
            ),
          ),
        ],
      ),
    );
  }
}

class _TenderShim extends StatefulWidget {
  const _TenderShim({
    required this.session,
    required this.onTenderUpdated,
    required this.onSubmit,
  });

  final EdenPosSession session;
  final void Function(EdenPosTenderState) onTenderUpdated;
  final VoidCallback onSubmit;

  @override
  State<_TenderShim> createState() => _TenderShimState();
}

class _TenderShimState extends State<_TenderShim> {
  EdenPosTenderMethod _method = EdenPosTenderMethod.cash;
  String _pan = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (final m in EdenPosTenderMethod.values)
              ChoiceChip(
                label: Text(m.name),
                selected: _method == m,
                onSelected: (_) => setState(() => _method = m),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_method == EdenPosTenderMethod.card) ...[
          Text(
            'Card number (PCI classified entry)',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 4),
          // PCI compliance gate: card-number entry uses EdenSecretField
          // in classified clipboard mode (shipped via obj-011-08).
          EdenSecretField(
            value: _pan,
            label: 'PAN',
            clipboardMode: EdenSecretClipboardMode.classified,
            onChanged: (v) {
              setState(() => _pan = v);
              widget.onTenderUpdated(EdenPosTenderState(
                method: _method,
                amountCents: 0,
                panClassified: v,
              ));
            },
          ),
        ],
        const Spacer(),
        SizedBox(
          height: 48,
          child: EdenButton(
            label: 'Submit payment',
            onPressed: widget.onSubmit,
          ),
        ),
      ],
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Receipt slide-out drawer.
// ───────────────────────────────────────────────────────────────────────────

class _ReceiptDrawer extends StatelessWidget {
  const _ReceiptDrawer({required this.data, required this.onClose});
  final EdenReceiptData data;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          title: const Text('Receipt'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Close receipt',
              onPressed: onClose,
            ),
          ],
        ),
        Expanded(
          child: EdenReceiptPreview(data: data),
        ),
      ],
    );
  }
}
