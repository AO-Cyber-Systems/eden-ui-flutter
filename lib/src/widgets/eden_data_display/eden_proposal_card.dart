import 'package:flutter/material.dart';

import '../../tokens/radii.dart';
import '../../tokens/spacing.dart';
import '../../tokens/typography.dart';
import '../eden_layout/nav_ink.dart';
import 'agent_intent_data.dart';

/// Called when the user decides a proposal.
///
/// The caller sends `action.proposalId` and `action.decision` back. Nothing
/// is interpreted here — the card does not know what approving does, which
/// is exactly why [EdenProposalCard.subject] exists.
typedef EdenProposalDecisionCallback = void Function(
  EdenProposalAction action,
);

/// Renders a `card/proposal` intent — a pending mutation the user may
/// approve or reject.
///
/// THIS IS THE ONLY COMPONENT SO FAR WHOSE CONTROLS MUTATE. The others
/// render observations and hand back a tool id to read more. Approving here
/// commits something. Every rule below follows from that.
///
/// ## What the payload cannot tell the user
///
/// `intent.data` carries `action_id`, `applied`, `status` and `expires_at`
/// and **nothing that says what is being proposed**. In fixture 05 the
/// proposal is `create_lead(email: jordan.lee@example.test, …)`, but that
/// lives in the fixture's `source` block — recorder metadata that does not
/// exist in a production envelope.
///
/// So a card built from the payload alone reads *"Pending approval, expires
/// 00:30. [Approve] [Reject]"* — approve **what**? The card renders
/// identically whether the proposal creates a lead or deletes a customer,
/// which makes it a consent dialog that cannot state what it is obtaining
/// consent for.
///
/// [subject] is therefore REQUIRED and undefaulted, on the same reasoning
/// as `EdenServiceList.currencyCode` but with higher stakes: a wrong
/// currency is a wrong number, a missing subject is a mutation the user did
/// not know they authorized. The agent knows it — it called the tool that
/// produced the proposal — the envelope just drops it. Filed as
/// eden-biz#863, which proposes `tool_id` + `summary` on `intent.data`.
///
/// ## What suppresses the controls, and what deliberately does not
///
/// SUPPRESSES (all payload-carried, all verifiable here):
///  * `applied == true` — already committed.
///  * `status != `[kEdenProposalPendingStatus]` — already decided.
///  * an empty [actions] list — the payload granted nothing.
///  * an action whose `decision` is empty — it binds to nothing. The Go
///    struct's `omitempty` makes `{"id": "approve"}` a legal action.
///  * an action whose `proposalId` is not [EdenProposalData.actionId] — it
///    decides a DIFFERENT proposal than the one on screen. eden-biz's
///    integrity test asserts the two match
///    (`fixtures_integrity_test.go:172`); this re-checks rather than
///    trusting, because the failure is a user approving one thing while
///    looking at another, and nothing on screen would differ.
///
/// DOES NOT SUPPRESS:
///  * [EdenProposalData.expiresAt] being in the past. The renderer has no
///    clock authority — device time is skewed, unset, or in another zone,
///    and this package never calls `toLocal()`. Hiding a live control
///    because a wrong local clock said so is worse than showing one the
///    server will reject with a reason. The expiry is rendered prominently
///    instead, so the user can see it; the server remains the authority on
///    whether it has passed.
class EdenProposalCard extends StatelessWidget {
  const EdenProposalCard({
    super.key,
    required this.data,
    required this.subject,
    this.actions = const <EdenProposalAction>[],
    this.onDecision,
  });

  /// The `component_id` this widget renders.
  static const String componentId = 'card/proposal';

  /// The payload's `intent.data`.
  final EdenProposalData data;

  /// One line naming what will happen if this is approved, e.g.
  /// `Create a lead for Jordan Lee`.
  ///
  /// REQUIRED AND UNDEFAULTED — see the class doc. There is no honest
  /// default: a generic "Approve this action?" is precisely the dialog that
  /// cannot say what it is asking about.
  final String subject;

  /// The payload's `intent.actions`, already narrowed to proposal actions by
  /// the adapter. Empty means read-only.
  final List<EdenProposalAction> actions;

  /// Fired with the action the user chose. Required for any control to
  /// render at all.
  final EdenProposalDecisionCallback? onDecision;

  /// True when the payload itself says this proposal is still open.
  bool get _open => !data.applied && data.status == kEdenProposalPendingStatus;

