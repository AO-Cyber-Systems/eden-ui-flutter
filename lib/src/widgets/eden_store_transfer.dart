// Store-transfer flow primitive. Inter-location inventory transfer.
//
// Two operating modes:
//   - EdenStoreTransferFlow.dispatch — origin store: 4-step dispatch leg
//     (selectLocations → selectItems → shipping → confirmDispatch).
//   - EdenStoreTransferFlow.receive — destination store: single-step
//     receive leg with per-line variance picker.
//
// Reuses obj 014-05 EdenVarianceReason enum (exported via eden_ui.dart
// because eden_receiving_flow.dart is exported as a whole). No new pubspec
// deps.

import 'package:flutter/material.dart';

import '../tokens/spacing.dart';
import 'eden_alert.dart';
import 'eden_input.dart';
import 'eden_receiving_flow.dart' show EdenVarianceReason;
import 'eden_search_input.dart';
import 'eden_select.dart';

// ─────────────────────────────────────────────────────────────────────────
// Value classes + enums
// ─────────────────────────────────────────────────────────────────────────

@immutable
class EdenLocation {
  const EdenLocation({
    required this.id,
    required this.name,
    this.displayLabel,
  });

  final String id;
  final String name;
  final String? displayLabel;

  String get effectiveLabel => displayLabel ?? name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EdenLocation && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

@immutable
class EdenStoreTransferItem {
  const EdenStoreTransferItem({
    required this.lineId,
    required this.sku,
    required this.name,
    required this.qty,
    this.unitLabel = 'ea',
    this.varianceReason,
    this.receivedQty,
  });

  final String lineId;
  final String sku;
  final String name;
  final num qty;
  final String unitLabel;
  final EdenVarianceReason? varianceReason;
  final num? receivedQty;

  EdenStoreTransferItem copyWith({
    num? qty,
    EdenVarianceReason? varianceReason,
    num? receivedQty,
    bool clearVariance = false,
  }) {
    return EdenStoreTransferItem(
      lineId: lineId,
      sku: sku,
      name: name,
      qty: qty ?? this.qty,
      unitLabel: unitLabel,
      varianceReason:
          clearVariance ? null : (varianceReason ?? this.varianceReason),
      receivedQty: receivedQty ?? this.receivedQty,
    );
  }
}

enum EdenStoreTransferStatus { draft, inTransit, received, cancelled }

enum EdenStoreTransferStep {
  selectLocations,
  selectItems,
  shipping,
  confirmDispatch,
  receive,
}

@immutable
class EdenStoreTransfer {
  const EdenStoreTransfer({
    required this.id,
    required this.sourceLocation,
    required this.destLocation,
    required this.items,
    required this.status,
    this.shippingCarrier,
    this.trackingRef,
    this.isWalkIn = false,
    this.dispatchedAt,
    this.receivedAt,
  });

  final String id;
  final EdenLocation sourceLocation;
  final EdenLocation destLocation;
  final List<EdenStoreTransferItem> items;
  final EdenStoreTransferStatus status;
  final String? shippingCarrier;
  final String? trackingRef;
  final bool isWalkIn;
  final DateTime? dispatchedAt;
  final DateTime? receivedAt;
}

@immutable
class EdenStoreTransferDraft {
  const EdenStoreTransferDraft({
    this.transferId,
    required this.sourceLocationId,
    required this.destLocationId,
    required this.items,
    required this.status,
    this.shippingCarrier,
    this.trackingRef,
    this.isWalkIn = false,
    this.perLineVariance = const {},
  });

