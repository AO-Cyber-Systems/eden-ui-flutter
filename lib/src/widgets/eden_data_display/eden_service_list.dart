import 'package:flutter/material.dart';

import '../../tokens/radii.dart';
import '../../tokens/spacing.dart';
import '../../tokens/typography.dart';
import 'agent_intent_data.dart';

/// The action id a `list/services` payload uses to grant row tapping.
///
/// FIXTURE: `intent.actions[0].id` in eden-biz testdata 08 —
/// `check_availability`, bound to `tool_id: find_availability`. The id is
/// matched; the tool id is NOT interpreted here.
const String kEdenServiceCheckAvailabilityActionId = 'check_availability';

/// Called when the user fires an [EdenIntentAction] against one service.
///
/// BOTH HALVES ARE NEEDED AND THE PAYLOAD ONLY CARRIES ONE, exactly as in
/// `list/customers`: `intent.actions` is COMPONENT-level — one
/// `check_availability` for the whole catalogue, with no per-row binding —
/// so the row the user pressed is the other half of the invocation and it
/// comes from here. The caller invokes `action.toolId` with `service.id`.
typedef EdenServiceActionCallback = void Function(
  EdenIntentAction action,
  EdenServiceSummary service,
);

/// Renders a `list/services` intent.
///
/// AFFORDANCES ARE GRANTED BY THE PAYLOAD. A row is tappable only when
/// [actions] contains an action whose id is
/// [kEdenServiceCheckAvailabilityActionId]. An empty [actions] list renders
/// a read-only catalogue — correct, not degraded.
///
/// THE RENDERER NEVER FETCHES. Everything drawn comes from [data] and
/// [currencyCode]. No repository, no provider, no future.
///
/// DUAL USE. Typed Dart data, not the intent envelope, so a purpose-built
/// companion experience composes it directly; the agent path differs only in
/// who builds [EdenServiceListData].
///
/// ## Why [currencyCode] is required and undefaulted
///
/// The payload has no currency field to pair with `price_cents`
/// (eden-biz#860). A default would therefore be a guess the component makes
/// on the tenant's behalf, and **a price rendered in the wrong currency is
/// indistinguishable from one rendered in the right currency** — `$50.00` is
/// correct for a USD tenant and a silent ~1.4x error for a CAD one, with
/// nothing on screen to tell them apart. A required parameter makes the
/// caller state what it knows; there is no path that silently assumes USD.
///
/// The amount is prefixed with the ISO code (`USD 50.00`) rather than a bare
/// symbol because `$` cannot distinguish USD from CAD, AUD or NZD, and
/// choosing which dollar a tenant means is not the renderer's call.
class EdenServiceList extends StatelessWidget {
  const EdenServiceList({
    super.key,
    required this.data,
    required this.currencyCode,
    this.actions = const <EdenIntentAction>[],
    this.onAction,
  });

  /// The `component_id` this widget renders.
  static const String componentId = 'list/services';

  /// The payload's `intent.data`.
  final EdenServiceListData data;

  /// The ISO 4217 code the prices in [data] are denominated in.
  ///
  /// REQUIRED AND UNDEFAULTED — see the class doc. It is rendered verbatim,
  /// not normalised: eden-biz stores `'USD'` on ten tables and `'usd'` on
  /// `payment_intents`, and silently upper-casing here would hide that
  /// split rather than surface it.
  final String currencyCode;

  /// The payload's `intent.actions`. Empty means read-only.
  final List<EdenIntentAction> actions;

  /// Fired with the action AND the row it was pressed on. Required for the
  /// rows to be tappable at all.
  final EdenServiceActionCallback? onAction;

  /// The `check_availability` action, if the payload granted one.
  EdenIntentAction? get _checkAction {
    for (final EdenIntentAction action in actions) {
      if (action.id == kEdenServiceCheckAvailabilityActionId) return action;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EdenIntentAction? check = _checkAction;
    final bool tappable = check != null && onAction != null;

    if (data.services.isEmpty) {
      return const _EmptyCatalogue(
        key: ValueKey<String>('eden-services-empty'),
      );
    }

    return Column(
      key: const ValueKey<String>('eden-service-list'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final EdenServiceSummary service in data.services)
          _ServiceRow(
            key: ValueKey<String>('eden-service-row-${service.id}'),
            service: service,
            currencyCode: currencyCode,
            onTap: tappable ? () => onAction!(check, service) : null,
            theme: theme,
          ),
      ],
    );
  }
}