  /// The actions that actually bind to THIS proposal and carry a decision.
  List<EdenProposalAction> get _bindable => <EdenProposalAction>[
        for (final EdenProposalAction a in actions)
          if (a.decision.isNotEmpty && a.proposalId == data.actionId) a,
      ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<EdenProposalAction> bindable =
        _open && onDecision != null ? _bindable : const <EdenProposalAction>[];

    return Container(
      key: const ValueKey<String>('eden-proposal-card'),
      padding: const EdgeInsets.all(EdenSpacing.space4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: EdenRadii.borderRadiusMd,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            // THE SUBJECT LEADS. It is the question being asked; the status
            // and the expiry are qualifiers on it.
            subject,
            key: const ValueKey<String>('eden-proposal-subject'),
            style: EdenTypography.bodyMedium(context).copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: EdenSpacing.space2),
          Text(
            _statusLine(data),
            key: const ValueKey<String>('eden-proposal-status'),
            style: EdenTypography.bodySmall(context).copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (bindable.isNotEmpty) ...<Widget>[
            const SizedBox(height: EdenSpacing.space4),
            Row(
              children: <Widget>[
                for (final EdenProposalAction action in bindable)
                  Padding(
                    padding: const EdgeInsets.only(right: EdenSpacing.space2),
                    child: _DecisionButton(
                      key: ValueKey<String>(
                        'eden-proposal-action-${action.decision}',
                      ),
                      action: action,
                      onPressed: () => onDecision!(action),
                      theme: theme,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// `pending_approval` + an expiry -> one line the user can read.
///
/// The status string is rendered as received, not mapped to friendlier
/// copy: `status` is a free string on the wire with exactly one observed
/// value, and a lookup table would silently fall through to a blank or to
/// the wrong label the first time eden-biz emits a second value.
String _statusLine(EdenProposalData d) {
  final String when = '${_two(d.expiresAt.day)}/${_two(d.expiresAt.month)}/'
      '${d.expiresAt.year} ${_two(d.expiresAt.hour)}:'
      '${_two(d.expiresAt.minute)}';
  if (d.applied) return '${d.status} · applied · expired or expires $when';
  return '${d.status} · expires $when';
}

String _two(int v) => v.toString().padLeft(2, '0');

/// One decision control.
///
/// `approve` is filled and `reject` is outlined, and that is the ONLY place
/// the decision string changes the rendering — deliberately, because a
/// decision this component has never seen must still render as a usable,
/// clearly-labelled control rather than vanish or fall through to the
/// approve styling. An unknown decision gets the neutral outlined treatment.
class _DecisionButton extends StatelessWidget {
  const _DecisionButton({
    super.key,
    required this.action,
    required this.onPressed,
    required this.theme,
  });

  final EdenProposalAction action;
  final VoidCallback onPressed;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final bool affirmative = action.decision == 'approve';
    final Widget label = Text(
      action.decision,
      style: EdenTypography.bodyMedium(context).copyWith(
        fontWeight: FontWeight.w600,
        // NOT `onPrimary`, and this is measured rather than chosen.
        // `FilledButton` fills with `colorScheme.primary` — the brand gold
        // #D4A853 — and the LIGHT theme sets `onPrimary: Colors.white`,
        // which is 2.20:1 against it, half the WCAG 1.4.3 floor of 4.5:1.
        // `expectUiSane` measured exactly that on `card-proposal/pending`
        // the first time this card got a story.
        //
        // `edenNavOnFillInk` (neutral[900]) is 8.04:1 light and 7.61:1
        // dark on the same fill. It is the token eden-ui-flutter#58
        // created for this pairing, and its own doc already records the
        // 2.20/2.33 measurement — the analysis existed, it had simply
        // never been applied to a button.
        //
        // The theme's `onPrimary` is still wrong for every other
        // FilledButton in this package; that is eden-ui-flutter#71, not
        // something to fix quietly from inside one card.
        color: affirmative ? edenNavOnFillInk : theme.colorScheme.onSurface,
      ),
    );

    return ConstrainedBox(
      // 48, for the reason every row in this directory is 48: this ships to
      // a pointer surface AND a touch one, so the stricter floor wins. It
      // matters more here than in a list — this is the control that mutates.
      constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
      child: affirmative
          ? FilledButton(onPressed: onPressed, child: label)
          : OutlinedButton(onPressed: onPressed, child: label),
    );
  }
}
