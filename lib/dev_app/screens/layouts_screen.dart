import 'package:flutter/material.dart';
import '../../eden_ui.dart';

/// Shared nav items used by both desktop and mobile layout demos.
final _navItems = [
  const EdenNavItem(
    id: '__main__',
    label: 'Main',
    icon: Icons.apps,
    children: [
      EdenNavItem(id: 'dashboard', label: 'Dashboard', icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard),
      EdenNavItem(id: 'inbox', label: 'Inbox', icon: Icons.inbox_outlined, activeIcon: Icons.inbox, badge: '3'),
      EdenNavItem(id: 'projects', label: 'Projects', icon: Icons.folder_outlined, activeIcon: Icons.folder),
      EdenNavItem(id: 'calendar', label: 'Calendar', icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today),
    ],
  ),
  const EdenNavItem(
    id: '__manage__',
    label: 'Manage',
    icon: Icons.settings,
    children: [
      EdenNavItem(id: 'team', label: 'Team', icon: Icons.people_outline, activeIcon: Icons.people),
      EdenNavItem(id: 'analytics', label: 'Analytics', icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart),
      EdenNavItem(id: 'settings', label: 'Settings', icon: Icons.settings_outlined, activeIcon: Icons.settings),
    ],
  ),
];

const _user = EdenLayoutUser(
  name: 'Jane Cooper',
  email: 'jane@example.com',
  initials: 'JC',
);

/// Showcase screen for EdenDesktopLayout and EdenMobileLayout.
class LayoutsScreen extends StatefulWidget {
  const LayoutsScreen({super.key});

  @override
  State<LayoutsScreen> createState() => _LayoutsScreenState();
}

/// Top-level preview mode for the Layouts dev screen.
enum _LayoutPreview { desktop, mobile, scaffolds }

class _LayoutsScreenState extends State<LayoutsScreen> {
  _LayoutPreview _preview = _LayoutPreview.desktop;
  String _selectedId = 'dashboard';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Layouts'),
        actions: [
          SegmentedButton<_LayoutPreview>(
            segments: const [
              ButtonSegment(value: _LayoutPreview.desktop, label: Text('Desktop'), icon: Icon(Icons.desktop_windows, size: 16)),
              ButtonSegment(value: _LayoutPreview.mobile, label: Text('Mobile'), icon: Icon(Icons.phone_iphone, size: 16)),
              ButtonSegment(value: _LayoutPreview.scaffolds, label: Text('Scaffolds'), icon: Icon(Icons.view_agenda_outlined, size: 16)),
            ],
            selected: {_preview},
            onSelectionChanged: (v) => setState(() => _preview = v.first),
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 12)),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: switch (_preview) {
        _LayoutPreview.desktop => _desktopPreview(),
        _LayoutPreview.mobile => _mobilePreview(),
        _LayoutPreview.scaffolds => const _ScaffoldsPreview(),
      },
    );
  }

  Widget _desktopPreview() {
    return EdenDesktopLayout(
      navItems: _navItems,
      selectedId: _selectedId,
      onNavChanged: (id) => setState(() => _selectedId = id),
      logo: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.hexagon, size: 24, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Acme App', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ],
      ),
      collapsedLogo: Icon(Icons.hexagon, size: 24, color: Theme.of(context).colorScheme.primary),
      user: _user,
      topBar: EdenTopBarConfig(
        showSearch: true,
        searchHint: 'Search anything…',
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, size: 20),
            onPressed: () {},
          ),
        ],
        trailing: CircleAvatar(
          radius: 16,
          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
          child: Text('JC', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary)),
        ),
      ),
      body: _PageContent(selectedId: _selectedId),
    );
  }

  Widget _mobilePreview() {
    return Container(
      alignment: Alignment.center,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Container(
        width: 390,
        height: 680,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant, width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(size: const Size(390, 680)),
            child: EdenMobileLayout(
              navItems: _navItems,
              selectedId: _selectedId,
              onNavChanged: (id) => setState(() => _selectedId = id),
              user: _user,
              logo: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.hexagon, size: 22, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  const Text('Acme App', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ],
              ),
              topBar: EdenTopBarConfig(
                title: _selectedId[0].toUpperCase() + _selectedId.substring(1),
                actions: [
                  IconButton(icon: const Icon(Icons.notifications_outlined, size: 20), onPressed: () {}),
                ],
                trailing: CircleAvatar(
                  radius: 14,
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                  child: Text('JC', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary)),
                ),
              ),
              body: _PageContent(selectedId: _selectedId),
            ),
          ),
        ),
      ),
    );
  }
}

