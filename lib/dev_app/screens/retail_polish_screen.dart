import 'package:flutter/material.dart';

import '../../eden_ui.dart';
import '../widgets/section.dart';

/// Dev-catalog screen for Objective 018 — Retail-Specific Polish.
///
/// TRD 018-01 creates the file with the [EdenLoyaltyMemberDetail] section.
/// TRDs 018-02 through 018-06 each append additional `Section(...)` entries
/// at the marked anchor comments — they do NOT re-create the file.
class RetailPolishScreen extends StatelessWidget {
  const RetailPolishScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('B-Retail — Customer & Service Flows')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          // ─── Wave 1 — Atomic primitives ────────────────────────────────
          Section(
            title:
                'EdenLoyaltyMemberDetail — loyalty profile (tier + points + recent purchases)',
            child: _LoyaltyMemberDetailDemoBlock(),
          ),
          // TRD 018-02 appended above.
          Section(
            title:
                'EdenStoreCreditLedger — store-credit balance + history + holds',
            child: _StoreCreditLedgerDemoBlock(),
          ),
          // TRD 018-03 appended above.
          Section(
            title:
                'EdenGiftCardBalanceLookup — gift-card balance + activity',
            child: _GiftCardBalanceLookupDemoBlock(),
          ),
          // ─── Wave 2 — Multi-step flows ─────────────────────────────────
          // TRD 018-04 appended above.
          Section(
            title:
                'EdenRefundFlow — multi-step refund (lookup → select → method → approve)',
            child: _RefundFlowDemoBlock(),
          ),
          // TRD 018-05 appended above.
          Section(
            title:
                'EdenLayawayFlow — layaway lifecycle (create + manage)',
            child: _LayawayFlowDemoBlock(),
          ),
          // TRD 018-06 appended above.
          Section(
            title:
                'EdenStoreTransferFlow — inter-location inventory transfer (dispatch + receive)',
            child: _StoreTransferDemoBlock(),
          ),
        ],
      ),
    );
  }
}

/// Hand-built sample data — mirrors
/// test/widgets/_fixtures/eden_loyalty_member_detail_fixtures.dart::janeGold().
/// Do NOT regenerate via LLM.
class _LoyaltyMemberDetailDemoBlock extends StatelessWidget {
  const _LoyaltyMemberDetailDemoBlock();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final member = EdenLoyaltyMember(
      id: 'c-1',
      name: 'Jane Doe',
      tier: EdenMembershipTier.gold,
      points: 1247,
      lifetimeSpendCents: 18950,
      birthday: DateTime(now.year - 32, now.month, now.day + 3),
      joinedAt: DateTime(now.year - 2, now.month, 1),
      recentPurchases: [
        EdenLoyaltyPurchase(
          id: 'p-1',
          occurredAt: now.subtract(const Duration(days: 1)),
          totalCents: 1875,
          lineCount: 3,
          locationName: 'Downtown',
        ),
        EdenLoyaltyPurchase(
          id: 'p-2',
          occurredAt: now.subtract(const Duration(days: 7)),
          totalCents: 4200,
          lineCount: 5,
          locationName: 'Downtown',
        ),
        EdenLoyaltyPurchase(
          id: 'p-3',
          occurredAt: now.subtract(const Duration(days: 21)),
          totalCents: 950,
          lineCount: 1,
          locationName: 'Airport',
        ),
      ],
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: EdenLoyaltyMemberDetail(member: member),
    );
  }
}

/// Hand-built sample data — mirrors
/// test/widgets/_fixtures/eden_store_credit_ledger_fixtures.dart::activeWithHolds().
/// Do NOT regenerate via LLM.
class _StoreCreditLedgerDemoBlock extends StatelessWidget {
  const _StoreCreditLedgerDemoBlock();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final data = EdenStoreCreditLedgerData(
      customerId: 'c-1',
      customerName: 'Jane Doe',
      balanceCents: 8750,
      holds: [
        EdenStoreCreditHold(
          id: 'h-1',
          holdAmountCents: 1500,
          holdReason: 'Pending refund verification',
          placedAt: now.subtract(const Duration(hours: 6)),
        ),
      ],
      history: [
        EdenStoreCreditEntry(
          id: 'e-1',
          occurredAt: now.subtract(const Duration(days: 2)),
          type: EdenStoreCreditEntryType.issued,
          amountCents: 5000,
          reason: 'No-receipt return',
          receiptRef: 'R-1003',
        ),
        EdenStoreCreditEntry(
          id: 'e-2',
          occurredAt: now.subtract(const Duration(days: 5)),
          type: EdenStoreCreditEntryType.spent,
          amountCents: -2250,
          reason: 'Applied to sale',
          receiptRef: 'R-1011',
        ),
        EdenStoreCreditEntry(
          id: 'e-3',
          occurredAt: now.subtract(const Duration(days: 15)),
          type: EdenStoreCreditEntryType.issued,
          amountCents: 6000,
          reason: 'Loyalty bonus',
        ),
        EdenStoreCreditEntry(
          id: 'e-4',
          occurredAt: now.subtract(const Duration(days: 30)),
          type: EdenStoreCreditEntryType.adjustment,
          amountCents: -750,
          reason: 'Manager correction',
        ),
      ],
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 800),
      child: EdenStoreCreditLedger(data: data),
    );
  }
}

