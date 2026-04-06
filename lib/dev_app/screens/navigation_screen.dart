import 'package:flutter/material.dart';
import '../../eden_ui.dart';
import '../widgets/interactive_controls.dart';
import '../widgets/section.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Navigation')),
      body: ListView(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        children: [
          InteractivePlayground(
            title: 'Tab Explorer',
            preview: EdenTabs(
              tabs: const [
                EdenTabItem(label: 'Overview'),
                EdenTabItem(label: 'Details'),
                EdenTabItem(label: 'Settings'),
              ],
              selectedIndex: _tabIndex % 3,
              onChanged: (i) => setState(() => _tabIndex = i),
            ),
            controls: [
              Text('Tap tabs to change selection', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: EdenSpacing.space4),
          // Tabs
          Section(
            title: 'Tabs',
            child: Column(
              children: [
                EdenTabs(
                  tabs: const [
                    EdenTabItem(label: 'All', badge: '24'),
                    EdenTabItem(label: 'Active', icon: Icons.check_circle_outline),
                    EdenTabItem(label: 'Archived'),
                    EdenTabItem(label: 'Drafts', badge: '3'),
                  ],
                  selectedIndex: _tabIndex,
                  onChanged: (i) => setState(() => _tabIndex = i),
                ),
                const SizedBox(height: 16),
                EdenCard(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(EdenSpacing.space8),
                      child: Text('Tab ${_tabIndex + 1} content'),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Stepper
          Section(
            title: 'Stepper',
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: EdenSpacing.space4),
              child: EdenStepper(
                steps: const [
                  EdenStepItem(label: 'Account', status: EdenStepStatus.complete),
                  EdenStepItem(label: 'Company', status: EdenStepStatus.complete),
                  EdenStepItem(label: 'Billing', status: EdenStepStatus.current),
                  EdenStepItem(label: 'Review', status: EdenStepStatus.upcoming),
                ],
              ),
            ),
          ),

          // List Group
          Section(
            title: 'List Group',
            child: EdenListGroup(
              items: [
                EdenListGroupItem(
                  title: 'Conversations',
                  leading: Icon(Icons.chat_bubble_outline, size: 18, color: Theme.of(context).colorScheme.primary),
                  trailing: const EdenBadge(label: '12', size: EdenBadgeSize.sm, variant: EdenBadgeVariant.primary),
                  active: true,
                  onTap: () {},
                ),
                EdenListGroupItem(
                  title: 'Personas',
                  leading: Icon(Icons.person_outline, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  onTap: () {},
                ),
                EdenListGroupItem(
                  title: 'Projects',
                  subtitle: 'Organize your work',
                  leading: Icon(Icons.folder_outlined, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  onTap: () {},
                ),
                EdenListGroupItem(
                  title: 'Settings',
                  leading: Icon(Icons.settings_outlined, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  trailing: Icon(Icons.chevron_right, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  onTap: () {},
                ),
              ],
            ),
          ),

          // Accordion
          Section(
            title: 'Accordion',
            child: EdenAccordion(
              items: [
                EdenAccordionItem(
                  title: 'What is Eden UI?',
                  icon: Icons.help_outline,
                  content: Text(
                    'Eden UI is a comprehensive component library that provides consistent, '
                    'beautiful UI elements for building modern applications.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                EdenAccordionItem(
                  title: 'How do I use it in Flutter?',
                  icon: Icons.code,
                  content: Text(
                    'Import the eden_ui package and use the widgets directly. '
                    'The theme is set up via EdenTheme.light() and EdenTheme.dark().',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                EdenAccordionItem(
                  title: 'Can I customize the brand color?',
                  content: Text(
                    'Yes! Use the brand color picker to switch between gold, blue, '
                    'emerald, purple, red, and slate presets.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search Input
          Section(
            title: 'Search Input',
            child: EdenSearchInput(
              hint: 'Search conversations...',
              onClear: () {},
            ),
          ),
        ],
      ),
    );
  }
}
