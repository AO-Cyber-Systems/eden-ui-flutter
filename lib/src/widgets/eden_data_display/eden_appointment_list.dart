// The `list/appointments` data-display component.
//
// SHAPE: `lib/src/widgets/eden_data_display/agent_intent_data.dart`, which
// names the eden-biz recordings every field was transcribed from (01, 02, 04).

import 'package:flutter/material.dart';

import '../../theme/eden_status_palette.dart';
import '../../tokens/radii.dart';
import '../../tokens/spacing.dart';
import '../../tokens/typography.dart';
import 'agent_intent_data.dart';

/// Below this width the row STACKS instead of running across.
///
/// Not a phone/tablet guess: it is the width at which the wide row's four
/// columns (time, identity, status, cancel) stop fitting without the client
/// name losing more than half its characters to the ellipsis.
const double kEdenAppointmentListNarrowBreakpoint = 600;

/// Called when the user fires an [EdenIntentAction] against one appointment.
typedef EdenAppointmentActionCallback = void Function(
  EdenIntentAction action,
  EdenAppointmentSummary appointment,
);

/// Renders a `list/appointments` intent.
///
/// AFFORDANCES ARE GRANTED BY THE PAYLOAD. A row is tappable only when
/// [actions] contains an action whose id is [kEdenAppointmentOpenActionId],
/// and the trailing cancel control exists only when [actions] contains
/// [kEdenAppointmentCancelActionId]. Hand it an empty [actions] list and it
/// renders a read-only list with no tap targets at all — which is the correct
/// rendering of an intent that granted nothing, and not a degraded one.
///
/// It also renders no affordance when [onAction] is null: an enabled control
/// that calls nothing is a lie the user only discovers by pressing it.
///
/// TWO HEIGHT MODES, AND THE SECOND IS THE ONE THIS COMPONENT EXISTS FOR.
///
/// BOUNDED (a panel, a route body, anything inside a `Scaffold`): the list
/// takes the height it is given and scrolls inside it, and the truncation
/// notice is pinned BELOW the scroll area rather than appended as a final row.
/// A truncation notice that scrolls is a notice nobody reads, because the
/// reader who needs it is the one who never reached the bottom.
///
/// UNBOUNDED (a conversational transcript, which is itself a scrollable and
/// therefore hands its children `maxHeight: infinity`): the list SHRINK-WRAPS,
/// stops scrolling on its own, and flows into the transcript's scroll. The
/// notice is then simply the last thing in the block, which is correct there —
/// there is no inner viewport for it to be pinned to.
///
/// This branch is not defensive tidying. `Expanded` under an unbounded parent
/// throws `RenderFlex children have non-zero flex but incoming height
/// constraints are unbounded`, and the agent-UI surface this component was
/// built for is exactly that shape. Every test in the repo pumps it through
/// `wrap()`, which always bounds height, so nothing would have caught it —
/// `eden_data_display_test.dart` now pumps it unbounded on purpose.
class EdenAppointmentList extends StatelessWidget {
  const EdenAppointmentList({
    super.key,
    required this.data,
    this.actions = const <EdenIntentAction>[],
    this.onAction,
  });

  /// The agent-intent `component_id` this widget renders.
  ///
  /// The binding between a payload and the widget that draws it lives HERE, on
  /// the widget, so a headless dispatcher can build its map by reading the
  /// components rather than by maintaining a second list that drifts.
  static const String componentId = 'list/appointments';

  /// The payload. See [EdenAppointmentListData].
  final EdenAppointmentListData data;

  /// `intent.actions`, verbatim. See the class doc: this is a GRANT list.
  final List<EdenIntentAction> actions;

  /// Fired when a granted action is taken. Null disables every affordance.
  final EdenAppointmentActionCallback? onAction;

