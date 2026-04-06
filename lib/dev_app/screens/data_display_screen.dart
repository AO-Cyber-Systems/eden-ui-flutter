import 'package:flutter/material.dart';
import '../../eden_ui.dart';
import '../widgets/interactive_controls.dart';
import '../widgets/section.dart';

class DataDisplayScreen extends StatefulWidget {
  const DataDisplayScreen({super.key});

  @override
  State<DataDisplayScreen> createState() => _DataDisplayScreenState();
}

class _DataDisplayScreenState extends State<DataDisplayScreen> {
  int _paginationPage = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Display')),
      body: ListView(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        children: [
          // Stat Cards
          Section(
            title: 'Stat Cards',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: EdenStatCard(
                        label: 'Total Revenue',
                        value: '\$45,231',
                        icon: Icons.attach_money,
                        trend: EdenStatTrend.up,
                        trendValue: '+12.5%',
                        trendLabel: 'vs last month',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: EdenStatCard(
                        label: 'Active Users',
                        value: '2,345',
                        icon: Icons.people_outline,
                        trend: EdenStatTrend.up,
                        trendValue: '+8.2%',
                        variant: EdenColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: EdenStatCard(
                        label: 'Bounce Rate',
                        value: '24.5%',
                        icon: Icons.trending_down,
                        trend: EdenStatTrend.down,
                        trendValue: '-3.1%',
                        variant: EdenColors.error,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: EdenStatCard(
                        label: 'Avg. Session',
                        value: '4m 32s',
                        icon: Icons.timer_outlined,
                        trend: EdenStatTrend.neutral,
                        trendValue: '0%',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Data Table
          Section(
            title: 'Data Table',
            child: EdenDataTable(
              columns: const [
                EdenTableColumn(label: 'Name', flex: 2),
                EdenTableColumn(label: 'Role'),
                EdenTableColumn(label: 'Status'),
              ],
              rows: [
                EdenTableRow(cells: [
                  Text('Alice Johnson', style: Theme.of(context).textTheme.bodyMedium),
                  Text('Admin', style: Theme.of(context).textTheme.bodySmall),
                  const EdenBadge(label: 'Active', variant: EdenBadgeVariant.success, size: EdenBadgeSize.sm),
                ]),
                EdenTableRow(cells: [
                  Text('Bob Smith', style: Theme.of(context).textTheme.bodyMedium),
                  Text('Editor', style: Theme.of(context).textTheme.bodySmall),
                  const EdenBadge(label: 'Active', variant: EdenBadgeVariant.success, size: EdenBadgeSize.sm),
                ]),
                EdenTableRow(cells: [
                  Text('Carol White', style: Theme.of(context).textTheme.bodyMedium),
                  Text('Viewer', style: Theme.of(context).textTheme.bodySmall),
                  const EdenBadge(label: 'Pending', variant: EdenBadgeVariant.warning, size: EdenBadgeSize.sm),
                ]),
                EdenTableRow(cells: [
                  Text('Dave Brown', style: Theme.of(context).textTheme.bodyMedium),
                  Text('Admin', style: Theme.of(context).textTheme.bodySmall),
                  const EdenBadge(label: 'Suspended', variant: EdenBadgeVariant.danger, size: EdenBadgeSize.sm),
                ]),
              ],
              striped: true,
            ),
          ),

          // Description List
          Section(
            title: 'Description List',
            child: EdenCard(
              child: EdenDescriptionList(
                items: const [
                  EdenDescriptionItem(label: 'Full Name', value: 'Justin Doe'),
                  EdenDescriptionItem(label: 'Email', value: 'justin@example.com'),
                  EdenDescriptionItem(label: 'Role', value: 'Administrator'),
                  EdenDescriptionItem(label: 'Status', value: 'Active'),
                  EdenDescriptionItem(label: 'Joined', value: 'March 1, 2024'),
                ],
              ),
            ),
          ),

          // Pagination
          Section(
            title: 'Pagination',
            child: EdenPagination(
              currentPage: _paginationPage,
              totalPages: 12,
              onPageChanged: (page) => setState(() => _paginationPage = page),
            ),
          ),

          // Empty State
          Section(
            title: 'Empty State',
            child: EdenCard(
              child: EdenEmptyState(
                title: 'No conversations yet',
                description: 'Start a new conversation to get going.',
                icon: Icons.chat_bubble_outline,
                actionLabel: 'New Conversation',
                onAction: () {},
              ),
            ),
          ),
        ],
      ),
    );
  }
}
