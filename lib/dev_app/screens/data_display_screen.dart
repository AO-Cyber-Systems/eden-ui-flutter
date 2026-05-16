import 'package:flutter/material.dart';
import '../../eden_ui.dart';
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
          const Section(
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
                    SizedBox(width: 12),
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
                SizedBox(height: 12),
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
                    SizedBox(width: 12),
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
          const Section(
            title: 'Description List',
            child: EdenCard(
              child: EdenDescriptionList(
                items: [
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

          // Currency Display (Wave A — Cross-vertical primitives)
          const Section(
            title: 'Currency Display',
            child: EdenCard(
              child: Padding(
                padding: EdgeInsets.all(EdenSpacing.space3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Default (USD)'),
                    EdenCurrencyDisplay(cents: 12500),
                    SizedBox(height: 8),
                    Text('Negative'),
                    EdenCurrencyDisplay(cents: -5000),
                    SizedBox(height: 8),
                    Text('Show sign'),
                    EdenCurrencyDisplay(cents: 5000, showSign: true),
                    SizedBox(height: 8),
                    Text('No cents'),
                    EdenCurrencyDisplay(cents: 5000, showCents: false),
                    SizedBox(height: 8),
                    Text('Thousands'),
                    EdenCurrencyDisplay(cents: 1234500),
                    SizedBox(height: 8),
                    Text('EUR'),
                    EdenCurrencyDisplay(cents: 12500, currencyCode: 'EUR'),
                    SizedBox(height: 8),
                    Text('GBP'),
                    EdenCurrencyDisplay(cents: 12500, currencyCode: 'GBP'),
                    SizedBox(height: 8),
                    Text('Colorize positive'),
                    EdenCurrencyDisplay(cents: 5000, colorize: true),
                    SizedBox(height: 8),
                    Text('Colorize negative'),
                    EdenCurrencyDisplay(cents: -5000, colorize: true),
                  ],
                ),
              ),
            ),
          ),

          // EdenAuthenticatedImage demo (Wave A primitive)
          const Section(
            title: 'Authenticated Image (Wave A)',
            child: EdenCard(
              child: Padding(
                padding: EdgeInsets.all(EdenSpacing.space3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Headers map (e.g., Bearer + X-Tenant for signed URLs) '
                      'is forwarded to NetworkImage. Library does NOT generate '
                      'the token — downstream apps inject via callback.',
                      style: TextStyle(fontSize: 12),
                    ),
                    SizedBox(height: 12),
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: EdenAuthenticatedImage(
                        // Catalog uses a public image so the demo renders without
                        // a backend; in production a signed-URL endpoint would be used.
                        url: 'https://picsum.photos/seed/eden/240/240',
                        headers: {
                          'Authorization': 'Bearer demo-token',
                          'X-Tenant': 'tenant-demo',
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Offline Queue Viewer (Wave A)
          Section(
            title: 'Offline Queue Viewer — empty',
            child: SizedBox(
              height: 220,
              child: EdenCard(
                child: EdenOfflineQueueViewer(
                  items: const <EdenOfflineQueueItem>[],
                ),
              ),
            ),
          ),

          Section(
            title: 'Offline Queue Viewer — mixed (5 items, all statuses)',
            child: SizedBox(
              height: 560,
              child: EdenCard(
                child: EdenOfflineQueueViewer(
                  items: <EdenOfflineQueueItem>[
                    EdenOfflineQueueItem(
                      id: 'd1',
                      actionType: 'Update Customer',
                      summary: 'Customer ABC123: phone → 555-0100',
                      queuedAt: DateTime.now()
                          .subtract(const Duration(seconds: 20)),
                    ),
                    EdenOfflineQueueItem(
                      id: 'd2',
                      actionType: 'Create Work Order',
                      summary: 'New WO for customer ABC123 — leaky faucet',
                      queuedAt: DateTime.now()
                          .subtract(const Duration(minutes: 5)),
                    ),
                    EdenOfflineQueueItem(
                      id: 'd3',
                      actionType: 'Update Invoice',
                      summary: 'Invoice INV-9012 status → paid',
                      queuedAt:
                          DateTime.now().subtract(const Duration(hours: 2)),
                      status: EdenOfflineQueueItemStatus.syncing,
                    ),
                    EdenOfflineQueueItem(
                      id: 'd4',
                      actionType: 'Update Customer',
                      summary: 'Customer XYZ987: address conflict',
                      queuedAt:
                          DateTime.now().subtract(const Duration(days: 1)),
                      status: EdenOfflineQueueItemStatus.conflict,
                      conflictDescription:
                          'Server has a newer address. Pick one.',
                    ),
                    EdenOfflineQueueItem(
                      id: 'd5',
                      actionType: 'Create Photo',
                      summary: 'Attach roof.jpg to WO-4455',
                      queuedAt:
                          DateTime.now().subtract(const Duration(days: 3)),
                      status: EdenOfflineQueueItemStatus.error,
                      errorMessage: '413: payload too large',
                    ),
                  ],
                  onRetry: (_) {},
                  onDiscard: (_) {},
                  onResolveConflict: (_) {},
                ),
              ),
            ),
          ),

          const EdenDivider(label: 'EdenStockLevelIndicator — Phase 1 (objective 003)'),
          const Section(
            title: 'Capacity gauge — green / amber / red',
            child: Column(
              children: [
                _StockSample(
                  caption: 'currentStock=80, reorderPoint=50 → green',
                  indicator: EdenStockLevelIndicator(
                    currentStock: 80,
                    reorderPoint: 50,
                  ),
                ),
                SizedBox(height: 12),
                _StockSample(
                  caption: 'currentStock=35, reorderPoint=0 → amber',
                  indicator: EdenStockLevelIndicator(
                    currentStock: 35,
                    reorderPoint: 0,
                  ),
                ),
                SizedBox(height: 12),
                _StockSample(
                  caption:
                      'currentStock=50, reorderPoint=100 → red (isBelowReorder)',
                  indicator: EdenStockLevelIndicator(
                    currentStock: 50,
                    reorderPoint: 100,
                  ),
                ),
                SizedBox(height: 12),
                _StockSample(
                  caption:
                      'currentStock=5, reorderPoint=0 → red (percent<0.25)',
                  indicator: EdenStockLevelIndicator(
                    currentStock: 5,
                    reorderPoint: 0,
                  ),
                ),
                SizedBox(height: 12),
                _StockSample(
                  caption: 'showLabel=false, height=16',
                  indicator: EdenStockLevelIndicator(
                    currentStock: 60,
                    reorderPoint: 50,
                    showLabel: false,
                    height: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StockSample extends StatelessWidget {
  const _StockSample({required this.caption, required this.indicator});

  final String caption;
  final EdenStockLevelIndicator indicator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(caption, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        indicator,
      ],
    );
  }
}