  /// The granted action with [id], or null when the payload did not grant it.
  EdenIntentAction? _action(String id) {
    for (final EdenIntentAction action in actions) {
      if (action.id == id) return action;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EdenIntentAction? open =
        onAction == null ? null : _action(kEdenAppointmentOpenActionId);
    final EdenIntentAction? cancel =
        onAction == null ? null : _action(kEdenAppointmentCancelActionId);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool narrow =
            constraints.maxWidth < kEdenAppointmentListNarrowBreakpoint;
        final bool bounded = constraints.maxHeight.isFinite;

        final Widget body = data.appointments.isEmpty
            ? _EdenAppointmentsEmpty(
                centred: bounded,
                truncated: data.truncated,
              )
            : ListView.separated(
                // Shrink-wrapped and inert only when there is no height to
                // scroll within. Inside a bounded parent this stays a real
                // viewport, which is what keeps the 50-row story lazy.
                shrinkWrap: !bounded,
                physics:
                    bounded ? null : const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  vertical: EdenSpacing.space2,
                ),
                itemCount: data.appointments.length,
                separatorBuilder: (BuildContext context, int index) => Divider(
                  height: 1,
                  thickness: 1,
                  color: theme.colorScheme.outlineVariant,
                ),
                itemBuilder: (BuildContext context, int index) {
                  final EdenAppointmentSummary appointment =
                      data.appointments[index];
                  return _EdenAppointmentRow(
                    appointment: appointment,
                    narrow: narrow,
                    openAction: open,
                    cancelAction: cancel,
                    onAction: onAction,
                  );
                },
              );

        return Column(
          // `min` when unbounded: a Column that tried to be `max` against an
          // infinite height is the same crash as the `Expanded` below it.
          mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (bounded) Expanded(child: body) else body,
            // SUPPRESSED ON AN EMPTY LIST. `truncated: true` with zero rows
            // rendered "No upcoming appointments" directly above "Showing the
            // first 0", which is not a sentence anyone can act on and reads
            // like a bug in the tool rather than an answer. No recording pairs
            // the two — `limit: 0` is the only way to reach it — and when they
            // do meet, the empty state is the whole of what is known.
            if (data.truncated && data.appointments.isNotEmpty)
              _EdenAppointmentsTruncated(shown: data.appointments.length),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Empty
// ---------------------------------------------------------------------------

/// Fixture 02's rendering: `appointments: []` with the key present.
///
/// It says NOTHING WENT WRONG, in as many words. An empty list and a failed
/// list look identical when the empty state is a blank panel, and the whole
/// point of having a separate `error/refusal` component is that these two are
/// not the same answer.
class _EdenAppointmentsEmpty extends StatelessWidget {
  const _EdenAppointmentsEmpty({
    required this.centred,
    required this.truncated,
  });

  /// True inside a bounded parent, where there is space to centre within.
  ///
  /// False under an unbounded height: `Center` would try to fill infinity.
  /// The state then sizes to its own content with a generous inset, which is
  /// also how it should read in a conversational transcript — a block of
  /// prose, not a centred placeholder in a panel that does not exist.
  final bool centred;

  /// Whether the payload ALSO said the result was cut short.
  ///
  /// THE RENDERED ANSWER MUST NOT BE STRONGER THAN THE DATA. Suppressing the
  /// "Showing the first 0" notice fixed a nonsense sentence and left a worse
  /// one behind: the default body says the schedule "was read successfully and
  /// there is nothing booked in the window that was asked about", which is a
  /// claim of COMPLETENESS, while `truncated: true` says the opposite. That is
  /// an outage rendering as an empty state, one axis over from the failure this
  /// component's empty copy was written to avoid. Caught in the
  /// eden-ui-flutter#53 re-review.
  final bool truncated;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Widget content = Padding(
      padding: const EdgeInsets.all(EdenSpacing.space6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.event_available_outlined,
            size: _kEmptyIconSize,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: EdenSpacing.space3),
          Text(
            _kEmptyHeading,
            style: EdenTypography.headlineSmall(context).copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: EdenSpacing.space1),
          Text(
            truncated ? _kEmptyTruncatedBody : _kEmptyBody,
            textAlign: TextAlign.center,
            style: EdenTypography.bodyMedium(context).copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
    return centred ? Center(child: content) : content;
  }
}

// ---------------------------------------------------------------------------
// Truncation
// ---------------------------------------------------------------------------

/// Fixture 04's rendering: `truncated: true`.
///
/// It names the number SHOWN and never a number missing, because the payload
/// carries no total — see [EdenAppointmentListData.truncated]. "50 of 61"
/// would be fabricated; "showing the first 50" is what is known.
class _EdenAppointmentsTruncated extends StatelessWidget {
  const _EdenAppointmentsTruncated({required this.shown});

  final int shown;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EdenStatusPalette palette =
        theme.extension<EdenStatusPalette>() ?? EdenStatusPalette.commercial();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space4,
        vertical: EdenSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.filter_list_outlined,
            size: _kTruncatedIconSize,
            color: palette.warningFg,
          ),
          const SizedBox(width: EdenSpacing.space2),
          Expanded(
            child: Text(
              'Showing the first $shown. More matched than this list carries — '
              'narrow the request to see the rest.',
              style: EdenTypography.bodySmall(context).copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Row
// ---------------------------------------------------------------------------

/// One appointment.
///
/// SEMANTICS SHAPE — copied deliberately from `EdenDesktopLayout._navRow`,
/// which is the shape in this repo already proved to publish exactly ONE
/// identified node per row with exactly one working tap route:
/// a `Semantics(identifier:, button:, label:, onTap:)` wrapping an opaque
/// `GestureDetector`. Two nested IDENTIFIED annotations publish two nodes with
/// identical rects, which is why the cancel control is a SIBLING of the
/// tappable region and never a descendant of it — nested, the two would also
/// trip `expectUiSane`'s disjointness rule, and on web the outer node would
/// eat the inner one's clicks.
class _EdenAppointmentRow extends StatelessWidget {
  const _EdenAppointmentRow({
    required this.appointment,
    required this.narrow,
    required this.openAction,
    required this.cancelAction,
    required this.onAction,
  });

  final EdenAppointmentSummary appointment;
  final bool narrow;
  final EdenIntentAction? openAction;
  final EdenIntentAction? cancelAction;
  final EdenAppointmentActionCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final Widget content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space4,
        vertical: EdenSpacing.space3,
      ),
      child: narrow ? _narrowBody(context) : _wideBody(context),
    );

    final EdenIntentAction? open = openAction;
    final Widget tappable = open == null
        ? content
        : Semantics(
            identifier: 'eden-appointment-${appointment.id}',
            button: true,
            label: '${appointment.serviceName} with ${appointment.staffName} '
                'for ${appointment.clientName}',
            onTap: () => onAction!(open, appointment),
            // `excludeFromSemantics: true` is LOAD-BEARING, not tidiness.
            // Without it the detector publishes a SECOND semantics node
            // carrying its own `tap`, under the identified one that already
            // advertises the route — so a single tap fires twice and
            // `expectUiSane` reports "declares 2 tap actions". (It also
            // published an unlabelled 48x48 tappable node, which failed
            // `labeledTapTargetGuideline` in the same run.) Excluding it
            // leaves exactly one route, on the node that carries the
            // identifier and the label, over a hit surface a finger can
            // actually take.
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
              onTap: () => onAction!(open, appointment),
              child: content,
            ),
          );

    final EdenIntentAction? cancel = cancelAction;
    if (cancel == null) return tappable;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(child: tappable),
        _EdenAppointmentCancel(
          appointment: appointment,
          action: cancel,
          onAction: onAction!,
        ),
      ],
    );
  }