  final String? transferId;
  final String sourceLocationId;
  final String destLocationId;
  final List<EdenStoreTransferItem> items;
  final EdenStoreTransferStatus status;
  final String? shippingCarrier;
  final String? trackingRef;
  final bool isWalkIn;
  final Map<String, EdenVarianceReason> perLineVariance;
}

// ─────────────────────────────────────────────────────────────────────────
// Library-private top-level helpers
// ─────────────────────────────────────────────────────────────────────────

bool edenStoreTransferIsValidLocationPair(
  EdenLocation? src,
  EdenLocation? dst,
) {
  if (src == null || dst == null) return false;
  return src.id != dst.id;
}

String _varianceReasonLabel(EdenVarianceReason r) {
  switch (r) {
    case EdenVarianceReason.damaged:
      return 'Damaged';
    case EdenVarianceReason.shortQty:
      return 'Short qty';
    case EdenVarianceReason.overShipped:
      return 'Over-shipped';
    case EdenVarianceReason.wrongItem:
      return 'Wrong item';
    case EdenVarianceReason.unopened:
      return 'Unopened';
    case EdenVarianceReason.other:
      return 'Other';
  }
}

String _stepLabel(EdenStoreTransferStep s) {
  switch (s) {
    case EdenStoreTransferStep.selectLocations:
      return 'Select locations';
    case EdenStoreTransferStep.selectItems:
      return 'Select items';
    case EdenStoreTransferStep.shipping:
      return 'Shipping';
    case EdenStoreTransferStep.confirmDispatch:
      return 'Confirm dispatch';
    case EdenStoreTransferStep.receive:
      return 'Receive';
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Widget
// ─────────────────────────────────────────────────────────────────────────

enum _EdenStoreTransferMode { dispatch, receive }

class EdenStoreTransferFlow extends StatefulWidget {
  const EdenStoreTransferFlow.dispatch({
    super.key,
    required this.availableLocations,
    required this.onSubmit,
    this.onItemLookup,
    this.transferId,
  })  : mode = _EdenStoreTransferMode.dispatch,
        initialTransfer = null;

  const EdenStoreTransferFlow.receive({
    super.key,
    required EdenStoreTransfer this.initialTransfer,
    required this.onSubmit,
  })  : mode = _EdenStoreTransferMode.receive,
        availableLocations = const [],
        onItemLookup = null,
        transferId = null;

  // ignore: library_private_types_in_public_api
  final _EdenStoreTransferMode mode;
  final List<EdenLocation> availableLocations;
  final EdenStoreTransfer? initialTransfer;
  final void Function(EdenStoreTransferDraft draft) onSubmit;
  final Future<EdenStoreTransferItem?> Function(String barcodeOrSku)?
      onItemLookup;
  final String? transferId;

  @override
  State<EdenStoreTransferFlow> createState() => _EdenStoreTransferFlowState();
}

class _EdenStoreTransferFlowState extends State<EdenStoreTransferFlow> {
  // Dispatch-mode state.
  EdenStoreTransferStep _step = EdenStoreTransferStep.selectLocations;
  EdenLocation? _source;
  EdenLocation? _dest;
  final List<EdenStoreTransferItem> _items = [];
  String _scanQuery = '';
  bool _lookupNotFound = false;
  bool _looking = false;
  String _carrier = '';
  String _tracking = '';
  bool _isWalkIn = false;
  late TextEditingController _carrierController;
  late TextEditingController _trackingController;

  // Receive-mode state.
  late Map<String, EdenStoreTransferItem> _received;
  late Map<String, TextEditingController> _receivedQtyControllers;

  @override
  void initState() {
    super.initState();
    _carrierController = TextEditingController();
    _trackingController = TextEditingController();
    _received = {};
    _receivedQtyControllers = {};
    if (widget.mode == _EdenStoreTransferMode.receive) {
      _step = EdenStoreTransferStep.receive;
      final t = widget.initialTransfer!;
      for (final i in t.items) {
        _received[i.lineId] = i.copyWith(receivedQty: i.qty);
        _receivedQtyControllers[i.lineId] =
            TextEditingController(text: i.qty.toString());
      }
    }
  }

  @override
  void dispose() {
    _carrierController.dispose();
    _trackingController.dispose();
    for (final c in _receivedQtyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _locationPairValid =>
      edenStoreTransferIsValidLocationPair(_source, _dest);

  Widget _stepIndicator() {
    final theme = Theme.of(context);
    if (widget.mode == _EdenStoreTransferMode.receive) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Receive transfer ${widget.initialTransfer!.id}',
          style: theme.textTheme.titleMedium,
        ),
      );
    }
    final n = _step.index + 1; // 1..4
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        'Step $n of 4 — ${_stepLabel(_step)}',
        style: theme.textTheme.titleMedium,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mode == _EdenStoreTransferMode.receive) {
      return _buildReceive(context);
    }
    switch (_step) {
      case EdenStoreTransferStep.selectLocations:
        return _buildStep1(context);
      case EdenStoreTransferStep.selectItems:
        return _buildStep2(context);
      case EdenStoreTransferStep.shipping:
        return _buildStep3(context);
      case EdenStoreTransferStep.confirmDispatch:
        return _buildStep4(context);
      case EdenStoreTransferStep.receive:
        return _buildReceive(context);
    }
  }

  // ───── Step 1 — Select locations ─────
  Widget _buildStep1(BuildContext context) {
    final locOptions = [
      for (final l in widget.availableLocations)
        EdenSelectOption<EdenLocation>(
          value: l,
          label: l.effectiveLabel,
        ),
    ];
    return Padding(
      padding: const EdgeInsets.all(EdenSpacing.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepIndicator(),
          EdenSelect<EdenLocation>(
            label: 'Source',
            value: _source,
            options: locOptions,
            onChanged: (v) => setState(() => _source = v),
          ),
          const SizedBox(height: 12),
          EdenSelect<EdenLocation>(
            label: 'Destination',
            value: _dest,
            options: locOptions,
            onChanged: (v) => setState(() => _dest = v),
          ),
          if (_source != null &&
              _dest != null &&
              _source!.id == _dest!.id)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: EdenAlert(
                variant: EdenAlertVariant.warning,
                message: 'Source and destination must differ.',
              ),
            ),
          const Spacer(),
          _stepNav(canNext: _locationPairValid),
        ],
      ),
    );
  }

  // ───── Step 2 — Select items ─────
  Widget _buildStep2(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(EdenSpacing.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepIndicator(),
          Row(
            children: [
              Expanded(
                child: EdenSearchInput(
                  hint: 'Scan or enter SKU / barcode',
                  onChanged: (v) => setState(() {
                    _scanQuery = v;
                    _lookupNotFound = false;
                  }),
                  onSubmitted: (_) => _doScan(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: (_scanQuery.trim().isEmpty || _looking)
                    ? null
                    : _doScan,
                child: const Text('Scan'),
              ),
            ],
          ),
          if (_lookupNotFound)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: EdenAlert(
                variant: EdenAlertVariant.warning,
                message: 'Item not found for that SKU / barcode.',
              ),
            ),
          const SizedBox(height: 12),
          Expanded(
            child: _items.isEmpty
                ? const Center(
                    child: Text('No items yet. Scan or add items above.'),
                  )
                : ListView(
                    children: [
                      for (final i in _items)
                        ListTile(
                          dense: true,
                          title: Text('${i.sku} — ${i.name}'),
                          subtitle: Text('${i.qty} ${i.unitLabel}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => setState(
                              () => _items
                                  .removeWhere((x) => x.lineId == i.lineId),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          Text('${_items.length} item(s)'),
          const SizedBox(height: 8),
          _stepNav(canNext: _items.isNotEmpty),
        ],
      ),
    );
  }

  Future<void> _doScan() async {
    final cb = widget.onItemLookup;
    if (cb == null) {
      // No lookup wired; create a synthetic line so the widget remains
      // usable in demos without backend.
      setState(() {
        _items.add(EdenStoreTransferItem(
          lineId: 'manual-${_items.length + 1}',
          sku: _scanQuery,
          name: _scanQuery,
          qty: 1,
        ));
        _scanQuery = '';
      });
      return;
    }
    setState(() {
      _looking = true;
      _lookupNotFound = false;
    });
    EdenStoreTransferItem? res;
    try {
      res = await cb(_scanQuery);
    } catch (_) {
      res = null;
    }
    if (!mounted) return;
    setState(() {
      _looking = false;
      if (res == null) {
        _lookupNotFound = true;
      } else {
        // De-dup by SKU: if SKU already in cart, bump qty.
        final existingIdx =
            _items.indexWhere((i) => i.sku == res!.sku);
        if (existingIdx >= 0) {
          _items[existingIdx] = _items[existingIdx]
              .copyWith(qty: _items[existingIdx].qty + res.qty);
        } else {
          _items.add(res);
        }
        _scanQuery = '';
      }
    });
  }

  // ───── Step 3 — Shipping ─────
  Widget _buildStep3(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(EdenSpacing.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepIndicator(),
          CheckboxListTile(
            title: const Text('Walk-in transfer (no carrier)'),
            value: _isWalkIn,
            onChanged: (v) {
              setState(() {
                _isWalkIn = v ?? false;
                if (_isWalkIn) {
                  _carrierController.clear();
                  _trackingController.clear();
                  _carrier = '';
                  _tracking = '';
                }
              });
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            key: const ValueKey('shippingCarrier'),
            width: 280,
            child: TextField(
              controller: _carrierController,
              enabled: !_isWalkIn,
              decoration: const InputDecoration(
                labelText: 'Shipping carrier',
              ),
              onChanged: (v) => setState(() => _carrier = v),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 280,
            child: TextField(
              controller: _trackingController,
              enabled: !_isWalkIn,
              decoration: const InputDecoration(
                labelText: 'Tracking #',
              ),
              onChanged: (v) => setState(() => _tracking = v),
            ),
          ),
          const Spacer(),
          _stepNav(canNext: true),
        ],
      ),
    );
  }

  // ───── Step 4 — Confirm dispatch ─────
  Widget _buildStep4(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(EdenSpacing.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepIndicator(),
          Text(
            '${_source!.effectiveLabel} → ${_dest!.effectiveLabel}',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text('${_items.length} item(s)'),
          const SizedBox(height: 8),
          if (_isWalkIn)
            const Text('Walk-in transfer (no carrier)')
          else if (_carrier.isNotEmpty || _tracking.isNotEmpty)
            Text(
              [
                if (_carrier.isNotEmpty) 'Carrier: $_carrier',
                if (_tracking.isNotEmpty) 'Tracking: $_tracking',
              ].join(' · '),
            ),
          const Spacer(),
          Row(
            children: [
              OutlinedButton(
                onPressed: () => setState(
                  () => _step = EdenStoreTransferStep.shipping,
                ),
                child: const Text('Back'),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _submitDispatch,
                child: const Text('Confirm dispatch'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _submitDispatch() {
    widget.onSubmit(EdenStoreTransferDraft(
      transferId: widget.transferId,
      sourceLocationId: _source!.id,
      destLocationId: _dest!.id,
      items: List<EdenStoreTransferItem>.from(_items),
      status: EdenStoreTransferStatus.inTransit,
      shippingCarrier: _isWalkIn ? null : (_carrier.isEmpty ? null : _carrier),
      trackingRef: _isWalkIn ? null : (_tracking.isEmpty ? null : _tracking),
      isWalkIn: _isWalkIn,
    ));
  }

  Widget _stepNav({required bool canNext}) {
    final firstStep = _step == EdenStoreTransferStep.selectLocations;
    return Row(
      children: [
        if (!firstStep)
          OutlinedButton(
            onPressed: () => setState(() {
              final i = _step.index;
              if (i > 0) {
                _step = EdenStoreTransferStep.values[i - 1];
              }
            }),
            child: const Text('Back'),
          ),
        const Spacer(),
        ElevatedButton(
          onPressed: canNext
              ? () => setState(() {
                    final i = _step.index;
                    _step = EdenStoreTransferStep.values[i + 1];
                  })
              : null,
          child: const Text('Next'),
        ),
      ],
    );
  }

  // ───── Receive ─────
  Widget _buildReceive(BuildContext context) {
    final theme = Theme.of(context);
    final t = widget.initialTransfer!;
    final varianceOptions = [
      for (final r in EdenVarianceReason.values)
        EdenSelectOption<EdenVarianceReason>(
          value: r,
          label: _varianceReasonLabel(r),
        ),
    ];
    return Padding(
      padding: const EdgeInsets.all(EdenSpacing.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepIndicator(),
          Text(
            'From ${t.sourceLocation.effectiveLabel} → ${t.destLocation.effectiveLabel}',
            style: theme.textTheme.bodyMedium,
          ),
          if (t.dispatchedAt != null)
            Text(
              'Dispatched ${t.dispatchedAt}',
              style: theme.textTheme.bodySmall,
            ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: [
                for (final item in t.items)
                  _ReceiveRow(
                    item: item,
                    received: _received[item.lineId]!,
                    qtyController: _receivedQtyControllers[item.lineId]!,
                    varianceOptions: varianceOptions,
                    onReceivedQtyChanged: (qty) {
                      setState(() {
                        final mismatch = qty != item.qty;
                        _received[item.lineId] = _received[item.lineId]!
                            .copyWith(
                          receivedQty: qty,
                          clearVariance: !mismatch,
                        );
                      });
                    },
                    onVarianceChanged: (r) {
                      setState(() {
                        _received[item.lineId] =
                            _received[item.lineId]!.copyWith(varianceReason: r);
                      });
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _submitReceive,
              child: const Text('Confirm receive'),
            ),
          ),
        ],
      ),
    );
  }

  void _submitReceive() {
    final t = widget.initialTransfer!;
    final variance = <String, EdenVarianceReason>{
      for (final e in _received.entries)
        if (e.value.varianceReason != null) e.key: e.value.varianceReason!,
    };
    widget.onSubmit(EdenStoreTransferDraft(
      transferId: t.id,
      sourceLocationId: t.sourceLocation.id,
      destLocationId: t.destLocation.id,
      items: _received.values.toList(),
      status: EdenStoreTransferStatus.received,
      shippingCarrier: t.shippingCarrier,
      trackingRef: t.trackingRef,
      isWalkIn: t.isWalkIn,
      perLineVariance: variance,
    ));
  }
}

class _ReceiveRow extends StatelessWidget {
  const _ReceiveRow({
    required this.item,
    required this.received,
    required this.qtyController,
    required this.varianceOptions,
    required this.onReceivedQtyChanged,
    required this.onVarianceChanged,
  });

  final EdenStoreTransferItem item;
  final EdenStoreTransferItem received;
  final TextEditingController qtyController;
  final List<EdenSelectOption<EdenVarianceReason>> varianceOptions;
  final ValueChanged<num> onReceivedQtyChanged;
  final ValueChanged<EdenVarianceReason> onVarianceChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mismatch =
        received.receivedQty != null && received.receivedQty != item.qty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${item.sku} — ${item.name}',
              style: theme.textTheme.bodyMedium),
          Text(
            'Expected: ${item.qty} ${item.unitLabel}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 120,
                child: TextField(
                  key: ValueKey('receivedQty-${item.lineId}'),
                  controller: qtyController,
                  decoration: const InputDecoration(
                    labelText: 'Received',
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    final parsed = num.tryParse(v);
                    if (parsed != null) onReceivedQtyChanged(parsed);
                  },
                ),
              ),
              if (mismatch)
                SizedBox(
                  width: 220,
                  child: EdenSelect<EdenVarianceReason>(
                    label: 'Variance reason',
                    value: received.varianceReason,
                    options: varianceOptions,
                    onChanged: (r) {
                      if (r != null) onVarianceChanged(r);
                    },
                  ),
                ),
            ],
          ),
          const Divider(height: 24),
        ],
      ),
    );
  }
}

// EdenInput is imported for parity with the design TRD even though
// the implementation uses raw TextFields for tighter control.
// ignore: unused_element
typedef _EdenInput = EdenInput;
