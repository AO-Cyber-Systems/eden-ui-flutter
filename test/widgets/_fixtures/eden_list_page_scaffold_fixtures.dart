// Hand-built fixtures. Do NOT regenerate via LLM; mutate in-place when
// EdenListPageScaffold's public API changes.
//
// Pattern: factories return either a plain [Widget] (for tests that only
// pump and assert on visible output) or a record `({Widget widget, ...})`
// that exposes captured callback events for behavioral tests.
//
// NO Riverpod, NO mocking library, NO LLM-generated test data. Pure Flutter.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';

/// Hand-built fixtures for [EdenListPageScaffold] widget tests.
class EdenListPageScaffoldFixtures {
  EdenListPageScaffoldFixtures._();

  /// Minimal: only required props (title + body). All optional slots null.
  static Widget minimal() {
    return const EdenListPageScaffold(
      title: 'Projects',
      body: Text('body'),
    );
  }

  /// Full slot composition with stub callbacks. The returned record exposes:
  /// - `widget` — the widget to pump
  /// - `onCreateInvoked` — getter returning whether the create button fired
  /// - `searchEvents` — list of all values fired by onSearchChanged
  static ({
    Widget widget,
    bool Function() onCreateInvoked,
    List<String> searchEvents,
  }) full() {
    var createInvoked = false;
    final searchEvents = <String>[];

    final widget = EdenListPageScaffold(
      title: 'Customers',
      createLabel: 'New Customer',
      onCreate: () {
        createInvoked = true;
      },
      filterPills: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Chip(label: Text('Active')),
          SizedBox(width: 8),
          Chip(label: Text('Archived')),
        ],
      ),
      searchHint: 'Search customers...',
      onSearchChanged: searchEvents.add,
      alerts: Container(
        padding: const EdgeInsets.all(8),
        color: const Color(0xFFFFF3CD),
        child: const Text('1 blocking alert'),
      ),
      body: ListView(
        children: List.generate(
          20,
          (i) => ListTile(title: Text('Row $i')),
        ),
      ),
    );

    return (
      widget: widget,
      onCreateInvoked: () => createInvoked,
      searchEvents: searchEvents,
    );
  }

  /// Long title + long create label, to force the iPhone-narrow constraint
  /// test to exercise the LayoutBuilder fallback (header stacks vertically
  /// when constraints are tight).
  static Widget narrowOverflowProbe() {
    return EdenListPageScaffold(
      title: 'Very Long Page Title That Might Cause Overflow At Narrow Widths',
      createLabel: 'Create Something With A Long Label',
      onCreate: () {},
      body: const Text('body'),
    );
  }
}
