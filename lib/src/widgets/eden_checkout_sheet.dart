import 'package:flutter/material.dart';

import '../tokens/spacing.dart';
import 'eden_banner.dart';
import 'eden_button.dart';
import 'eden_currency_display.dart';
import 'eden_line_item_editor.dart';
import 'eden_payment_entry.dart';
import 'eden_promotion_apply.dart';
import 'eden_promotion_author.dart';
import 'eden_split_tender.dart';
import 'eden_stepper.dart';
import 'eden_tipping_selector.dart';

/// Steps in the chair-side checkout flow.
enum EdenCheckoutStep { lineItems, tip, payment, review }

/// Working checkout state. Library produces drafts; consumer wires
/// actual payment processing + persistence.
@immutable
class EdenCheckoutDraft {
  const EdenCheckoutDraft({
    required this.lineItems,
    required this.tip,
    required this.payments,
    required this.currentStep,
    this.appliedPromotion,
    this.taxRate = 0.0,
  });

  final List<EdenLineItem<dynamic>> lineItems;
  final EdenTipDraft tip;
  final List<EdenPaymentDraft> payments;
  final EdenCheckoutStep currentStep;
  final EdenPromotionApplyResult? appliedPromotion;

  /// Tax fraction — applied AFTER discount per locked v1 decision.
  final double taxRate;

  double get subtotal =>
      lineItems.fold<double>(0, (acc, it) => acc + it.lineTotal);

  double get discount => appliedPromotion?.discountAmount ?? 0;

  double get taxAmount => (subtotal - discount) * taxRate;

  double get total => subtotal - discount + tip.tipAmount + taxAmount;

  double get tendered =>
      payments.fold<double>(0, (acc, p) => acc + p.amount);

  double get balance => total - tendered;

  EdenCheckoutDraft copyWith({
    List<EdenLineItem<dynamic>>? lineItems,
    EdenTipDraft? tip,
    List<EdenPaymentDraft>? payments,
    EdenCheckoutStep? currentStep,
    EdenPromotionApplyResult? appliedPromotion,
    double? taxRate,
    bool clearAppliedPromotion = false,
  }) {
    return EdenCheckoutDraft(
      lineItems: lineItems ?? this.lineItems,
      tip: tip ?? this.tip,
      payments: payments ?? this.payments,
      currentStep: currentStep ?? this.currentStep,
      appliedPromotion: clearAppliedPromotion
          ? null
          : (appliedPromotion ?? this.appliedPromotion),
      taxRate: taxRate ?? this.taxRate,
    );
  }
}

/// Chair-side checkout composite (obj 015-02).
///
/// 4-step wizard (lineItems → tip → payment → review). The widget IS
/// the sheet BODY; consumer wraps in `showModalBottomSheet`.
class EdenCheckoutSheet extends StatefulWidget {
  const EdenCheckoutSheet({
    super.key,
    required this.initialDraft,
    required this.onDraftChanged,
    required this.onComplete,
    this.availablePromotions = const <EdenPromotionRule>[],
    this.promotionContext,
    this.allowedPaymentMethods = const [
      EdenPaymentMethod.cash,
      EdenPaymentMethod.card,
      EdenPaymentMethod.giftCard,
    ],
    this.tipPresets = EdenTipPresets.salonStandard,
    this.allowSkipTip = true,
    this.allowSkipPromotion = true,
    this.currencyCode = 'USD',
  });

  final EdenCheckoutDraft initialDraft;
  final ValueChanged<EdenCheckoutDraft> onDraftChanged;
  final ValueChanged<EdenCheckoutDraft> onComplete;
  final List<EdenPromotionRule> availablePromotions;
  final EdenPromotionApplyContext? promotionContext;
  final List<EdenPaymentMethod> allowedPaymentMethods;
  final List<EdenTipPreset> tipPresets;
  final bool allowSkipTip;
  final bool allowSkipPromotion;
  final String currencyCode;

  @override
  State<EdenCheckoutSheet> createState() => _EdenCheckoutSheetState();
}

