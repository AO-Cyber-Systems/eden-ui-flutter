// Hand-built fixtures. Do NOT regenerate via LLM; mutate in-place when
// EdenDetailHeader's public API changes.
//
// Sample data is intentionally simple, deterministic, and aligned to the
// trades-flutter detail-page archetype (Customer / Project / Service).
// NO Riverpod, NO mocking library, NO LLM-generated test data.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';

/// Hand-built fixtures for [EdenDetailHeader] tests.
class EdenDetailHeaderFixtures {
  EdenDetailHeaderFixtures._();

  /// Minimal: title only.
  static Widget minimal() {
    return const EdenDetailHeader(title: 'Customer ABC123');
  }

  /// Title + subtitle (e.g., trade name under display name).
  static Widget withSubtitle() {
    return const EdenDetailHeader(
      title: 'Customer ABC123',
      subtitle: 'Acme HVAC Co.',
    );
  }

  /// Title + breadcrumb segments rendered above the title row.
  static Widget withBreadcrumb() {
    return const EdenDetailHeader(
      title: 'Customer ABC123',
      breadcrumb: ['Customers', 'Active'],
    );
  }

  /// Title + N action icons. Triggers PopupMenuButton overflow when
  /// `n > actionsOverflowAtCount`.
  /// Returns a record exposing the captured set of action-tap labels.
  static ({Widget widget, List<String> tapped}) withActions(int n) {
    final tapped = <String>[];
    final allActions = <EdenDetailHeaderAction>[
      EdenDetailHeaderAction(
        icon: Icons.star,
        tooltip: 'Star',
        onPressed: () => tapped.add('Star'),
      ),
      EdenDetailHeaderAction(
        icon: Icons.push_pin,
        tooltip: 'Pin',
        onPressed: () => tapped.add('Pin'),
      ),
      EdenDetailHeaderAction(
        icon: Icons.share,
        tooltip: 'Share',
        onPressed: () => tapped.add('Share'),
      ),
      EdenDetailHeaderAction(
        icon: Icons.archive,
        tooltip: 'Archive',
        onPressed: () => tapped.add('Archive'),
      ),
      EdenDetailHeaderAction(
        icon: Icons.delete_outline,
        tooltip: 'Delete',
        onPressed: () => tapped.add('Delete'),
      ),
      EdenDetailHeaderAction(
        icon: Icons.flag_outlined,
        tooltip: 'Flag',
        onPressed: () => tapped.add('Flag'),
      ),
    ];
    return (
      widget: EdenDetailHeader(
        title: 'Customer ABC123',
        actions: allActions.take(n).toList(),
      ),
      tapped: tapped,
    );
  }

  /// Long-title probe for the iPhone-narrow overflow safety case.
  static Widget narrowOverflowProbe() {
    return EdenDetailHeader(
      title:
          'Customer With An Extremely Long Display Name That Should Wrap Or Ellipsize Before Overflowing The Row',
      subtitle: 'Acme HVAC Co. — Field Services Division',
      leading: const Icon(Icons.business),
      statusBadge: const Chip(label: Text('Active')),
      actions: [
        EdenDetailHeaderAction(
          icon: Icons.star,
          tooltip: 'Star',
          onPressed: () {},
        ),
        EdenDetailHeaderAction(
          icon: Icons.archive,
          tooltip: 'Archive',
          onPressed: () {},
        ),
      ],
    );
  }
}
