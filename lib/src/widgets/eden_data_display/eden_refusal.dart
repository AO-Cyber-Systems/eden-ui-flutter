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

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kEdenRefusalMaxWidth),
        child: Container(
          padding: const EdgeInsets.all(EdenSpacing.space6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: EdenRadii.borderRadiusLg,
            border: Border.all(color: palette.dangerBorder),
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
                    color: palette.dangerFg,
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
              // VERBATIM. No prefix stripping, no rewording, no ellipsis: the
              // reason is the entire content of a refusal, and a truncated
              // reason is a refusal whose cause the reader cannot see.
              Text(
                data.reason,
                style: EdenTypography.bodyLarge(context).copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: EdenSpacing.space4),
              // THE ABSENCE OF A BUTTON, SAID OUT LOUD. Without this line the
              // card is a dead end that looks like a loading state someone
              // forgot to finish. With it, the dead end is the message.
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
