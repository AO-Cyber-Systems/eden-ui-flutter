import 'package:flutter/material.dart';

import '../../tokens/radii.dart';
import '../../tokens/spacing.dart';
import '../../tokens/typography.dart';
import 'agent_intent_data.dart';

/// The action id a `list/customers` payload uses to grant row tapping.
///
/// FIXTURE: `intent.actions[0].id` in eden-biz testdata 11 — `open`, bound to
/// `tool_id: get_customer_history`. The id is matched, the tool id is NOT
/// interpreted here: the renderer hands both back and the caller invokes.
const String kEdenCustomerOpenActionId = 'open';

/// Called when the user fires an [EdenIntentAction] against one customer.
///
/// BOTH HALVES ARE NEEDED AND THE PAYLOAD ONLY CARRIES ONE. `intent.actions`
/// is COMPONENT-level — one `open` for the whole list, with no per-row
/// binding — so the row the user pressed is the other half of the invocation
/// and it comes from here, not from the payload. The caller invokes
/// `action.toolId` with `customer.id`.
typedef EdenCustomerActionCallback = void Function(
  EdenIntentAction action,
  EdenCustomerSummary customer,
);

/// Renders a `list/customers` intent.
///
/// AFFORDANCES ARE GRANTED BY THE PAYLOAD, the same rule
/// [EdenAppointmentList] states. A row is tappable only when [actions]
/// contains an action whose id is [kEdenCustomerOpenActionId]. Hand it an
/// empty [actions] list and it renders a read-only list with no tap targets
/// at all — which is correct, not degraded: the agent's payload is what
/// decides whether this caller may open a customer, and a renderer that
/// offered the control anyway would be inventing an authorization the
/// observation did not grant.
///
/// THE RENDERER NEVER FETCHES. Everything drawn comes from [data], which is
/// built server-side from an authorized tool observation and typed by that
/// tool's `OutputSchema`. There is no repository here, no provider, no
/// future — hand it data or hand it nothing.
///
/// DUAL USE. This takes typed Dart data, not the intent envelope, so a
/// purpose-built companion experience can compose it directly with its own
/// `EdenCustomerListData`; the agent path differs only in who builds that
/// object. Nothing about the widget knows which caller it has.
///
/// ## Empty is a real answer
///
/// `customers: []` renders a stated empty result, never a blank region. A
/// card that renders nothing is indistinguishable from a card that failed to
/// render, which is the one outcome both sides of this contract agreed must
/// never happen. A genuine failure is a different component entirely
/// (`error/refusal`, [EdenRefusal]) and carries a reason.
class EdenCustomerList extends StatelessWidget {
  const EdenCustomerList({
    super.key,
    required this.data,
    this.actions = const <EdenIntentAction>[],
    this.onAction,
  });

  /// The `component_id` this widget renders.
  ///
  /// Exposed as a static so `kDataDisplayComponents` can pair the id with the
  /// widget without a re-typed string literal, and so the manifest's closed
  /// partition can see it. See `eden_data_display_exports.dart`.
  static const String componentId = 'list/customers';

  /// The payload's `intent.data`.
  final EdenCustomerListData data;

  /// The payload's `intent.actions`. Empty means read-only.
  final List<EdenIntentAction> actions;

  /// Fired with the action AND the row it was pressed on. Required for the
  /// rows to be tappable at all — an `open` action with no callback would be
  /// an affordance that does nothing.
  final EdenCustomerActionCallback? onAction;

  /// The `open` action, if the payload granted one.
  EdenIntentAction? get _openAction {
    for (final EdenIntentAction action in actions) {
      if (action.id == kEdenCustomerOpenActionId) return action;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EdenIntentAction? open = _openAction;
    final bool tappable = open != null && onAction != null;

    if (data.customers.isEmpty) {
      return const _EmptyResult(
          key: ValueKey<String>('eden-customers-empty'));
    }

    return Column(
      key: const ValueKey<String>('eden-customer-list'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final EdenCustomerSummary customer in data.customers)
          _CustomerRow(
            key: ValueKey<String>('eden-customer-row-${customer.id}'),
            customer: customer,
            // The ROW decides nothing about authorization; it is handed the
            // action or nothing, and renders a tap target only in the first
            // case.
            onTap: tappable
                ? () => onAction!(open, customer)
                : null,
            theme: theme,
          ),
      ],
    );
  }
}

/// One customer row: name, and the tool's masked email hint beneath it.
class _CustomerRow extends StatelessWidget {
  const _CustomerRow({
    super.key,
    required this.customer,
    required this.onTap,
    required this.theme,
  });

  final EdenCustomerSummary customer;
  final VoidCallback? onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    // 48 MINIMUM, not 44. This component ships to the biz portal (pointer)
    // AND to the companion app (touch), and `expectUiSane` holds a touch
    // surface to 48dp — so the stricter of the two floors is the one the row
    // is built to, rather than being correct on one surface and reported on
    // the other.
    final Widget content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space3,
        vertical: EdenSpacing.space2,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  customer.name,
                  style: EdenTypography.bodyMedium(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                // `space1` (4), not a tighter hand-picked 2: the sibling
                // `eden_appointment_list.dart` sets exactly this label/value
                // pair at `space1`, and the design rule refuses an
                // `// ignore:` precisely because an exempted magic number is
                // indistinguishable from real debt.
                const SizedBox(height: EdenSpacing.space1),
                Text(
                  // DISPLAYED AS GIVEN. The tool already masked this; see
                  // EdenCustomerSummary.emailHint. No unmasking, no mailto,
                  // no "invalid email" styling — it is not meant to be one.
                  customer.emailHint,
                  key: const ValueKey<String>('eden-customer-email-hint'),
                  style: EdenTypography.bodySmall(context).copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onTap != null)
            Icon(
              Icons.chevron_right,
              size: 20,
              // onSurfaceVariant, not the brand: a chevron is a direction
              // cue, not a selection state, and eden-ui-flutter#55/#58 are
              // the record of what happens when a brand hue carries meaning
              // as a glyph on a light surface (2.05:1).
              color: theme.colorScheme.onSurfaceVariant,
            ),
        ],
      ),
    );

    final Widget sized = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: content,
    );

    if (onTap == null) return sized;

    return InkWell(
      onTap: onTap,
      borderRadius: EdenRadii.borderRadiusMd,
      child: sized,
    );
  }
}

/// The stated empty result.
///
/// A SENTENCE, not an empty box. `customers: []` is an answer the tool gave,
/// and the user needs to be able to tell it apart from a card that failed to
/// draw. It carries no retry and no action: nothing the user could press
/// would change a search that genuinely matched nobody — the same one-sided
/// reasoning [EdenRefusal] is built on, for a different reason.
class _EmptyResult extends StatelessWidget {
  const _EmptyResult({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space3,
        vertical: EdenSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: EdenRadii.borderRadiusMd,
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        'No customers matched.',
        style: EdenTypography.bodyMedium(context).copyWith(
          // onSurfaceVariant on surfaceContainerLow — #52525B on #FAFAFA is
          // 7.41:1 light, and the dark pair clears the floor too. Measured,
          // because an empty state that is hard to read is the same defect
          // as no empty state.
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
