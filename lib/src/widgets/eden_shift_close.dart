import 'dart:async';

import 'package:flutter/material.dart';

import '../tokens/spacing.dart';
import 'eden_banner.dart';
import 'eden_button.dart';
import 'eden_cash_drawer_close.dart';
import 'eden_xz_report.dart';

/// Steps in the end-of-shift wizard.
enum EdenShiftCloseStep { drawerClose, reportPreview, printOrEmail, confirm }

/// Distribution channels for the X/Z report.
enum EdenShiftCloseDistribution { thermalPrint, email, sms }

/// Result emitted on shift close.
@immutable
class EdenShiftCloseResult {
  const EdenShiftCloseResult({
    required this.drawerCloseResult,
    required this.reportSnapshot,
    required this.distributedTo,
  });

  final EdenCashDrawerCloseResult drawerCloseResult;
  final EdenShiftReport reportSnapshot;
  final Set<EdenShiftCloseDistribution> distributedTo;
}

/// Composite end-of-shift wizard (obj 015-07).
class EdenShiftClose extends StatefulWidget {
  const EdenShiftClose({
    super.key,
    required this.initialSession,
    required this.reportSnapshot,
    required this.onSessionChanged,
    required this.onCompleted,
    this.onDistribute,
    this.denominations = EdenDenominations.usd,
    this.currencyCode = 'USD',
    this.allowDeposit = true,
    this.varianceManagerOverrideMessage,
  });

  final EdenDrawerSession initialSession;
  final EdenShiftReport reportSnapshot;
  final ValueChanged<EdenDrawerSession> onSessionChanged;
  final ValueChanged<EdenShiftCloseResult> onCompleted;
  final FutureOr<void> Function(
      EdenShiftReport report, EdenShiftCloseDistribution channel)? onDistribute;
  final List<EdenDenomination> denominations;
  final String currencyCode;
  final bool allowDeposit;
  final String? varianceManagerOverrideMessage;

  @override
  State<EdenShiftClose> createState() => _EdenShiftCloseState();
}

class _EdenShiftCloseState extends State<EdenShiftClose> {
  EdenShiftCloseStep _step = EdenShiftCloseStep.drawerClose;
  EdenCashDrawerCloseResult? _drawerCloseResult;
  final Set<EdenShiftCloseDistribution> _distributedTo = {};
  bool _distributing = false;

  void _advance(EdenShiftCloseStep next) {
    setState(() => _step = next);
  }

  Future<void> _distribute(EdenShiftCloseDistribution channel) async {
    if (widget.onDistribute == null) return;
    setState(() => _distributing = true);
    await widget.onDistribute!(widget.reportSnapshot, channel);
    if (!mounted) return;
    setState(() {
      _distributing = false;
      _distributedTo.add(channel);
    });
  }

  void _confirmClose() {
    if (_drawerCloseResult == null) return;
    widget.onCompleted(EdenShiftCloseResult(
      drawerCloseResult: _drawerCloseResult!,
      reportSnapshot: widget.reportSnapshot,
      distributedTo: Set.unmodifiable(_distributedTo),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(),
        const SizedBox(height: EdenSpacing.space3),
        _buildBody(),
      ],
    );
  }

  Widget _buildStepHeader() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final s in EdenShiftCloseStep.values)
          ChoiceChip(
            label: Text(s.name),
            selected: _step == s,
            onSelected: (_) => setState(() => _step = s),
          ),
      ],
    );
  }

  Widget _buildBody() {
    switch (_step) {
      case EdenShiftCloseStep.drawerClose:
        return EdenCashDrawerClose(
          initialSession: widget.initialSession,
          onSessionChanged: widget.onSessionChanged,
          onSubmit: (result) {
            setState(() {
              _drawerCloseResult = result;
              _step = EdenShiftCloseStep.reportPreview;
            });
          },
          denominations: widget.denominations,
          allowDeposit: widget.allowDeposit,
          currencyCode: widget.currencyCode,
          varianceManagerOverrideMessage:
              widget.varianceManagerOverrideMessage,
        );
      case EdenShiftCloseStep.reportPreview:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EdenXZReport(
              report: widget.reportSnapshot,
              currencyCode: widget.currencyCode,
            ),
            const SizedBox(height: 16),
            EdenButton(
              label: 'Continue',
              onPressed: () => _advance(EdenShiftCloseStep.printOrEmail),
            ),
          ],
        );
      case EdenShiftCloseStep.printOrEmail:
        final disabled = widget.onDistribute == null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Distribute report (optional)',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Semantics(
                  label:
                      'Print thermal — ${_distributedTo.contains(EdenShiftCloseDistribution.thermalPrint) ? "distributed" : "not yet"}',
                  container: true,
                  excludeSemantics: true,
                  child: EdenButton(
                    label: 'Print thermal',
                    variant: EdenButtonVariant.secondary,
                    outline: true,
                    onPressed: disabled || _distributing
                        ? null
                        : () => _distribute(
                            EdenShiftCloseDistribution.thermalPrint),
                  ),
                ),
                Semantics(
                  label:
                      'Email — ${_distributedTo.contains(EdenShiftCloseDistribution.email) ? "distributed" : "not yet"}',
                  container: true,
                  excludeSemantics: true,
                  child: EdenButton(
                    label: 'Email',
                    variant: EdenButtonVariant.secondary,
                    outline: true,
                    onPressed: disabled || _distributing
                        ? null
                        : () => _distribute(EdenShiftCloseDistribution.email),
                  ),
                ),
                Semantics(
                  label:
                      'SMS — ${_distributedTo.contains(EdenShiftCloseDistribution.sms) ? "distributed" : "not yet"}',
                  container: true,
                  excludeSemantics: true,
                  child: EdenButton(
                    label: 'SMS',
                    variant: EdenButtonVariant.secondary,
                    outline: true,
                    onPressed: disabled || _distributing
                        ? null
                        : () => _distribute(EdenShiftCloseDistribution.sms),
                  ),
                ),
              ],
            ),
            if (_distributedTo.isNotEmpty) ...[
              const SizedBox(height: 8),
              EdenBanner(
                message:
                    'Distributed: ${_distributedTo.map((c) => c.name).join(", ")}',
                variant: EdenBannerVariant.success,
                dismissible: false,
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                EdenButton(
                  label: 'Continue',
                  onPressed: () => _advance(EdenShiftCloseStep.confirm),
                ),
                EdenButton(
                  label: 'Skip distribution',
                  variant: EdenButtonVariant.secondary,
                  outline: true,
                  onPressed: () => _advance(EdenShiftCloseStep.confirm),
                ),
              ],
            ),
          ],
        );
      case EdenShiftCloseStep.confirm:
        final variance = _drawerCloseResult?.finalSession.computedVariance;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Confirm shift close',
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            Text(_drawerCloseResult == null
                ? 'Drawer close: incomplete'
                : 'Drawer close: OK'),
            if (variance != null)
              Text('Variance: \$${variance.toStringAsFixed(2)}'),
            Text(_distributedTo.isEmpty
                ? 'Distributed to: none'
                : 'Distributed to: ${_distributedTo.map((c) => c.name).join(", ")}'),
            Text(_drawerCloseResult?.deposit == null
                ? 'Cash deposit: no'
                : 'Cash deposit: yes'),
            const SizedBox(height: 12),
            EdenButton(
              label: 'Confirm shift close',
              variant: EdenButtonVariant.primary,
              onPressed: _drawerCloseResult == null ? null : _confirmClose,
            ),
          ],
        );
    }
  }
}