class _EdenCheckoutSheetState extends State<EdenCheckoutSheet> {
  late EdenCheckoutDraft _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialDraft;
  }

  void _emit(EdenCheckoutDraft d) {
    setState(() {
      _draft = d;
    });
    widget.onDraftChanged(d);
  }

  void _continue() {
    final next = _nextStep(_draft.currentStep);
    if (next == null) return;
    _emit(_draft.copyWith(currentStep: next));
  }

  void _back() {
    final prev = _prevStep(_draft.currentStep);
    if (prev == null) return;
    _emit(_draft.copyWith(currentStep: prev));
  }

  EdenCheckoutStep? _nextStep(EdenCheckoutStep s) {
    switch (s) {
      case EdenCheckoutStep.lineItems:
        return EdenCheckoutStep.tip;
      case EdenCheckoutStep.tip:
        return EdenCheckoutStep.payment;
      case EdenCheckoutStep.payment:
        return EdenCheckoutStep.review;
      case EdenCheckoutStep.review:
        return null;
    }
  }

  EdenCheckoutStep? _prevStep(EdenCheckoutStep s) {
    switch (s) {
      case EdenCheckoutStep.lineItems:
        return null;
      case EdenCheckoutStep.tip:
        return EdenCheckoutStep.lineItems;
      case EdenCheckoutStep.payment:
        return EdenCheckoutStep.tip;
      case EdenCheckoutStep.review:
        return EdenCheckoutStep.payment;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 500;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepHeader(compact),
          const SizedBox(height: EdenSpacing.space2),
          Flexible(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(EdenSpacing.space2),
                child: _buildBody(),
              ),
            ),
          ),
          const SizedBox(height: EdenSpacing.space2),
          _buildNavRow(),
        ],
      );
    });
  }

  Widget _buildStepHeader(bool compact) {
    final stepIndex = _draft.currentStep.index;
    final stepItems = <EdenStepItem>[
      for (var i = 0; i < EdenCheckoutStep.values.length; i++)
        EdenStepItem(
          label: EdenCheckoutStep.values[i].name,
          status: i < stepIndex
              ? EdenStepStatus.complete
              : (i == stepIndex
                  ? EdenStepStatus.current
                  : EdenStepStatus.upcoming),
        ),
    ];
    if (compact) {
      // Compact dot variant: just the names without the connector.
      return Wrap(
        spacing: 8,
        children: [
          for (var i = 0; i < stepItems.length; i++)
            Chip(
              label: Text(stepItems[i].label,
                  style: TextStyle(
                    fontWeight: i == stepIndex
                        ? FontWeight.w700
                        : FontWeight.w400,
                  )),
              backgroundColor: i == stepIndex
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
                  : null,
            ),
        ],
      );
    }
    return EdenStepper(steps: stepItems);
  }

  Widget _buildBody() {
    return Semantics(
      liveRegion: true,
      child: Builder(builder: (context) {
        switch (_draft.currentStep) {
          case EdenCheckoutStep.lineItems:
            return _LineItemsStep(
              draft: _draft,
              onChanged: _emit,
            );
          case EdenCheckoutStep.tip:
            return _TipStep(
              draft: _draft,
              presets: widget.tipPresets,
              currencyCode: widget.currencyCode,
              onChanged: _emit,
              allowSkipTip: widget.allowSkipTip,
              onSkip: _continue,
            );
          case EdenCheckoutStep.payment:
            return _PaymentStep(
              draft: _draft,
              allowedMethods: widget.allowedPaymentMethods,
              currencyCode: widget.currencyCode,
              onChanged: _emit,
            );
          case EdenCheckoutStep.review:
            return _ReviewStep(
              draft: _draft,
              currencyCode: widget.currencyCode,
              availablePromotions: widget.availablePromotions,
              promotionContext: widget.promotionContext ??
                  EdenPromotionApplyContext(
                    lineItems: _draft.lineItems,
                    subtotal: _draft.subtotal,
                    currentTime: DateTime.now(),
                  ),
              onPromotionApplied: (r) => _emit(_draft.copyWith(
                appliedPromotion: r,
                clearAppliedPromotion: r == null,
              )),
            );
        }
      }),
    );
  }

  Widget _buildNavRow() {
    final isFirst = _draft.currentStep == EdenCheckoutStep.lineItems;
    final isReview = _draft.currentStep == EdenCheckoutStep.review;
    final paymentBalanceMet =
        _draft.currentStep != EdenCheckoutStep.payment ||
            _draft.balance <= 0.01;
    final completeLabel =
        'Complete checkout, total \$${_draft.total.toStringAsFixed(2)}';
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.spaceBetween,
      children: [
        if (!isFirst)
          EdenButton(
            label: 'Back',
            variant: EdenButtonVariant.secondary,
            outline: true,
            onPressed: _back,
          )
        else
          const SizedBox.shrink(),
        if (!isReview)
          KeyedSubtree(
            key: const ValueKey('checkout-continue'),
            child: EdenButton(
              label: 'Continue',
              onPressed: paymentBalanceMet ? _continue : null,
            ),
          )
        else
          Semantics(
            label: completeLabel,
            container: true,
            excludeSemantics: true,
            child: EdenButton(
              label: 'Complete',
              onPressed: () => widget.onComplete(_draft),
            ),
          ),
      ],
    );
  }
}

