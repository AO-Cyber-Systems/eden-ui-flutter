import 'package:flutter/material.dart';
import '../../eden_ui.dart';
import '../widgets/section.dart';

/// Showcase screen for scaffold and hierarchy components:
/// EdenDetailScaffold, EdenListScaffold, EdenHierarchyTree.
class ScaffoldsScreen extends StatelessWidget {
  const ScaffoldsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scaffolds & Trees')),
      body: ListView(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        children: [
          // ---------------------------------------------------------------
          // Hierarchy Tree
          // ---------------------------------------------------------------
          Section(
            title: 'Hierarchy Tree — 3 Levels',
            child: EdenHierarchyTree(
              nodes: [
                EdenHierarchyNode(
                  id: 'service',
                  label: 'Service',
                  color: Colors.blue,
                  tag: 'System',
                  subtitle: 'types',
                  onAdd: () {},
                  addLabel: 'Type',
                  children: [
                    EdenHierarchyNode(
                      id: 'hvac',
                      label: 'HVAC',
                      subtitle: 'sub-types',
                      onEdit: () {},
                      onDelete: () {},
                      children: [
                        EdenHierarchyNode(
                          id: 'hvac-install',
                          label: 'Installation',
                          onEdit: () {},
                          onDelete: () {},
                        ),
                        EdenHierarchyNode(
                          id: 'hvac-repair',
                          label: 'Repair',
                          onEdit: () {},
                          onDelete: () {},
                        ),
                        EdenHierarchyNode(
                          id: 'hvac-maint',
                          label: 'Maintenance',
                          onEdit: () {},
                          onDelete: () {},
                        ),
                      ],
                    ),
                    EdenHierarchyNode(
                      id: 'plumbing',
                      label: 'Plumbing',
                      subtitle: 'sub-types',
                      onEdit: () {},
                      onDelete: () {},
                      children: [
                        EdenHierarchyNode(
                          id: 'plumb-drain',
                          label: 'Drain Cleaning',
                          onEdit: () {},
                        ),
                      ],
                    ),
                    EdenHierarchyNode(
                      id: 'electrical',
                      label: 'Electrical',
                      onEdit: () {},
                      onDelete: () {},
                    ),
                  ],
                ),
                EdenHierarchyNode(
                  id: 'project',
                  label: 'Project',
                  color: Colors.green,
                  subtitle: 'types',
                  onAdd: () {},
                  addLabel: 'Type',
                  children: [
                    EdenHierarchyNode(
                      id: 'reno',
                      label: 'Renovation',
                      onEdit: () {},
                      onDelete: () {},
                    ),
                    EdenHierarchyNode(
                      id: 'new-const',
                      label: 'New Construction',
                      onEdit: () {},
                      onDelete: () {},
                    ),
                  ],
                ),
                EdenHierarchyNode(
                  id: 'emergency',
                  label: 'Emergency',
                  color: Colors.red,
                  tag: 'System',
                  subtitle: 'types',
                  children: [
                    EdenHierarchyNode(
                      id: 'water-damage',
                      label: 'Water Damage',
                      icon: Icons.water_damage,
                    ),
                    EdenHierarchyNode(
                      id: 'gas-leak',
                      label: 'Gas Leak',
                      icon: Icons.local_fire_department,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const EdenDivider(label: 'Detail Scaffold'),

          // ---------------------------------------------------------------
          // Detail Scaffold (embedded in a constrained box)
          // ---------------------------------------------------------------
          Section(
            title: 'Detail Scaffold — Tabbed Layout',
            child: Container(
              height: 350,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                borderRadius: EdenRadii.borderRadiusLg,
              ),
              clipBehavior: Clip.antiAlias,
              child: EdenDetailScaffold(
                header: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Smith Residence HVAC Install',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '123 Main St, Springfield',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    const EdenStatusBadge(status: 'in_progress'),
                  ],
                ),
                tabs: [
                  EdenDetailTab(
                    label: 'Work',
                    content: Center(
                      child: Text('Work tab content',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  ),
                  EdenDetailTab(
                    label: 'Contacts',
                    count: 5,
                    content: Center(
                      child: Text('Contacts tab content',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  ),
                  EdenDetailTab(
                    label: 'Documents',
                    count: 12,
                    content: Center(
                      child: Text('Documents tab content',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const EdenDivider(label: 'List Scaffold'),

          // ---------------------------------------------------------------
          // List Scaffold (embedded in a constrained box)
          // ---------------------------------------------------------------
          Section(
            title: 'List Scaffold — With Filters & Search',
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                borderRadius: EdenRadii.borderRadiusLg,
              ),
              clipBehavior: Clip.antiAlias,
              child: EdenListScaffold(
                title: 'Projects',
                createButtonLabel: 'Create Project',
                onCreatePressed: () {},
                searchHint: 'Search projects...',
                onSearchChanged: (_) {},
                filterPills: EdenFilterChipRow<String>(
                  options: const [
                    EdenFilterOption(label: 'Active', value: 'active'),
                    EdenFilterOption(label: 'Completed', value: 'completed'),
                    EdenFilterOption(label: 'On Hold', value: 'on_hold'),
                  ],
                  selected: null,
                  onSelected: (_) {},
                ),
                body: Center(
                  child: EdenEmptyState(
                    icon: Icons.folder_open,
                    title: 'No projects',
                    description: 'Create your first project to get started.',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