  /// Wide: time | identity | status, read left to right.
  Widget _wideBody(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: _kWideTimeColumnWidth,
          child: _EdenAppointmentWhen(appointment: appointment, stacked: true),
        ),
        const SizedBox(width: EdenSpacing.space4),
        Expanded(child: _EdenAppointmentWho(appointment: appointment)),
        const SizedBox(width: EdenSpacing.space4),
        _EdenAppointmentStatus(status: appointment.status),
      ],
    );
  }

  /// Narrow: identity first with the status beside it, then WHEN, then the
  /// note. The time leads on a wide row because a scanning eye uses it as the
  /// index; at 390 there is no scanning, only reading, and the name is what
  /// the reader came for.
  Widget _narrowBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Text(
                appointment.clientName,
                overflow: TextOverflow.ellipsis,
                style: EdenTypography.labelLarge(context).copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: EdenSpacing.space2),
            _EdenAppointmentStatus(status: appointment.status),
          ],
        ),
        const SizedBox(height: EdenSpacing.space1),
        _EdenAppointmentWhen(appointment: appointment, stacked: false),
        const SizedBox(height: EdenSpacing.space1),
        _EdenAppointmentDetail(
          text: '${appointment.serviceName} · ${appointment.staffName}',
        ),
        if (appointment.notes != null) ...<Widget>[
          const SizedBox(height: EdenSpacing.space1),
          _EdenAppointmentNotes(notes: appointment.notes!),
        ],
      ],
    );
  }
}

