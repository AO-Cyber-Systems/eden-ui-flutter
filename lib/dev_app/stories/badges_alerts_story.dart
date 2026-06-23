// lib/dev_app/stories/badges_alerts_story.dart
//
// Interactive story for EdenBadge + EdenAlert.
//
// Knob set mirrors badges_alerts_screen.dart:
//   - badgeVariant (EnumKnob<EdenBadgeVariant>)
//   - alertVariant (EnumKnob<EdenAlertVariant>)
//
// Previews both an EdenBadge and an EdenAlert so both variant knobs are live.
// Pure build function — no internal setState.
// Exported for central registration in 38-05.

import 'package:flutter/material.dart';

import '../../eden_ui.dart';
import '../registry/eden_story.dart';
import '../registry/knob_values.dart';

/// Interactive story for [EdenBadge] + [EdenAlert].
///
/// Registered by 38-05's central registry assembly.
final badgesAlertsInteractiveStory = EdenStory(
  id: 'badges-alerts/interactive',
  component: 'badges-alerts',
  name: 'Interactive',
  icon: Icons.local_offer_outlined,
  knobs: [
    const EnumKnob<EdenBadgeVariant>(
      key: 'badge-variant',
      label: 'Badge Variant',
      values: EdenBadgeVariant.values,
      defaultValue: EdenBadgeVariant.primary,
    ),
    const EnumKnob<EdenAlertVariant>(
      key: 'alert-variant',
      label: 'Alert Variant',
      values: EdenAlertVariant.values,
      defaultValue: EdenAlertVariant.info,
    ),
  ],
  build: (BuildContext context, KnobValues k) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      EdenBadge(
        label: 'Preview',
        variant: k.get<EdenBadgeVariant>('badge-variant'),
      ),
      const SizedBox(height: 16),
      EdenAlert(
        title: 'Alert Preview',
        message: 'This is a preview alert message.',
        variant: k.get<EdenAlertVariant>('alert-variant'),
      ),
    ],
  ),
);
