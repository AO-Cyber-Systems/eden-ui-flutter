import 'package:flutter/material.dart';
import '../../eden_ui.dart';
import 'buttons_screen.dart';
import 'cards_screen.dart';
import 'badges_alerts_screen.dart';
import 'inputs_screen.dart';
import 'avatars_screen.dart';
import 'misc_screen.dart';
import 'colors_screen.dart';
import 'typography_screen.dart';
import 'data_display_screen.dart';
import 'navigation_screen.dart';
import 'overlays_screen.dart';
import 'settings_screen.dart';
import 'chat_screen.dart';
import 'compound_screen.dart';
import 'diagram_screen.dart';
import 'layouts_screen.dart';
import 'devflow_infra_screen.dart';
import 'devflow_project_screen.dart';
import 'devflow_tools_screen.dart';
import 'trades_screen.dart';

/// Root screen showing all component categories.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.themeMode,
    required this.brandColor,
    required this.onToggleTheme,
    required this.onBrandColorChanged,
  });

  final ThemeMode themeMode;
  final MaterialColor brandColor;
  final VoidCallback onToggleTheme;
  final ValueChanged<MaterialColor> onBrandColorChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eden UI'),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: onToggleTheme,
            tooltip: 'Toggle theme',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        children: [
          // Brand color picker
          _BrandColorPicker(
            selected: brandColor,
            onChanged: onBrandColorChanged,
          ),
          const SizedBox(height: EdenSpacing.space6),

          // Component categories
          ..._categories.map((cat) => Padding(
            padding: const EdgeInsets.only(bottom: EdenSpacing.space3),
            child: _CategoryTile(
              icon: cat.icon,
              title: cat.title,
              subtitle: cat.subtitle,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => cat.builder(context)),
              ),
            ),
          )),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Brand color picker row
// -----------------------------------------------------------------------------

class _BrandColorPicker extends StatelessWidget {
  const _BrandColorPicker({required this.selected, required this.onChanged});

  final MaterialColor selected;
  final ValueChanged<MaterialColor> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return EdenCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Brand Color', style: theme.textTheme.labelLarge),
          const SizedBox(height: EdenSpacing.space3),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: EdenColors.presets.entries.map((entry) {
              final isSelected = entry.value == selected;
              return GestureDetector(
                onTap: () => onChanged(entry.value),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: entry.value,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: theme.colorScheme.onSurface, width: 3)
                        : null,
                  ),
                  child: isSelected
                      ? Icon(Icons.check, size: 18, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Category tile
// -----------------------------------------------------------------------------

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return EdenCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: EdenRadii.borderRadiusLg,
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 22),
          ),
          const SizedBox(width: EdenSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Category definitions
// -----------------------------------------------------------------------------

class _Category {
  const _Category({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.builder,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget Function(BuildContext) builder;
}

final _categories = [
  _Category(
    icon: Icons.palette_outlined,
    title: 'Colors',
    subtitle: 'Brand presets, neutrals, status colors',
    builder: (_) => const ColorsScreen(),
  ),
  _Category(
    icon: Icons.text_fields,
    title: 'Typography',
    subtitle: 'Display, heading, body, label, code styles',
    builder: (_) => const TypographyScreen(),
  ),
  _Category(
    icon: Icons.smart_button,
    title: 'Buttons',
    subtitle: 'Variants, sizes, outlines, pills, icons',
    builder: (_) => const ButtonsScreen(),
  ),
  _Category(
    icon: Icons.credit_card,
    title: 'Cards',
    subtitle: 'Standard, gradient, glass variants',
    builder: (_) => const CardsScreen(),
  ),
  _Category(
    icon: Icons.label_outline,
    title: 'Badges & Alerts',
    subtitle: 'Status badges, alert banners',
    builder: (_) => const BadgesAlertsScreen(),
  ),
  _Category(
    icon: Icons.text_snippet_outlined,
    title: 'Inputs',
    subtitle: 'Text fields, toggles, form controls',
    builder: (_) => const InputsScreen(),
  ),
  _Category(
    icon: Icons.account_circle_outlined,
    title: 'Avatars',
    subtitle: 'Images, initials, status indicators',
    builder: (_) => const AvatarsScreen(),
  ),
  _Category(
    icon: Icons.widgets_outlined,
    title: 'Misc',
    subtitle: 'Progress, spinner, skeleton, divider, tooltip',
    builder: (_) => const MiscScreen(),
  ),
  _Category(
    icon: Icons.bar_chart,
    title: 'Data Display',
    subtitle: 'Stat cards, tables, description lists, pagination',
    builder: (_) => const DataDisplayScreen(),
  ),
  _Category(
    icon: Icons.menu_open,
    title: 'Navigation',
    subtitle: 'Tabs, stepper, list group, accordion, search',
    builder: (_) => const NavigationScreen(),
  ),
  _Category(
    icon: Icons.layers_outlined,
    title: 'Overlays',
    subtitle: 'Modal, drawer, toast, banner, dropdown',
    builder: (_) => const OverlaysScreen(),
  ),
  _Category(
    icon: Icons.settings_outlined,
    title: 'Settings Pattern',
    subtitle: 'Settings sections, page/section headers, select',
    builder: (_) => const SettingsScreen(),
  ),
  _Category(
    icon: Icons.chat_outlined,
    title: 'Chat',
    subtitle: 'Chat bubbles with sender styles and avatars',
    builder: (_) => const ChatScreen(),
  ),
  _Category(
    icon: Icons.dashboard_outlined,
    title: 'Compound',
    subtitle: 'Kanban, calendar, timeline, carousel, code blocks',
    builder: (_) => const CompoundScreen(),
  ),
  _Category(
    icon: Icons.account_tree_outlined,
    title: 'Diagram / Flow',
    subtitle: 'Interactive flowcharts, JSON-backed, AI-generatable',
    builder: (_) => const DiagramScreen(),
  ),
  _Category(
    icon: Icons.view_sidebar_outlined,
    title: 'Layouts',
    subtitle: 'Desktop sidebar + mobile bottom nav shells',
    builder: (_) => const LayoutsScreen(),
  ),
  _Category(
    icon: Icons.dns_outlined,
    title: 'DevFlow — Infrastructure',
    subtitle: 'Services, ports, domains, certs, health checks',
    builder: (_) => const DevflowInfraScreen(),
  ),
  _Category(
    icon: Icons.rocket_launch_outlined,
    title: 'DevFlow — Projects & Workflow',
    subtitle: 'Project cards, objectives, stepper, logs, terminal',
    builder: (_) => const DevflowProjectScreen(),
  ),
  _Category(
    icon: Icons.build_outlined,
    title: 'DevFlow — Tools & Config',
    subtitle: 'Accounts, packages, env editor, email, polling',
    builder: (_) => const DevflowToolsScreen(),
  ),
  _Category(
    icon: Icons.construction_outlined,
    title: 'Trades — Enterprise Components',
    subtitle: 'Scheduler, approvals, checklists, maps, sync, signatures',
    builder: (_) => const TradesScreen(),
  ),
];
