// Hand-built fixtures. Do NOT regenerate via LLM; mutate in-place when
// EdenDetailPageScaffold's public API changes.
//
// Sample data is intentionally simple, deterministic, and aligned to the
// trades-flutter detail-page archetype (Customer / Project / Service).
// NO Riverpod, NO mocking library, NO LLM-generated test data.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';

/// Hand-built fixtures for [EdenDetailPageScaffold] tests.
class EdenDetailPageScaffoldFixtures {
  EdenDetailPageScaffoldFixtures._();

  /// Header-only: no tabs, no side rail.
  static Widget headerOnly() {
    return const EdenDetailPageScaffold(
      header: EdenDetailHeader(title: 'Customer ABC123'),
      body: Text('body content'),
    );
  }

  /// With tabs. Caller passes the labels; the body is a TabBarView wired to
  /// the [DefaultTabController] provided by this fixture.
  static Widget withTabs(List<String> tabLabels) {
    return DefaultTabController(
      length: tabLabels.length,
      child: EdenDetailPageScaffold(
        header: const EdenDetailHeader(title: 'Customer ABC123'),
        tabs: tabLabels.map((l) => EdenDetailTab(label: l)).toList(),
        body: TabBarView(
          children: tabLabels
              .map((l) => Center(child: Text('Tab body: $l')))
              .toList(),
        ),
      ),
    );
  }

  /// With side rail; no tabs.
  static Widget withSideRail() {
    return const EdenDetailPageScaffold(
      header: EdenDetailHeader(title: 'Customer ABC123'),
      sideRail: _SampleSideRail(),
      body: Text('body content'),
    );
  }

  /// Full composition: header + tabs + side rail + body (TabBarView).
  static Widget full() {
    const tabs = ['Overview', 'Activity', 'Files'];
    return DefaultTabController(
      length: tabs.length,
      child: const EdenDetailPageScaffold(
        header: EdenDetailHeader(
          title: 'Customer ABC123',
          subtitle: 'Acme HVAC Co.',
        ),
        tabs: [
          EdenDetailTab(label: 'Overview'),
          EdenDetailTab(label: 'Activity'),
          EdenDetailTab(label: 'Files'),
        ],
        sideRail: _SampleSideRail(),
        body: TabBarView(
          children: [
            Center(child: Text('Overview body')),
            Center(child: Text('Activity body')),
            Center(child: Text('Files body')),
          ],
        ),
      ),
    );
  }

  /// Narrow viewport fixture: side rail collapses to a bottom "Details"
  /// button when the surface is below the breakpoint.
  static Widget narrowResponsive() {
    return const EdenDetailPageScaffold(
      header: EdenDetailHeader(title: 'Customer ABC123'),
      sideRail: _SampleSideRail(),
      body: Center(child: Text('body content')),
    );
  }
}

/// Trivial side-rail fixture used by the scaffold demos.
class _SampleSideRail extends StatelessWidget {
  const _SampleSideRail();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: const Color(0xFFF5F5F5),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Side rail'),
          SizedBox(height: 8),
          Text('Quick stats'),
        ],
      ),
    );
  }
}