/// Hand-built demo lookup function for EdenGiftCardBalanceLookup.
/// Do NOT regenerate via LLM.
class _GiftCardBalanceLookupDemoBlock extends StatelessWidget {
  const _GiftCardBalanceLookupDemoBlock();

  static Future<EdenGiftCardBalanceResult?> _demoLookup(
      String cardNumber) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final clean = cardNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) return null;
    if (clean.endsWith('0000')) return null; // not found
    if (clean.endsWith('1111')) {
      return EdenGiftCardBalanceResult(
        cardNumber: clean,
        balanceCents: 0,
        status: EdenGiftCardStatus.deactivated,
      );
    }
    final now = DateTime.now();
    return EdenGiftCardBalanceResult(
      cardNumber: clean,
      balanceCents: 4250,
      status: EdenGiftCardStatus.active,
      lastUsedAt: now.subtract(const Duration(days: 5)),
      expiresAt: DateTime(now.year + 2, now.month, now.day),
      recentActivity: [
        EdenGiftCardActivity(
          id: 'a-1',
          occurredAt: now.subtract(const Duration(days: 5)),
          type: EdenGiftCardActivityType.redeemed,
          amountCents: -1500,
          reason: 'POS sale',
          receiptRef: 'R-2103',
        ),
        EdenGiftCardActivity(
          id: 'a-2',
          occurredAt: now.subtract(const Duration(days: 12)),
          type: EdenGiftCardActivityType.loaded,
          amountCents: 5000,
          reason: 'New card',
          receiptRef: 'R-2087',
        ),
        EdenGiftCardActivity(
          id: 'a-3',
          occurredAt: now.subtract(const Duration(days: 18)),
          type: EdenGiftCardActivityType.adjustment,
          amountCents: 750,
          reason: 'Promo bonus',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: const EdenGiftCardBalanceLookup(onLookup: _demoLookup),
    );
  }
}

/// Hand-built demo lookup + approval functions for EdenRefundFlow.
/// Do NOT regenerate via LLM.
class _RefundFlowDemoBlock extends StatelessWidget {
  const _RefundFlowDemoBlock();

