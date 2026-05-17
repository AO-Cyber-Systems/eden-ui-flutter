import 'package:flutter/material.dart';

import '../tokens/spacing.dart';
import 'eden_alert.dart';
import 'eden_input.dart';
import 'eden_search_input.dart';
import 'eden_select.dart';

// ───────────────────────────────────────────────────────────────────────────
// Value classes — receiving doc + line items + draft submission shape.
// ───────────────────────────────────────────────────────────────────────────

/// Purchase order document with expected line items. Consumer fetches this
/// asynchronously via the [EdenReceivingFlow.onPoLookup] callback (typically
/// hitting their backend / Connect RPC service).
@immutable
class EdenReceivingDoc {
  const EdenReceivingDoc({
    required this.poNumber,
    required this.vendor,
    required this.expectedItems,
    this.expectedTotalCents,
    this.expectedAt,
    this.notes,
  });

  final String poNumber;
  final String vendor;
  final List<EdenReceivingExpectedItem> expectedItems;
  final int? expectedTotalCents;
  final DateTime? expectedAt;
  final String? notes;
}

@immutable
class EdenReceivingExpectedItem {
  const EdenReceivingExpectedItem({
    required this.lineId,
    required this.sku,
    required this.name,
    required this.expectedQty,
    required this.expectedUnitCostCents,
    this.unitLabel = 'ea',
  });

  final String lineId;
  final String sku;
  final String name;
  final num expectedQty;
  final int expectedUnitCostCents;
  final String unitLabel;
}

@immutable
class EdenReceivingReceivedItem {
  const EdenReceivingReceivedItem({
    required this.lineId,
    required this.receivedQty,
    this.varianceReason,
    this.newUnitCostCents,
    this.photoRef,
  });

  final String lineId;
  final num receivedQty;
  final EdenVarianceReason? varianceReason;
  final int? newUnitCostCents;
  final String? photoRef;

  EdenReceivingReceivedItem copyWith({
    num? receivedQty,
    EdenVarianceReason? varianceReason,
    int? newUnitCostCents,
    String? photoRef,
    bool clearVarianceReason = false,
    bool clearNewUnitCostCents = false,
  }) {
    return EdenReceivingReceivedItem(
      lineId: lineId,
      receivedQty: receivedQty ?? this.receivedQty,
      varianceReason: clearVarianceReason
          ? null
          : (varianceReason ?? this.varianceReason),
      newUnitCostCents: clearNewUnitCostCents
          ? null
          : (newUnitCostCents ?? this.newUnitCostCents),
      photoRef: photoRef ?? this.photoRef,
    );
  }
}

enum EdenVarianceReason {
  damaged,
  shortQty,
  overShipped,
  wrongItem,
  unopened,
  other,
}

extension EdenVarianceReasonLabel on EdenVarianceReason {
  String get label {
    switch (this) {
      case EdenVarianceReason.damaged:
        return 'Damaged';
      case EdenVarianceReason.shortQty:
        return 'Short qty';
      case EdenVarianceReason.overShipped:
        return 'Over shipped';
      case EdenVarianceReason.wrongItem:
        return 'Wrong item';
      case EdenVarianceReason.unopened:
        return 'Unopened';
      case EdenVarianceReason.other:
        return 'Other';
    }
  }
}

enum EdenReceivingDisposition { receivePartial, receiveFull, damaged }

extension EdenReceivingDispositionLabel on EdenReceivingDisposition {
  String get label {
    switch (this) {
      case EdenReceivingDisposition.receivePartial:
        return 'Receive partial';
      case EdenReceivingDisposition.receiveFull:
        return 'Receive full';
      case EdenReceivingDisposition.damaged:
        return 'Damaged';
    }
  }
}

@immutable
class EdenReceivingDraft {
  const EdenReceivingDraft({
    required this.poNumber,
    required this.disposition,
    required this.receivedItems,
    this.damagedPhotoRef,
    this.notes,
  });

  final String poNumber;
  final EdenReceivingDisposition disposition;
  final List<EdenReceivingReceivedItem> receivedItems;
  final String? damagedPhotoRef;
  final String? notes;
}

enum EdenReceivingStep { selectPo, variance, costUpdate, disposition }

// ───────────────────────────────────────────────────────────────────────────
// EdenReceivingFlow
// ───────────────────────────────────────────────────────────────────────────