/// Placeholder content for each "page" in the layout demo.
class _PageContent extends StatelessWidget {
  const _PageContent({required this.selectedId});
  final String selectedId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(EdenSpacing.space4),
      children: [
        // Page header
        EdenPageHeader(
          title: selectedId[0].toUpperCase() + selectedId.substring(1),
          description: 'This is the $selectedId page content area.',
          actions: [
            EdenButton(
              label: 'New Item',
              icon: Icons.add,
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: EdenSpacing.space4),
        // Sample stat cards
        const Wrap(
          spacing: EdenSpacing.space3,
          runSpacing: EdenSpacing.space3,
          children: [
            SizedBox(
              width: 220,
              child: EdenStatCard(
                label: 'Total Users',
                value: '2,847',
                icon: Icons.people,
                trend: EdenStatTrend.up,
                trendValue: '+12.5%',
              ),
            ),
            SizedBox(
              width: 220,
              child: EdenStatCard(
                label: 'Revenue',
                value: '\$48.2k',
                icon: Icons.attach_money,
                trend: EdenStatTrend.up,
                trendValue: '+8.1%',
              ),
            ),
            SizedBox(
              width: 220,
              child: EdenStatCard(
                label: 'Active Projects',
                value: '12',
                icon: Icons.folder,
                trend: EdenStatTrend.neutral,
                trendValue: '0%',
              ),
            ),
          ],
        ),
        const SizedBox(height: EdenSpacing.space4),
        // Placeholder card
        EdenCard(
          child: SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.widgets_outlined, size: 40, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  Text('Content for "$selectedId" goes here', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Scaffolds preview — Wave A cross-vertical scaffolds
// -----------------------------------------------------------------------------

/// Demos the Wave A list/detail scaffolds in a single scrollable panel so
/// `just dev-ui` reveals them under the Layouts category.
class _ScaffoldsPreview extends StatelessWidget {
  const _ScaffoldsPreview();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(EdenSpacing.space4),
      children: [
        Text('EdenListPageScaffold', style: theme.textTheme.titleLarge),
        const SizedBox(height: EdenSpacing.space2),
        Text(
          'Composable list-page scaffold: header + alerts + filters + search + body. '
          'Header stacks vertically when constraints drop below 480pt.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: EdenSpacing.space4),

        const _DemoFrame(
          label: 'Minimal',
          child: SizedBox(
            height: 240,
            child: EdenListPageScaffold(
              title: 'Projects',
              body: Text('Body content'),
            ),
          ),
        ),
        const SizedBox(height: EdenSpacing.space6),

        _DemoFrame(
          label: 'Full composition',
          child: SizedBox(
            height: 520,
            child: EdenListPageScaffold(
              title: 'Customers',
              createLabel: 'New Customer',
              onCreate: () {},
              filterPills: const Wrap(
                spacing: 8,
                children: [
                  Chip(label: Text('Active')),
                  Chip(label: Text('Archived')),
                  Chip(label: Text('VIP')),
                ],
              ),
              searchHint: 'Search customers...',
              onSearchChanged: (_) {},
              alerts: Container(
                padding: const EdgeInsets.all(EdenSpacing.space3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: EdenRadii.borderRadiusMd,
                ),
                child: Text(
                  '1 blocking alert',
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),
              body: ListView(
                children: List.generate(
                  5,
                  (i) => ListTile(
                    leading: const Icon(Icons.business),
                    title: Text('Customer ${i + 1}'),
                    subtitle: Text('Last activity ${i + 1}d ago'),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: EdenSpacing.space6),

        _DemoFrame(
          label: 'Narrow constraint (390pt) — header stacks vertically',
          child: Center(
            child: SizedBox(
              width: 390,
              height: 320,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: EdenRadii.borderRadiusMd,
                ),
                child: EdenListPageScaffold(
                  title: 'Very Long Page Title That Would Overflow',
                  createLabel: 'Create Something With A Long Label',
                  onCreate: () {},
                  body: const Center(child: Text('Body content')),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: EdenSpacing.space8),
        Text('EdenDetailHeader + EdenDetailPageScaffold',
            style: theme.textTheme.titleLarge),
        const SizedBox(height: EdenSpacing.space2),
        Text(
          'Detail-page scaffold: header (breadcrumb + title + badge + actions) → '
          'optional tab bar → body + optional side rail. Side rail collapses to '
          'a "Details" bottom-sheet trigger below 480pt.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: EdenSpacing.space4),

        _DemoFrame(
          label: 'EdenDetailHeader — header only with breadcrumb + actions',
          child: Padding(
            padding: const EdgeInsets.all(EdenSpacing.space4),
            child: EdenDetailHeader(
              title: 'Customer ABC123',
              subtitle: 'Acme HVAC Co.',
              breadcrumb: const ['Customers', 'Active'],
              leading: const Icon(Icons.business),
              statusBadge: const Chip(label: Text('Active')),
              actions: [
                EdenDetailHeaderAction(
                    icon: Icons.star, tooltip: 'Star', onPressed: () {}),
                EdenDetailHeaderAction(
                    icon: Icons.archive,
                    tooltip: 'Archive',
                    onPressed: () {}),
              ],
            ),
          ),
        ),
        const SizedBox(height: EdenSpacing.space6),

        const _DemoFrame(
          label: 'EdenDetailPageScaffold — header only',
          child: SizedBox(
            height: 200,
            child: EdenDetailPageScaffold(
              header: EdenDetailHeader(title: 'Customer ABC123'),
              body: Center(child: Text('Body content')),
            ),
          ),
        ),
        const SizedBox(height: EdenSpacing.space6),

        const _DemoFrame(
          label: 'EdenDetailPageScaffold — with tabs',
          child: SizedBox(
            height: 320,
            child: DefaultTabController(
              length: 3,
              child: EdenDetailPageScaffold(
                header: EdenDetailHeader(title: 'Customer ABC123'),
                tabs: [
                  EdenDetailTab(label: 'Overview'),
                  EdenDetailTab(label: 'Activity'),
                  EdenDetailTab(label: 'Files'),
                ],
                body: TabBarView(
                  children: [
                    Center(child: Text('Overview body')),
                    Center(child: Text('Activity body')),
                    Center(child: Text('Files body')),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: EdenSpacing.space6),

        _DemoFrame(
          label: 'EdenDetailPageScaffold — with side rail (desktop)',
          child: SizedBox(
            height: 320,
            child: EdenDetailPageScaffold(
              header: const EdenDetailHeader(title: 'Customer ABC123'),
              sideRail: _DemoSideRail(theme: theme),
              body: const Center(child: Text('Body content')),
            ),
          ),
        ),
        const SizedBox(height: EdenSpacing.space6),

        _DemoFrame(
          label: 'EdenDetailPageScaffold — narrow (390pt, side rail → Details button)',
          child: Center(
            child: SizedBox(
              width: 390,
              height: 320,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: EdenRadii.borderRadiusMd,
                ),
                child: EdenDetailPageScaffold(
                  header: const EdenDetailHeader(title: 'Customer ABC123'),
                  sideRail: _DemoSideRail(theme: theme),
                  body: const Center(child: Text('Body content')),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Minimal side-rail demo used by the Scaffolds preview.
class _DemoSideRail extends StatelessWidget {
  const _DemoSideRail({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(EdenSpacing.space4),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick stats', style: theme.textTheme.labelLarge),
          const SizedBox(height: EdenSpacing.space2),
          Text('Open work orders: 3',
              style: theme.textTheme.bodySmall),
          const SizedBox(height: 4),
          Text('Outstanding balance: \$1,240',
              style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Captioned frame used by the Scaffolds preview panel.
class _DemoFrame extends StatelessWidget {
  const _DemoFrame({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: EdenSpacing.space2),
        EdenCard(child: child),
      ],
    );
  }
}