  static Future<EdenSaleRecord?> _lookup(String query) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final trimmed = query.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'no-sale') return null;
    final now = DateTime.now();
    return EdenSaleRecord(
      saleId: 'S-1042',
      occurredAt: now.subtract(const Duration(days: 3)),
      originalTender: EdenPaymentMethod.card,
      originalTotalCents: 8950,
      customerId: 'c-1',
      customerName: 'Jane Doe',
      receiptRef: 'R-1042',
      lines: const [
        EdenSaleLine(
          lineId: 'L-1',
          sku: 'SKU-A',
          name: 'Espresso 1kg',
          originalQty: 2,
          unitPriceCents: 2500,
          taxCents: 200,
          refundableQty: 2,
        ),
        EdenSaleLine(
          lineId: 'L-2',
          sku: 'SKU-B',
          name: 'Mocha mix',
          originalQty: 1,
          unitPriceCents: 900,
          taxCents: 75,
          refundableQty: 1,
        ),
        EdenSaleLine(
          lineId: 'L-3',
          sku: 'SKU-C',
          name: 'Filter coffee',
          originalQty: 3,
          unitPriceCents: 800,
          taxCents: 175,
          refundableQty: 3,
        ),
      ],
    );
  }

  static Future<bool> _managerApprove() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 720,
      child: EdenRefundFlow(
        onLookupSale: _lookup,
        onManagerApprove: _managerApprove,
        onSubmit: (draft) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Refund submitted: ${draft.refundLines.length} lines, '
                '${draft.method.name}, '
                'total \$${(draft.totalRefundCents / 100).toStringAsFixed(2)}',
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Hand-built demo for EdenLayawayFlow — toggle between create and manage.
/// Do NOT regenerate via LLM.
class _LayawayFlowDemoBlock extends StatefulWidget {
  const _LayawayFlowDemoBlock();

  @override
  State<_LayawayFlowDemoBlock> createState() => _LayawayFlowDemoBlockState();
}

class _LayawayFlowDemoBlockState extends State<_LayawayFlowDemoBlock> {
  bool _showManage = false;

  static const _cart = [
    EdenLayawayCartItem(
      lineId: 'L-1',
      sku: 'SKU-A',
      name: 'Leather jacket',
      qty: 1,
      unitPriceCents: 25000,
      taxCents: 2000,
    ),
    EdenLayawayCartItem(
      lineId: 'L-2',
      sku: 'SKU-B',
      name: 'Belt',
      qty: 1,
      unitPriceCents: 3500,
      taxCents: 280,
    ),
  ];

  EdenLayawayState _manageState() {
    final now = DateTime.now();
    return EdenLayawayState(
      id: 'LAY-001',
      cartItems: _cart,
      depositCents: 6156,
      balanceCents: 18468,
      pickupByDate: now.add(const Duration(days: 30)),
      status: EdenLayawayStatus.active,
      customerId: 'c-1',
      customerName: 'Jane Doe',
      installments: [
        EdenLayawayInstallment(
          id: 'INS-1',
          paidAt: now.subtract(const Duration(days: 10)),
          amountCents: 6156,
          method: EdenPaymentMethod.card,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          title: const Text('Manage existing layaway'),
          value: _showManage,
          onChanged: (v) => setState(() => _showManage = v),
        ),
        SizedBox(
          height: 600,
          child: _showManage
              ? EdenLayawayFlow.manage(
                  state: _manageState(),
                  onSubmit: (d) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Manage: ${d.kind.name}')),
                    );
                  },
                  onNotifyCustomer: (ch, msg) async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Notify ${ch.name}: $msg')),
                    );
                  },
                )
              : EdenLayawayFlow.create(
                  cartItems: _cart,
                  onSubmit: (d) {
                    final created = d as EdenLayawayCreatedDraft;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Created layaway: deposit \$${(created.depositCents / 100).toStringAsFixed(2)}',
                        ),
                      ),
                    );
                  },
                  onNotifyCustomer: (ch, msg) async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Notify ${ch.name}: $msg')),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Hand-built demo for EdenStoreTransferFlow — toggle dispatch vs receive.
/// Do NOT regenerate via LLM.
class _StoreTransferDemoBlock extends StatefulWidget {
  const _StoreTransferDemoBlock();

  @override
  State<_StoreTransferDemoBlock> createState() =>
      _StoreTransferDemoBlockState();
}

class _StoreTransferDemoBlockState extends State<_StoreTransferDemoBlock> {
  bool _showReceive = false;

  static const _locations = [
    EdenLocation(id: 'L-DOWN', name: 'Downtown'),
    EdenLocation(id: 'L-AIR', name: 'Airport'),
    EdenLocation(id: 'L-FLAG', name: 'Flagship'),
  ];

  EdenStoreTransfer _inTransitDemoTransfer() {
    return EdenStoreTransfer(
      id: 'XFR-101',
      sourceLocation: _locations[0],
      destLocation: _locations[1],
      items: const [
        EdenStoreTransferItem(
          lineId: 'I-1',
          sku: 'SKU-A',
          name: 'Espresso 1kg',
          qty: 12,
          unitLabel: 'kg',
        ),
        EdenStoreTransferItem(
          lineId: 'I-2',
          sku: 'SKU-B',
          name: 'Mocha mix',
          qty: 6,
        ),
      ],
      status: EdenStoreTransferStatus.inTransit,
      shippingCarrier: 'FedEx',
      trackingRef: 'TRK-999-001',
      dispatchedAt: DateTime.now().subtract(const Duration(hours: 12)),
    );
  }

  Future<EdenStoreTransferItem?> _demoItemLookup(String q) async {
    final clean = q.trim();
    if (clean.isEmpty || clean.toLowerCase() == 'nope') return null;
    return EdenStoreTransferItem(
      lineId: 'D-${clean.hashCode.abs()}',
      sku: clean,
      name: 'Item for $clean',
      qty: 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          title: const Text('Receive existing in-transit'),
          value: _showReceive,
          onChanged: (v) => setState(() => _showReceive = v),
        ),
        SizedBox(
          height: 600,
          child: _showReceive
              ? EdenStoreTransferFlow.receive(
                  initialTransfer: _inTransitDemoTransfer(),
                  onSubmit: (d) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Received transfer ${d.transferId} (${d.perLineVariance.length} variance)',
                        ),
                      ),
                    );
                  },
                )
              : EdenStoreTransferFlow.dispatch(
                  availableLocations: _locations,
                  onItemLookup: _demoItemLookup,
                  onSubmit: (d) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Dispatched ${d.items.length} items '
                          '${d.sourceLocationId} → ${d.destLocationId}',
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