/// Multi-step PO receiving flow primitive. Sequential steps:
///
/// 1. **SelectPo** — search/scan input → consumer's [onPoLookup] callback
///    returns an [EdenReceivingDoc] (or null → 'PO not found' alert).
/// 2. **Variance** — split-pane (≥700pt) or tabbed (<700pt). Expected line
///    items on the left/first tab; editable received quantities on the
///    right/second tab. Per-row [EdenSelect] for variance reasons appears
///    when received qty != expected qty.
/// 3. **CostUpdate** — auto-skipped when no row has a variance reason set.
///    Otherwise shows an optional new-unit-cost input per varianced row.
/// 4. **Disposition** — three [RadioListTile]s (receivePartial / receiveFull
///    / damaged). When `damaged` is selected, an 'Attach photo' button
///    surfaces and Submit stays disabled until [onPhotoCapture] returns a
///    non-null photo ref.
///
/// Final commit emits [EdenReceivingDraft] via [onSubmit]. The widget never
/// persists; the consumer is responsible for posting the draft to backend.
///
/// **Photo capture** is callback-only. Consumer wires their preferred
/// camera plugin in [onPhotoCapture] returning a `Future<String?>` (signed
/// URL / local path / null on user cancel).
///
/// **Cross-vertical:** retail back-office incoming shipments, trades
/// materials receiving, salon product replenishment, fuel parts receiving,
/// medical supply ledger intake.
class EdenReceivingFlow extends StatefulWidget {
  const EdenReceivingFlow({
    super.key,
    required this.onPoLookup,
    required this.onSubmit,
    this.onPhotoCapture,
    this.onBarcodeScanRequest,
    this.initialDoc,
  });

  final Future<EdenReceivingDoc?> Function(String query) onPoLookup;
  final void Function(EdenReceivingDraft draft) onSubmit;
  final Future<String?> Function()? onPhotoCapture;
  final Future<String?> Function()? onBarcodeScanRequest;

  /// When provided, the flow boots directly into the variance step with
  /// this document pre-loaded. Useful for tests + flows that already have
  /// a PO context.
  final EdenReceivingDoc? initialDoc;

  @override
  State<EdenReceivingFlow> createState() => _EdenReceivingFlowState();
}

class _EdenReceivingFlowState extends State<EdenReceivingFlow> {
  EdenReceivingStep _step = EdenReceivingStep.selectPo;
  EdenReceivingDoc? _doc;
  final Map<String, EdenReceivingReceivedItem> _received = {};
  EdenReceivingDisposition? _disposition;
  String? _damagedPhotoRef;
  bool _costUpdateVisited = false;
  String _poNotFound = '';
  bool _lookupInFlight = false;

  late TextEditingController _poQueryCtl;
  // Per-line-id qty controllers — initialized in _initializeReceived.
  final Map<String, TextEditingController> _qtyCtls = {};
  // Per-line-id cost controllers — initialized lazily on costUpdate entry.
  final Map<String, TextEditingController> _costCtls = {};

  @override
  void initState() {
    super.initState();
    _poQueryCtl = TextEditingController();
    if (widget.initialDoc != null) {
      _doc = widget.initialDoc;
      _step = EdenReceivingStep.variance;
      _initializeReceived();
    }
  }

