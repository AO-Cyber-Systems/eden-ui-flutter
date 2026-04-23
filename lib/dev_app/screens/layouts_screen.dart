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

class _LayoutsScreenState extends State<LayoutsScreen> {
  bool _showMobile = false;
  String _selectedId = 'dashboard';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Layouts'),
        actions: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Desktop'), icon: Icon(Icons.desktop_windows, size: 16)),
              ButtonSegment(value: true, label: Text('Mobile'), icon: Icon(Icons.phone_iphone, size: 16)),
            ],
            selected: {_showMobile},
            onSelectionChanged: (v) => setState(() => _showMobile = v.first),
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 12)),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: _showMobile ? _mobilePreview() : _desktopPreview(),
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