/// Minor units to a displayable amount, with INTEGER arithmetic.
///
/// `priceCents / 100` as a double is wrong for the same reason money is
/// never a double: the quotient is not exactly representable and large
/// values lose the cents entirely. Integer division plus a padded remainder
/// has no such range.
///
/// TWO MINOR DIGITS IS AN ASSUMPTION, and it is the wire field's own: it is
/// named `price_cents` and documented as "minor units", which asserts a
/// hundredth. A zero-decimal currency (JPY, KRW) would render 100x too
/// large. That cannot be fixed here — it needs the currency on the payload
/// (eden-biz#860) before the exponent can be derived from anything real.
String edenFormatMinorUnits(int minorUnits) {
  final bool negative = minorUnits < 0;
  final int magnitude = minorUnits.abs();
  final String major = (magnitude ~/ 100).toString();
  final String minor = (magnitude % 100).toString().padLeft(2, '0');
  return '${negative ? '-' : ''}$major.$minor';
}

/// Minutes to a short duration label: `45 min`, `1 hr`, `1 hr 30 min`.
///
/// The fixture only records 30, so every other branch here is exercised by
/// the unit test rather than by a recording. `duration_minutes` is an
/// unbounded integer in the tool's `OutputSchema`, so the branches have to
/// exist whether or not a recording reaches them.
String edenFormatDurationMinutes(int minutes) {
  if (minutes < 60) return '$minutes min';
  final int hours = minutes ~/ 60;
  final int rest = minutes % 60;
  if (rest == 0) return '$hours hr';
  return '$hours hr $rest min';
}

/// One catalogue row: name, duration beneath it, price trailing.
class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    super.key,
    required this.service,
    required this.currencyCode,
    required this.onTap,
    required this.theme,
  });

  final EdenServiceSummary service;
  final String currencyCode;
  final VoidCallback? onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    // 48 MINIMUM, not 44 — this ships to the biz portal (pointer) AND the
    // companion app (touch), so the row is built to the stricter floor
    // rather than being correct on one surface and merely reported on the
    // other.
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
                  service.name,
                  style: EdenTypography.bodyMedium(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: EdenSpacing.space1),
                Text(
                  edenFormatDurationMinutes(service.durationMinutes),
                  key: ValueKey<String>('eden-service-duration-${service.id}'),
                  style: EdenTypography.bodySmall(context)
                      .copyWith(color: theme.colorScheme.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: EdenSpacing.space3),
          Text(
            // CODE THEN AMOUNT. See EdenServiceList.currencyCode: the code
            // is rendered because `$` cannot say which dollar this is.
            '$currencyCode ${edenFormatMinorUnits(service.priceCents)}',
            key: ValueKey<String>('eden-service-price-${service.id}'),
            style: EdenTypography.bodyMedium(context).copyWith(
              color: theme.colorScheme.onSurface,
              // Tabular figures so a column of prices lines up on the
              // decimal; proportional digits make two prices of the same
              // magnitude look like different lengths.
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          if (onTap != null)
            Padding(
              padding: const EdgeInsets.only(left: EdenSpacing.space2),
              child: Icon(
                Icons.chevron_right,
                size: 20,
                // onSurfaceVariant, not the brand: a chevron is a direction
                // cue, not a selection state — eden-ui-flutter#55/#58 are
                // the record of a brand hue carrying meaning as a glyph on
                // a light surface (2.05:1).
                color: theme.colorScheme.onSurfaceVariant,
              ),
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

/// The stated empty catalogue.
///
/// "LISTED", NOT "MATCHED", and the difference is the tool's. `find_customer`
/// takes a query, so nobody matching it is a search result; `list_services`
/// takes no arguments at all (`"arguments": {}` in the recording), so an
/// empty `services` array means the catalogue itself is empty. Copying
/// `list/customers`' "No services matched." would describe a search that
/// never happened.
class _EmptyCatalogue extends StatelessWidget {
  const _EmptyCatalogue({super.key});

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
        'No services are listed.',
        style: EdenTypography.bodyMedium(context).copyWith(
          // onSurfaceVariant on surfaceContainerLow — the pair
          // `list/customers`' empty state already measured at 7.41:1 light,
          // and it clears the floor dark too.
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
