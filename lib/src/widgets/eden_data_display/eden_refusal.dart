// The `error/refusal` data-display component.
//
// SHAPE: `lib/src/widgets/eden_data_display/agent_intent_data.dart`, which
// names the eden-biz recordings every field was transcribed from (03 and 14).

import 'package:flutter/material.dart';

import '../../theme/eden_status_palette.dart';
import '../../tokens/radii.dart';
import '../../tokens/spacing.dart';
import '../../tokens/typography.dart';
import 'agent_intent_data.dart';

/// Widest the refusal card is allowed to get, in logical pixels.
///
/// A refusal is one short sentence. Let it run the full width of a desktop
/// content column and the eye has to travel the whole 1280 to read nine words,
/// which reads as a page rather than as an answer. Not an [EdenSpacing] step
/// on purpose: this is a MEASURE (a line-length limit), not a gap, and the
/// spacing scale has nothing to say about it.
const double kEdenRefusalMaxWidth = 560;

/// Renders an `error/refusal` intent: the agent was asked for something and
/// said no, with a reason.
///
/// ONE-SIDED BY CONSTRUCTION. There is no `onAction`, no `onRetry`, and no
/// actions parameter on this widget — the recordings carry `actions: []` and
/// that emptiness is the contract, so it is expressed in the constructor
/// signature rather than in a comment somebody can route around. See
/// [EdenRefusalData] for the full argument. If a future payload ever DOES
/// carry actions on a refusal, that is a deliberate API change here and a new
/// recording to point at — not a parameter quietly added because a screen
/// wanted a button.
///
/// The reason is displayed verbatim and is never interpreted. It arrives from
/// the same untrusted channel as an appointment's notes.
class EdenRefusal extends StatelessWidget {
  const EdenRefusal({super.key, required this.data});

  /// The agent-intent `component_id` this widget renders.
  ///
  /// The binding between a payload and the widget that draws it lives HERE, on
  /// the widget, so a headless dispatcher can build its map by reading the
  /// components rather than by maintaining a second list that drifts.
  static const String componentId = 'error/refusal';

  /// The refusal payload. See [EdenRefusalData].
  final EdenRefusalData data;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EdenStatusPalette palette =
        theme.extension<EdenStatusPalette>() ?? EdenStatusPalette.commercial();

    // `is_error` IS READ, and this is where. It was carried on the model with
    // a comment saying a dropped field "cannot later be noticed changing" --
    // but nothing read it, so `is_error: false` rendered pixel-identically to
    // `true` and the field could have changed for ever without anything
    // noticing. A transcribed field that nothing consumes is not a guard
    // against drift; it is a claim of one.
    //
    // It selects the TONE and nothing else: same layout, same copy, same
    // absence of actions. Every recording to date is `true` and renders in the
    // danger palette; a refusal the tool did not flag as an error is still a
    // refusal, it just does not shout. No recording exercises the neutral
    // branch -- it exists so the field is observable, and
    // `eden_data_display_test.dart` pins that the two differ.
    final Color edge = data.isError ? palette.dangerBorder : palette.neutralBorder;
    final Color glyph = data.isError ? palette.dangerFg : palette.neutralFg;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // THE REASON IS UNTRUSTED TEXT OF UNKNOWN LENGTH. It comes back from a
        // tool error, so its length is not this package's to assume. In a
        // non-scrolling `mainAxisSize: min` Column a long one overflowed --
        // which in debug is a yellow-and-black band and in RELEASE is silent
        // clipping, i.e. exactly the "reason the reader cannot see" that
        // refusing to ellipsise it was meant to prevent.
        //
        // So the reason SCROLLS inside whatever height the card has, while the
        // heading and the footer stay put. Nothing is truncated and nothing is
        // hidden: the text is all there, and reaching it is a gesture rather
        // than a guess.
        //
        // Under an UNBOUNDED height there is nothing to scroll within and a
        // viewport would throw, so the text simply lays out at full height --
        // correct in a conversational transcript, which scrolls for it.
        final Widget reason = Text(
          data.reason,
          style: EdenTypography.bodyLarge(context).copyWith(
            color: theme.colorScheme.onSurface,
          ),
        );

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kEdenRefusalMaxWidth),
            child: Container(
              padding: const EdgeInsets.all(EdenSpacing.space6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: EdenRadii.borderRadiusLg,
                border: Border.all(color: edge),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      // A GLYPH, not text. WCAG 1.4.3 does not reach it and
                      // `expectUiSane`'s contrast rule only walks Text and
                      // EditableText, so nothing here measures it: the 3:1
                      // non-text floor it clears (dangerFg #EF4444 on
                      // surfaceContainerLow is 3.9:1 light, 5.4:1 dark) is
                      // asserted by this comment and by a human looking at the
                      // golden, and by nothing else in the gate.
                      Icon(
                        Icons.block_outlined,
                        size: _kRefusalIconSize,
                        color: glyph,
                      ),
                      const SizedBox(width: EdenSpacing.space3),
                      Expanded(
                        child: Text(
                          _kRefusalHeading,
                          style: EdenTypography.headlineSmall(context).copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: EdenSpacing.space3),
                  // VERBATIM. No prefix stripping, no rewording, no ellipsis:
                  // the reason is the entire content of a refusal.
                  if (constraints.maxHeight.isFinite)
                    Flexible(child: SingleChildScrollView(child: reason))
                  else
                    reason,
                  const SizedBox(height: EdenSpacing.space4),
                  // THE ABSENCE OF A BUTTON, SAID OUT LOUD. Without this line
                  // the card is a dead end that looks like a loading state
                  // someone forgot to finish. With it, the dead end is the
                  // message.
                  Text(
                    _kRefusalFooter,
                    style: EdenTypography.bodySmall(context).copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Icon size. Matched to [EdenTypography.headlineSmall]'s 18px so the glyph
/// and the heading share a cap height.
const double _kRefusalIconSize = 20;

/// UI COPY, not payload. The payload names the reason; naming the CATEGORY is
/// this package's job, and it must not read like a system fault — the request
/// was understood and declined, which is a different thing from a crash.
const String _kRefusalHeading = 'Request refused';

/// UI COPY. Says why there is nothing to press.
const String _kRefusalFooter =
    'This request was declined and cannot be retried from here.';