class _LineItemsStep extends StatelessWidget {
  const _LineItemsStep({required this.draft, required this.onChanged});
  final EdenCheckoutDraft draft;
  final ValueChanged<EdenCheckoutDraft> onChanged;

  @override
  Widget build(BuildContext context) {
    return EdenLineItemEditor<dynamic>(
      items: draft.lineItems,
      onItemsChanged: (items) =>
          onChanged(draft.copyWith(lineItems: items)),
    );
  }
}

class _TipStep extends StatelessWidget {
  const _TipStep({
    required this.draft,
    required this.presets,
    required this.currencyCode,
    required this.onChanged,
    required this.allowSkipTip,
    required this.onSkip,
  });

  final EdenCheckoutDraft draft;
  final List<EdenTipPreset> presets;
  final String currencyCode;
  final ValueChanged<EdenCheckoutDraft> onChanged;
  final bool allowSkipTip;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        EdenTippingSelector(
          subtotal: draft.subtotal,
          presets: presets,
          currencyCode: currencyCode,
          initialDraft: draft.tip,
          onDraftChanged: (tip) => onChanged(draft.copyWith(tip: tip)),
        ),
        if (allowSkipTip) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: onSkip,
            child: const Text('Skip tip'),
          ),
        ],
      ],
    );
  }
}

class _PaymentStep extends StatelessWidget {
  const _PaymentStep({
    required this.draft,
    required this.allowedMethods,
    required this.currencyCode,
    required this.onChanged,
  });

  final EdenCheckoutDraft draft;
  final List<EdenPaymentMethod> allowedMethods;
  final String currencyCode;
  final ValueChanged<EdenCheckoutDraft> onChanged;

  @override
  Widget build(BuildContext context) {
    final remaining = draft.balance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Text('Total: ',
                style: TextStyle(fontWeight: FontWeight.w700)),
            EdenCurrencyDisplay(
              cents: (draft.total * 100).round(),
              currencyCode: currencyCode,
            ),
          ],
        ),
        const SizedBox(height: 8),
        EdenSplitTender(
          total: draft.total,
          allowedMethods: allowedMethods,
          initialDrafts: draft.payments.isEmpty ? null : draft.payments,
          currencyCode: currencyCode,
          onDraftsChanged: (payments) =>
              onChanged(draft.copyWith(payments: payments)),
        ),
        if (remaining > 0.01) ...[
          const SizedBox(height: 8),
          EdenBanner(
            message: 'Remaining: \$${remaining.toStringAsFixed(2)}',
            variant: EdenBannerVariant.warning,
            dismissible: false,
          ),
        ],
      ],
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    required this.draft,
    required this.currencyCode,
    required this.availablePromotions,
    required this.promotionContext,
    required this.onPromotionApplied,
  });

  final EdenCheckoutDraft draft;
  final String currencyCode;
  final List<EdenPromotionRule> availablePromotions;
  final EdenPromotionApplyContext promotionContext;
  final ValueChanged<EdenPromotionApplyResult?> onPromotionApplied;

  Widget _row(BuildContext context, String label, double value,
      {bool emphasis = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: emphasis ? FontWeight.w700 : FontWeight.w400)),
          EdenCurrencyDisplay(
            cents: (value * 100).round(),
            currencyCode: currencyCode,
            style: TextStyle(
                fontWeight: emphasis ? FontWeight.w700 : FontWeight.w400),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Order summary',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 4),
        for (final item in draft.lineItems)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(item.description)),
                EdenCurrencyDisplay(
                  cents: (item.lineTotal * 100).round(),
                  currencyCode: currencyCode,
                ),
              ],
            ),
          ),
        const Divider(),
        _row(context, 'Subtotal', draft.subtotal),
        if (draft.discount != 0)
          _row(context, 'Discount', -draft.discount),
        if (draft.tip.tipAmount != 0)
          _row(context, 'Tip', draft.tip.tipAmount),
        if (draft.taxAmount != 0) _row(context, 'Tax', draft.taxAmount),
        _row(context, 'Total', draft.total, emphasis: true),
        if (availablePromotions.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Apply promotion?',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          EdenPromotionApply(
            context: promotionContext,
            availableRules: availablePromotions,
            onPromotionApplied: onPromotionApplied,
            currencyCode: currencyCode,
          ),
        ],
      ],
    );
  }
}