  @override
  void dispose() {
    _poQueryCtl.dispose();
    for (final c in _qtyCtls.values) {
      c.dispose();
    }
    for (final c in _costCtls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _initializeReceived() {
    _received.clear();
    for (final c in _qtyCtls.values) {
      c.dispose();
    }
    _qtyCtls.clear();
    if (_doc == null) return;
    for (final e in _doc!.expectedItems) {
      _received[e.lineId] = EdenReceivingReceivedItem(
        lineId: e.lineId,
        receivedQty: e.expectedQty,
      );
      _qtyCtls[e.lineId] = TextEditingController(
        text: e.expectedQty.toString(),
      );
    }
  }

  Future<void> _runLookup() async {
    final query = _poQueryCtl.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _lookupInFlight = true;
      _poNotFound = '';
    });
    try {
      final result = await widget.onPoLookup(query);
      if (!mounted) return;
      setState(() {
        _lookupInFlight = false;
        if (result == null) {
          _poNotFound = 'PO not found';
        } else {
          _doc = result;
          _initializeReceived();
          _step = EdenReceivingStep.variance;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _lookupInFlight = false;
        _poNotFound = 'PO not found';
      });
    }
  }

  bool _hasAnyVariance() {
    if (_doc == null) return false;
    return _received.values.any((r) => r.varianceReason != null);
  }

  void _next() {
    setState(() {
      switch (_step) {
        case EdenReceivingStep.selectPo:
          // Step 1 advances on lookup, not Next.
          break;
        case EdenReceivingStep.variance:
          if (_hasAnyVariance()) {
            _step = EdenReceivingStep.costUpdate;
            _costUpdateVisited = true;
          } else {
            _step = EdenReceivingStep.disposition;
          }
          break;
        case EdenReceivingStep.costUpdate:
          _step = EdenReceivingStep.disposition;
          break;
        case EdenReceivingStep.disposition:
          break;
      }
    });
  }

  void _back() {
    setState(() {
      switch (_step) {
        case EdenReceivingStep.selectPo:
          break;
        case EdenReceivingStep.variance:
          _step = EdenReceivingStep.selectPo;
          _doc = null;
          _received.clear();
          _costUpdateVisited = false;
          break;
        case EdenReceivingStep.costUpdate:
          _step = EdenReceivingStep.variance;
          break;
        case EdenReceivingStep.disposition:
          _step = _costUpdateVisited
              ? EdenReceivingStep.costUpdate
              : EdenReceivingStep.variance;
          break;
      }
    });
  }

  bool _canSubmit() {
    if (_disposition == null) return false;
    if (_disposition == EdenReceivingDisposition.damaged &&
        _damagedPhotoRef == null) {
      return false;
    }
    return true;
  }

  void _submit() {
    if (!_canSubmit()) return;
    widget.onSubmit(EdenReceivingDraft(
      poNumber: _doc!.poNumber,
      disposition: _disposition!,
      receivedItems: _received.values.toList(),
      damagedPhotoRef: _damagedPhotoRef,
    ));
  }

  @override
  Widget build(BuildContext context) {
    switch (_step) {
      case EdenReceivingStep.selectPo:
        return _buildSelectPo();
      case EdenReceivingStep.variance:
        return _buildVariance();
      case EdenReceivingStep.costUpdate:
        return _buildCostUpdate();
      case EdenReceivingStep.disposition:
        return _buildDisposition();
    }
  }

  Widget _stepHeader(int step, int total, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        'Step $step of $total — $label',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }

  // ─── Step 1: SelectPo ──────────────────────────────────────────────────

  Widget _buildSelectPo() {
    return Padding(
      key: const ValueKey('eden-receiving-step-selectPo'),
      padding: const EdgeInsets.all(EdenSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(1, 4, 'Select PO'),
          Row(
            children: [
              Expanded(
                child: EdenSearchInput(
                  controller: _poQueryCtl,
                  hint: 'PO number',
                  onSubmitted: (_) => _runLookup(),
                ),
              ),
              const SizedBox(width: 8),
              if (widget.onBarcodeScanRequest != null)
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  tooltip: 'Scan barcode',
                  onPressed: () async {
                    final scanned = await widget.onBarcodeScanRequest!();
                    if (scanned != null && mounted) {
                      _poQueryCtl.text = scanned;
                      await _runLookup();
                    }
                  },
                ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _lookupInFlight ? null : _runLookup,
                child: const Text('Lookup'),
              ),
            ],
          ),
          if (_poNotFound.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: EdenAlert(
                message: _poNotFound,
                variant: EdenAlertVariant.danger,
              ),
            ),
          if (_lookupInFlight)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }

  // ─── Step 2: Variance ──────────────────────────────────────────────────

  Widget _buildVariance() {
    return Padding(
      key: const ValueKey('eden-receiving-step-variance'),
      padding: const EdgeInsets.all(EdenSpacing.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(2, 4, 'Variance — ${_doc!.poNumber} (${_doc!.vendor})'),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 700) {
                  return Row(
                    key: const ValueKey('eden-receiving-variance-split'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _expectedPane()),
                      const VerticalDivider(width: 1),
                      Expanded(child: _receivedPane()),
                    ],
                  );
                }
                return DefaultTabController(
                  key: const ValueKey('eden-receiving-variance-tabbed'),
                  length: 2,
                  child: Column(
                    children: [
                      const TabBar(
                        tabs: [
                          Tab(text: 'Expected'),
                          Tab(text: 'Received'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [_expectedPane(), _receivedPane()],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          _navRow(showNext: true),
        ],
      ),
    );
  }

  Widget _expectedPane() {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        Text('Expected', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        for (final e in _doc!.expectedItems)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text('${e.sku} — ${e.name}',
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                Text('${e.expectedQty} ${e.unitLabel}'),
              ],
            ),
          ),
      ],
    );
  }

  Widget _receivedPane() {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        Text('Received', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        for (final e in _doc!.expectedItems) _receivedRow(e),
      ],
    );
  }

  Widget _receivedRow(EdenReceivingExpectedItem e) {
    final received = _received[e.lineId]!;
    final mismatch = received.receivedQty != e.expectedQty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${e.sku} — ${e.name}',
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Row(
            children: [
              SizedBox(
                width: 100,
                child: EdenInput(
                  key: ValueKey('received-qty-${e.lineId}'),
                  controller: _qtyCtls[e.lineId],
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  size: EdenInputSize.sm,
                  onChanged: (v) {
                    final parsed = num.tryParse(v);
                    if (parsed == null) return;
                    setState(() {
                      final next = received.copyWith(
                        receivedQty: parsed,
                        // Clear variance reason if user returns qty back to
                        // expected; consumer can re-pick if mismatched again.
                        clearVarianceReason: parsed == e.expectedQty,
                      );
                      _received[e.lineId] = next;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Text('of ${e.expectedQty} ${e.unitLabel}',
                  style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
          if (mismatch)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: SizedBox(
                width: 220,
                child: EdenSelect<EdenVarianceReason>(
                  value: received.varianceReason,
                  hint: 'Variance reason',
                  options: [
                    for (final r in EdenVarianceReason.values)
                      EdenSelectOption(value: r, label: r.label),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _received[e.lineId] = _received[e.lineId]!.copyWith(
                        varianceReason: v,
                      );
                    });
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Step 3: CostUpdate ────────────────────────────────────────────────

  Widget _buildCostUpdate() {
    final variancedLines = _doc!.expectedItems.where((e) {
      return _received[e.lineId]?.varianceReason != null;
    }).toList();
    return Padding(
      key: const ValueKey('eden-receiving-step-costUpdate'),
      padding: const EdgeInsets.all(EdenSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(3, 4, 'Cost adjustments'),
          Expanded(
            child: ListView(
              children: [
                for (final e in variancedLines)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(child: Text('${e.sku} — ${e.name}')),
                        const SizedBox(width: 12),
                        Text(
                          'Was: \$'
                          '${(e.expectedUnitCostCents / 100).toStringAsFixed(2)}',
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 120,
                          child: EdenInput(
                            controller: _costCtls.putIfAbsent(
                              e.lineId,
                              () => TextEditingController(),
                            ),
                            hint: 'New cost',
                            size: EdenInputSize.sm,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                            onChanged: (v) {
                              final parsed = double.tryParse(v);
                              setState(() {
                                final existing = _received[e.lineId]!;
                                _received[e.lineId] = existing.copyWith(
                                  newUnitCostCents: parsed == null
                                      ? null
                                      : (parsed * 100).round(),
                                  clearNewUnitCostCents: parsed == null,
                                );
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _navRow(showNext: true),
        ],
      ),
    );
  }

  // ─── Step 4: Disposition + Submit ──────────────────────────────────────

  Widget _buildDisposition() {
    return Padding(
      key: const ValueKey('eden-receiving-step-disposition'),
      padding: const EdgeInsets.all(EdenSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(4, 4, 'Disposition'),
          for (final d in EdenReceivingDisposition.values)
            RadioListTile<EdenReceivingDisposition>(
              title: Text(d.label),
              value: d,
              groupValue: _disposition,
              onChanged: (v) => setState(() {
                _disposition = v;
                if (v != EdenReceivingDisposition.damaged) {
                  _damagedPhotoRef = null;
                }
              }),
            ),
          if (_disposition == EdenReceivingDisposition.damaged)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: Text(
                      _damagedPhotoRef == null
                          ? 'Attach photo'
                          : 'Photo attached',
                    ),
                    onPressed: widget.onPhotoCapture == null
                        ? null
                        : () async {
                            final ref = await widget.onPhotoCapture!();
                            if (!mounted) return;
                            setState(() => _damagedPhotoRef = ref);
                          },
                  ),
                ],
              ),
            ),
          const Spacer(),
          _navRow(showNext: false, showSubmit: true),
        ],
      ),
    );
  }

  // ─── Shared nav row ────────────────────────────────────────────────────

  Widget _navRow({required bool showNext, bool showSubmit = false}) {
    final showBack = _step != EdenReceivingStep.selectPo;
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        if (showBack)
          OutlinedButton(
            onPressed: _back,
            child: const Text('Back'),
          ),
        const Spacer(),
        if (showNext)
          ElevatedButton(
            onPressed: _next,
            child: const Text('Next'),
          ),
        if (showSubmit)
          ElevatedButton(
            onPressed: _canSubmit() ? _submit : null,
            child: const Text('Submit'),
          ),
      ],
    );
  }
}
