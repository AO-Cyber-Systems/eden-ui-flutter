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
    // `eden_data_display_test.dart` pins that the two differ AND that both
    // clear the contrast floor in BOTH themes.
    //
    // THE NEUTRAL BRANCH DOES NOT COME FROM EdenStatusPalette, and that is the
    // whole of this paragraph. `EdenStatusPalette.forProfile` takes no
    // `Brightness`: light and dark share ONE palette. The danger values were
    // audited against both surfaces and hold. The neutral ones were not, and
    // do not -- measured against `surfaceContainerLow`:
    //
    //   neutralFg     #52525B   light 7.41:1   dark 2.29:1  <- under the 3:1
    //                                                          non-text floor
    //   neutralBorder #E4E4E7   light 1.22:1   dark 13.96:1 <- a near-white
    //                                                          ring in dark,
    //                                                          where danger is
    //                                                          a 30%-alpha red
    //
    // So the neutral branch reads brightness-aware values off the colorScheme
    // instead:
    //
    //   onSurfaceVariant   light 4.63:1   dark 6.91:1  (glyph, clears 3:1)
    //   outline            light 1.42:1   dark 1.70:1  (ring, subtle in both)
    //
    // This mattered because of WHERE the defect was: adding a second tone put
    // a new branch into the exact blind spot the comment fifty lines down
    // documents -- the oracle walks only `Text`/`EditableText`, and no story
    // or golden exercises `isError: false`. The test computes the ratios; see
    // "the neutral tone is legible in BOTH themes".
    final Color edge =
        data.isError ? palette.dangerBorder : theme.colorScheme.outline;
    final Color glyph =
        data.isError ? palette.dangerFg : theme.colorScheme.onSurfaceVariant;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // THE REASON IS UNTRUSTED TEXT OF UNKNOWN LENGTH. It comes back from a
        // tool error, so its length is not this package's to assume. In a
        // non-scrolling `mainAxisSize: min` Column a long one overflowed --
        // which in debug is a yellow-and-black band and in RELEASE is silent
        // clipping, i.e. exactly the "reason the reader cannot see" that
        // refusing to ellipsise it was meant to prevent.
        //
        // THE WHOLE CARD SCROLLS, NOT JUST THE REASON. The first fix put the
        // reason alone in a `Flexible(SingleChildScrollView(...))`, keeping the
        // heading and footer pinned. That is the nicer shape at a comfortable
        // height and it is WORSE THAN THE BUG at a small one: Flexible hands
        // the reason `cardHeight - (heading + two spacers + footer + padding)`,
        // which at 900x180 is a 59px viewport, at 140 is 19px, and at 120 is
        // ZERO -- plus `RenderFlex overflowed by 1.00 pixels`. Pre-fix, the
        // reason at least laid out at full height and its first lines were
        // visible before the clip. So the "fix" turned a clipped reason into an
        // absent and unscrollable one, on a card still cheerfully rendering its
        // heading and its "nothing to press" footer. Found in the
        // eden-ui-flutter#53 re-review.
        //
        // One viewport around the whole content has no such threshold. When the
        // content fits, a shrink-wrapping scroll view changes no pixel (the
        // goldens are byte-identical across this change). When it does not, the
        // heading scrolls with everything else and EVERY part of the card stays
        // reachable -- which at 120px is the only honest option, because there
        // is no height at which a pinned heading plus a pinned footer plus a
        // usable reason viewport all fit.
        //
        // Under an UNBOUNDED height there is nothing to scroll within and a
        // viewport would throw, so the content simply lays out at full height --
        // correct in a conversational transcript, which scrolls for it.
        final Widget reason = Text(
          data.reason,
          style: EdenTypography.bodyLarge(context).copyWith(
            color: theme.colorScheme.onSurface,
          ),
        );

        final Widget card = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                // A GLYPH, not text. WCAG 1.4.3 does not reach it and
                // `expectUiSane`'s contrast rule only walks Text and
                // EditableText, so nothing in the ORACLE measures it. The 3:1
                // non-text floor it clears against `surfaceContainerLow` is
                // dangerFg #EF4444 at 3.61:1 light and 4.71:1 dark. (An
                // earlier version of this comment said 3.9 and 5.4. Both were
                // wrong, both still cleared the floor, and neither was
                // computed -- which is the same defect as the rest of this
                // review, in the one comment claiming to be the only check.
                // They are now computed, by the test named below.)
                //
                // It is no longer true that NOTHING measures it:
                // `eden_data_display_test.dart` computes the WCAG ratio for
                // both branches in both themes. That is a check on resolved
                // colours, not on painted pixels -- it would not catch a
                // ShaderMask or a ColorFiltered ancestor, per
                // ORACLE_COVERAGE.md -- but it is a real floor where there was
                // previously only prose.
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
              child: constraints.maxHeight.isFinite
                  ? SingleChildScrollView(child: card)
                  : card,
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