/// The trailing cancel control.
///
/// A 48x48 opaque box, which is the Android tap-target floor and clears the
/// iOS 44pt one — `expectUiSane` asserts BOTH on a touch surface, and an
/// icon sized to its glyph would fail both while looking fine.
class _EdenAppointmentCancel extends StatelessWidget {
  const _EdenAppointmentCancel({
    required this.appointment,
    required this.action,
    required this.onAction,
  });

  final EdenAppointmentSummary appointment;
  final EdenIntentAction action;
  final EdenAppointmentActionCallback onAction;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Semantics(
      identifier: 'eden-appointment-${appointment.id}-cancel',
      button: true,
      label: 'Cancel ${appointment.serviceName} for ${appointment.clientName}',
      onTap: () => onAction(action, appointment),
      // See the note on the row's detector: excluded, or this publishes a
      // second, unlabelled tap node under the identified one.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: () => onAction(action, appointment),
        child: SizedBox(
          width: EdenSpacing.space12,
          height: EdenSpacing.space12,
          child: Icon(
            Icons.close,
            size: _kCancelIconSize,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// `09:00 – 10:00` over (or beside) `Tue 8 Jan`.
class _EdenAppointmentWhen extends StatelessWidget {
  const _EdenAppointmentWhen({
    required this.appointment,
    required this.stacked,
  });

  final EdenAppointmentSummary appointment;

  /// True on the wide row, where the time column has its own width and the
  /// date sits under the clock. False on the narrow row, where they run
  /// together on one line.
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String clock =
        '${edenFormatClock(appointment.startsAt)} – '
        '${edenFormatClock(appointment.endsAt)}';
    final String day = edenFormatDay(appointment.startsAt);

    if (!stacked) {
      return Text(
        '$clock · $day',
        style: EdenTypography.bodySmall(context).copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          clock,
          style: EdenTypography.labelLarge(context).copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        Text(
          day,
          style: EdenTypography.bodySmall(context).copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Client name, then service · staff, then the note.
class _EdenAppointmentWho extends StatelessWidget {
  const _EdenAppointmentWho({required this.appointment});

  final EdenAppointmentSummary appointment;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          appointment.clientName,
          overflow: TextOverflow.ellipsis,
          style: EdenTypography.labelLarge(context).copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: EdenSpacing.space1),
        _EdenAppointmentDetail(
          text: '${appointment.serviceName} · ${appointment.staffName}',
        ),
        if (appointment.notes != null) ...<Widget>[
          const SizedBox(height: EdenSpacing.space1),
          _EdenAppointmentNotes(notes: appointment.notes!),
        ],
      ],
    );
  }
}

/// Secondary one-liner.
class _EdenAppointmentDetail extends StatelessWidget {
  const _EdenAppointmentDetail({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Text(
      text,
      overflow: TextOverflow.ellipsis,
      style: EdenTypography.bodySmall(context).copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// A tenant's free-text note, rendered as INERT TEXT.
///
/// One line, ellipsised. See [EdenAppointmentSummary.notes]: row 5 of fixture
/// 01 carries a prompt-injection attempt in this field. Nothing here parses
/// it, linkifies it, or passes it anywhere it could be acted on — it is drawn
/// and that is all. The single line is also why the injection string cannot
/// push the rest of the row off the screen.
class _EdenAppointmentNotes extends StatelessWidget {
  const _EdenAppointmentNotes({required this.notes});

  final String notes;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(
          Icons.sticky_note_2_outlined,
          size: _kNoteIconSize,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: EdenSpacing.space1),
        Expanded(
          child: Text(
            notes,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: EdenTypography.bodySmall(context).copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}

/// The status pill.
///
/// THE COLOUR IS A DOT, THE WORD IS NOT COLOURED. Painting `confirmed` in
/// `EdenStatusPalette.successFg` (#10B981) on this package's light surface
/// measures 2.4:1 — under WCAG 1.4.3's 4.5:1 floor, and `expectUiSane`'s
/// contrast rule WOULD have caught it. Moving the hue onto a non-text glyph
/// and leaving the word in `onSurface` clears the floor without losing the
/// at-a-glance colour. It also means the state is legible to a reader who
/// cannot see the hue at all, which the coloured word never was.
class _EdenAppointmentStatus extends StatelessWidget {
  const _EdenAppointmentStatus({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EdenStatusPalette palette =
        theme.extension<EdenStatusPalette>() ?? EdenStatusPalette.commercial();
    final Color dot = switch (EdenAppointmentStatusTone.of(status)) {
      EdenAppointmentStatusTone.confirmed => palette.successFg,
      EdenAppointmentStatusTone.neutral => palette.neutralFg,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space2,
        vertical: EdenSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: EdenRadii.borderRadiusFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: _kStatusDotSize,
            height: _kStatusDotSize,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: EdenSpacing.space1),
          Text(
            status,
            style: EdenTypography.labelSmall(context).copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Formatting
// ---------------------------------------------------------------------------

/// `2030-01-08T09:00:00Z` -> `09:00`.
///
/// NO `toLocal()`, NO `package:intl`. See [EdenAppointmentSummary.startsAt]:
/// localising here would make every golden a recording of the machine that
/// took it. `intl` is not a dependency of this package and adding one to
/// format two fields would enter eden-biz's and aodex's production resolve.
@visibleForTesting
String edenFormatClock(DateTime at) =>
    '${at.hour.toString().padLeft(2, '0')}:'
    '${at.minute.toString().padLeft(2, '0')}';

/// `2030-01-08T09:00:00Z` -> `Tue 8 Jan`.
///
/// (Both doc examples said `Wed` until eden-ui-flutter#53 review. The CODE
/// was right -- 2030-01-08 is a Tuesday, the goldens render `Tue 8 Jan` and
/// the unit test below asserts `Tue 8 Jan` -- so the only thing wrong was
/// the prose a reader checks the behaviour against, which is the worst
/// place for it to be wrong.)
@visibleForTesting
String edenFormatDay(DateTime at) =>
    '${_kWeekdays[at.weekday - 1]} ${at.day} ${_kMonths[at.month - 1]}';

/// `DateTime.weekday` is 1..7 starting at Monday.
const List<String> _kWeekdays = <String>[
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

/// `DateTime.month` is 1..12.
const List<String> _kMonths = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

// ---------------------------------------------------------------------------
// Sizes and copy
// ---------------------------------------------------------------------------

/// Width of the wide row's time column. Sized to `09:00 – 10:00` at
/// [EdenTypography.labelLarge] with room for a two-digit day and a
/// three-letter month beneath it.
const double _kWideTimeColumnWidth = 116;

const double _kStatusDotSize = 8;
const double _kNoteIconSize = 14;
const double _kCancelIconSize = 20;
const double _kEmptyIconSize = 40;
const double _kTruncatedIconSize = 16;

/// UI COPY, not payload.
const String _kEmptyHeading = 'No upcoming appointments';

/// UI COPY. Says explicitly that this is an ANSWER, because an empty panel and
/// a failed request look the same otherwise.
///
/// It claims COMPLETENESS ("nothing booked in the window that was asked
/// about"), which is only true when the payload did not also say the result
/// was cut. See [_kEmptyTruncatedBody].
const String _kEmptyBody =
    'The schedule was read successfully and there is nothing booked in the '
    'window that was asked about.';

/// UI COPY for `appointments: []` WITH `truncated: true` — reachable only with
/// `limit: 0`, and recorded by no fixture.
///
/// It says the read succeeded (so this is still not an outage) and stops
/// short of claiming the window is empty, because the payload did not say
/// that. Two facts, neither of them inflated into the other.
const String _kEmptyTruncatedBody =
    'The schedule was read successfully and nothing came back. The result was '
    'also marked as cut short, so this may not be the whole answer — narrow '
    'the request and ask again.';
