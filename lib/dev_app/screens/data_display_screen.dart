import 'package:flutter/material.dart';
import '../../eden_ui.dart';
import '../_sample_data/sample_data.dart';
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
          // -----------------------------------------------------------------
          // Objective 008 Wave 2 (TRD 008-03) — cross-vertical enrichment.
          // Pulls fixtures from lib/dev_app/_sample_data/. NO inline records.
          // -----------------------------------------------------------------
          const EdenDivider(label: 'Cross-vertical KPIs'),
          const Section(
            title: 'Trades dispatch KPIs',
            child: _TradesDispatchStatGrid(),
          ),
          const Section(
            title: 'Salon front-desk KPIs',
            child: _SalonFrontDeskStatGrid(),
          ),
          const Section(
            title: 'Fuel fleet KPIs',
            child: _FuelFleetStatGrid(),
          ),
          const Section(
            title: 'Medical clinic KPIs',
            child: _MedicalClinicStatGrid(),
          ),
          const Section(
            title: 'Gov caseworker KPIs',
            child: _GovCaseworkerStatGrid(),
          ),
          const Section(
            title: 'Edge — Zero-value stat card',
            child: _ZeroValueStatCardDemo(),
          ),

          const EdenDivider(label: 'Realistic tables'),
          const Section(
            title: 'Trades — jobs this week (8 columns)',
            child: _TradesJobsTableDemo(),
          ),
          const Section(
            title: 'Salon — client roster',
            child: _SalonClientsTableDemo(),
          ),
          const Section(
            title: 'Fuel — deliveries this week',
            child: _FuelDeliveriesTableDemo(),
          ),
          const Section(
            title: 'Medical — visits this week',
            child: _MedicalVisitsTableDemo(),
          ),
          const Section(
            title: 'Edge — Empty table',
            child: _EmptyTableDemo(),
          ),
          const Section(
            title: 'Edge — Single row',
            child: _SingleRowTableDemo(),
          ),
          const Section(
            title: 'Edge — Overflow (50 rows)',
            child: _OverflowTableDemo(),
          ),

          const EdenDivider(label: 'Cost summaries'),
          const Section(
            title: 'Trades — job cost summary',
            child: _TradesCostSummaryDemo(),
          ),
          const Section(
            title: 'Fuel — delivery cost summary',
            child: _FuelCostSummaryDemo(),
          ),
          const Section(
            title: 'Medical — visit cost summary',
            child: _MedicalCostSummaryDemo(),
          ),

          const EdenDivider(label: 'Mixed activity feed'),
          const Section(
            title: 'Cross-vertical activity (10 events)',
            child: _MixedActivityFeedDemo(),
          ),
          const Section(
            title: 'Single-event minimal',
            child: _SingleActivityItemDemo(),
          ),

          const EdenDivider(label: 'Media rows'),
          const Section(
            title: 'Trades — photos / videos / docs',
            child: _TradesMediaRowDemo(),
          ),
          const Section(
            title: 'Salon — before / after / products',
            child: _SalonMediaRowDemo(),
          ),
          const Section(
            title: 'Medical — imaging / labs / referrals',
            child: _MedicalMediaRowDemo(),
          ),

          const EdenDivider(label: 'Fuel tank stock levels'),
          const Section(
            title: 'Tank levels (green / amber / red)',
            child: _FuelTankLevelsDemo(),
          ),

          // -----------------------------------------------------------------
          // Pre-existing demos (generic placeholders) — kept for back-compat.
          // -----------------------------------------------------------------
          const EdenDivider(label: 'Generic / placeholder demos (legacy)'),

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

          const EdenDivider(label: 'EdenCostSummaryCard — Phase 1 (objective 003)'),
          const Section(
            title: 'Default 3-row breakdown',
            child: EdenCostSummaryCard(
              laborCents: 120000,
              materialCents: 45000,
              equipmentCents: 25000,
            ),
          ),
          const Section(
            title: 'With extraRows — note total still excludes them',
            child: EdenCostSummaryCard(
              laborCents: 120000,
              materialCents: 45000,
              equipmentCents: 25000,
              extraRows: [
                EdenCostRow(label: 'Subcontractor', cents: 50000),
                EdenCostRow(label: 'Permits', cents: 7500),
              ],
            ),
          ),
          const Section(
            title: 'Custom title — Project Budget',
            child: EdenCostSummaryCard(
              laborCents: 50000,
              materialCents: 25000,
              equipmentCents: 10000,
              title: 'Project Budget',
            ),
          ),

          const EdenDivider(label: 'EdenActivityFeedItem — Phase 1 (objective 003)'),
          const Section(
            title: 'Activity feed (4 variants + tappable + long-entity wrap)',
            child: Column(
              children: [
                EdenActivityFeedItem(
                  item: EdenActivityFeedItemData(
                    actorName: 'John Smith',
                    actorInitials: 'JS',
                    action: 'created',
                    entityName: 'Customer #42',
                    timeAgo: '5m ago',
                    variant: EdenActivityVariant.success,
                  ),
                ),
                EdenActivityFeedItem(
                  item: EdenActivityFeedItemData(
                    actorName: 'Maria Garcia',
                    actorInitials: 'MG',
                    action: 'flagged',
                    entityName: 'Invoice #1029',
                    timeAgo: '12m ago',
                    variant: EdenActivityVariant.warning,
                  ),
                ),
                EdenActivityFeedItem(
                  item: EdenActivityFeedItemData(
                    actorName: 'Alex Park',
                    actorInitials: 'AP',
                    action: 'deleted',
                    entityName: 'Project Atlas',
                    timeAgo: '1h ago',
                    variant: EdenActivityVariant.danger,
                  ),
                ),
                EdenActivityFeedItem(
                  item: EdenActivityFeedItemData(
                    actorName: 'Dev Bot',
                    actorInitials: 'DB',
                    action: 'commented on',
                    entityName: 'Ticket T-501',
                    timeAgo: 'just now',
                    variant: EdenActivityVariant.info,
                  ),
                ),
                EdenActivityFeedItem(
                  item: EdenActivityFeedItemData(
                    actorName: 'Long Name',
                    actorInitials: 'LN',
                    action: 'updated',
                    entityName:
                        'A really long entity name that should ellipsize gracefully on narrow viewports',
                    timeAgo: 'yesterday',
                    variant: EdenActivityVariant.info,
                  ),
                ),
              ],
            ),
          ),

          const EdenDivider(label: 'EdenMediaRow — Phase 1 (objective 003)'),
          Section(
            title: '3-cell media row (photos + docs + budget)',
            child: EdenMediaRow(items: [
              EdenMediaRowItem(
                icon: Icons.camera_alt,
                label: 'photos',
                count: '7',
                onAddPressed: () {},
              ),
              EdenMediaRowItem(
                icon: Icons.description,
                label: 'documents',
                count: '3',
                onAddPressed: () {},
              ),
              const EdenMediaRowItem(
                icon: Icons.attach_money,
                label: 'budget',
                count: r'$24,500',
                trailingText: '1 CO',
              ),
            ]),
          ),
          const Section(
            title: 'Label-only (no count, no trailing)',
            child: EdenMediaRow(items: [
              EdenMediaRowItem(icon: Icons.star, label: 'favorited'),
            ]),
          ),
          const Section(
            title: 'EdenDataTable.dense — Density + sticky + freeze + bulk-select (Obj 010)',
            child: _DenseDispatchDemo(),
          ),
        ],
      ),
    );
  }
}

class _DenseDispatchDemo extends StatefulWidget {
  const _DenseDispatchDemo();

  @override
  State<_DenseDispatchDemo> createState() => _DenseDispatchDemoState();
}

class _DenseDispatchDemoState extends State<_DenseDispatchDemo> {
  Set<int> _selected = {};
  bool _freezeFirst = true;

  // Hand-built fixture — Do NOT regenerate via LLM.
  // 8 representative trades dispatch rows; the dense demo extends them to 40
  // via index-based repeats to demonstrate scroll perf without LLM-generated
  // bulk data.
  static const List<List<String>> _seedRows = [
    ['JOB-4291', 'Acme Plumbing', '1247 Oak St',  'Crew A', 'In Progress', '09:00', 'High'],
    ['JOB-4292', 'Bright Lights', '88 Maple Ave', 'Crew B', 'Scheduled',   '10:30', 'Med'],
    ['JOB-4293', 'Cleanline LLC', '15 River Rd',  'Crew C', 'En route',    '11:00', 'High'],
    ['JOB-4294', 'Delta Cooling', '900 Pine St',  'Crew A', 'Complete',    '08:00', 'Low'],
    ['JOB-4295', 'Echo HVAC',     '300 Elm Pl',   'Crew B', 'Blocked',     '12:00', 'High'],
    ['JOB-4296', 'Falcon Roofing','55 Birch Ln',  'Crew D', 'Scheduled',   '13:30', 'Med'],
    ['JOB-4297', 'Granite Group', '21 Cedar Ct',  'Crew A', 'In Progress', '14:00', 'Low'],
    ['JOB-4298', 'Helix Glass',   '999 Spruce',   'Crew C', 'Scheduled',   '15:00', 'High'],
  ];

  List<EdenTableRow> _buildRows() {
    return List.generate(40, (i) {
      final seed = _seedRows[i % _seedRows.length];
      return EdenTableRow(cells: seed.map((s) => Text(s, overflow: TextOverflow.ellipsis)).toList());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(child: Padding(
      padding: const EdgeInsets.all(EdenSpacing.space4),
      child: Column(children: [
        Row(children: [
          Text('${_selected.length} selected'),
          const Spacer(),
          Switch(value: _freezeFirst, onChanged: (v) => setState(() => _freezeFirst = v)),
          const SizedBox(width: 4),
          const Text('Freeze first column'),
        ]),
        const SizedBox(height: EdenSpacing.space2),
        SizedBox(
          height: 400,
          child: EdenDataTable.dense(
            columns: const [
              EdenTableColumn(label: 'Job #'),
              EdenTableColumn(label: 'Customer', flex: 2),
              EdenTableColumn(label: 'Address', flex: 2),
              EdenTableColumn(label: 'Crew'),
              EdenTableColumn(label: 'Status'),
              EdenTableColumn(label: 'Scheduled'),
              EdenTableColumn(label: 'Priority'),
            ],
            rows: _buildRows(),
            freezeFirstColumn: _freezeFirst,
            bulkSelectable: true,
            selectedRowIndices: _selected,
            onSelectionChanged: (s) => setState(() => _selected = s),
            striped: true,
          ),
        ),
      ]),
    ));
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

// =============================================================================
// Objective 008 Wave 2 (TRD 008-03) — cross-vertical demos for the
// data-display catalog screen. Fixtures from lib/dev_app/_sample_data/.
//
// SCOPE: Demo-only. ZERO modifications to lib/src/widgets/.
// =============================================================================

// -----------------------------------------------------------------------------
// EdenStatCard — 5 vertical KPI grids + edge demo
//
// Helper: render a list of stat cards as a 2-column grid on Medium+ widths
// (≥480pt) and as a single-column stack on narrow widths (<480pt). Uses Wrap
// so cards naturally wrap; avoids GridView aspect-ratio overflow at 195pt.
// -----------------------------------------------------------------------------

Widget _statGridResponsive(List<Widget> cards) {
  return LayoutBuilder(
    builder: (context, c) {
      // Two columns above 480pt (gives ~228pt/card); single column below.
      final wideEnough = c.maxWidth >= 480;
      final cardWidth = wideEnough ? (c.maxWidth - 12) / 2 : c.maxWidth;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: <Widget>[
          for (final card in cards)
            SizedBox(width: cardWidth, child: card),
        ],
      );
    },
  );
}

class _TradesDispatchStatGrid extends StatelessWidget {
  const _TradesDispatchStatGrid();

  @override
  Widget build(BuildContext context) {
    final openJobs =
        TradesScenarios.weekEvents.where((e) => e.status != 'completed').length;
    return _statGridResponsive(<Widget>[
        EdenStatCard(
          label: 'Open jobs (week)',
          value: '$openJobs',
          icon: Icons.build,
          trend: EdenStatTrend.up,
          trendValue: '+3 vs last week',
        ),
        const EdenStatCard(
          label: 'Truck utilization',
          value: '87%',
          icon: Icons.local_shipping_outlined,
          variant: EdenColors.success,
        ),
        const EdenStatCard(
          label: 'Callbacks (week)',
          value: '2',
          icon: Icons.refresh,
          variant: EdenColors.warning,
        ),
        const EdenStatCard(
          label: 'Avg job revenue',
          value: r'$1,028',
          icon: Icons.attach_money,
          trend: EdenStatTrend.up,
          trendValue: '+\$74',
        ),
      ],
    );
  }
}

class _SalonFrontDeskStatGrid extends StatelessWidget {
  const _SalonFrontDeskStatGrid();

  @override
  Widget build(BuildContext context) {
    final apptsToday = SalonScenarios.weekAppointments
        .where(
          (e) =>
              e.start.year == CrossCuttingFixtures.catalogToday.year &&
              e.start.month == CrossCuttingFixtures.catalogToday.month &&
              e.start.day == CrossCuttingFixtures.catalogToday.day,
        )
        .length;
    return _statGridResponsive(<Widget>[
        EdenStatCard(
          label: 'Bookings today',
          value: '$apptsToday',
          icon: Icons.event_available,
        ),
        const EdenStatCard(
          label: 'Stylists on floor',
          value: '4 / 4',
          icon: Icons.people_outline,
          variant: EdenColors.success,
        ),
        const EdenStatCard(
          label: 'No-shows this week',
          value: '3',
          icon: Icons.event_busy_outlined,
          variant: EdenColors.warning,
          trendValue: 'flagged',
        ),
        const EdenStatCard(
          label: 'Avg ticket',
          value: r'$148',
          icon: Icons.receipt_long,
          trend: EdenStatTrend.up,
          trendValue: '+\$12',
        ),
      ],
    );
  }
}

class _FuelFleetStatGrid extends StatelessWidget {
  const _FuelFleetStatGrid();

  @override
  Widget build(BuildContext context) {
    final tanksBelowReorder =
        FuelScenarios.tankLevels.where((t) => t.isBelowReorder).length;
    return _statGridResponsive(<Widget>[
        const EdenStatCard(
          label: 'Trucks on road',
          value: '3 / 4',
          icon: Icons.local_shipping,
          trendValue: 'T7 in shop',
        ),
        EdenStatCard(
          label: 'Tanks below reorder',
          value: '$tanksBelowReorder',
          icon: Icons.warning_amber_outlined,
          variant: tanksBelowReorder > 0
              ? EdenColors.error
              : EdenColors.success,
        ),
        const EdenStatCard(
          label: 'Gallons today',
          value: '6,420',
          icon: Icons.opacity,
        ),
        const EdenStatCard(
          label: 'Revenue today',
          value: r'$23,160',
          icon: Icons.attach_money,
          trend: EdenStatTrend.up,
          trendValue: '+8%',
        ),
      ],
    );
  }
}

class _MedicalClinicStatGrid extends StatelessWidget {
  const _MedicalClinicStatGrid();

  @override
  Widget build(BuildContext context) {
    return _statGridResponsive(const <Widget>[
      EdenStatCard(
        label: 'Visits today',
        value: '7',
        icon: Icons.medical_services_outlined,
      ),
      EdenStatCard(
        label: 'Avg visit duration',
        value: '52m',
        icon: Icons.timer_outlined,
        trend: EdenStatTrend.down,
        trendValue: '-4m',
      ),
      EdenStatCard(
        label: 'Open labs',
        value: '4',
        icon: Icons.science_outlined,
        variant: EdenColors.warning,
        trendValue: '1 abnormal',
      ),
      EdenStatCard(
        label: 'Pending consents',
        value: '2',
        icon: Icons.assignment_late_outlined,
        variant: EdenColors.error,
      ),
    ]);
  }
}

class _GovCaseworkerStatGrid extends StatelessWidget {
  const _GovCaseworkerStatGrid();

  @override
  Widget build(BuildContext context) {
    return _statGridResponsive(const <Widget>[
      EdenStatCard(
        label: 'Open cases',
        value: '247',
        icon: Icons.folder_open_outlined,
        trend: EdenStatTrend.up,
        trendValue: '+18 vs last week',
      ),
      EdenStatCard(
        label: 'SLA breaches today',
        value: '4',
        icon: Icons.warning_amber_outlined,
        variant: EdenColors.error,
      ),
      EdenStatCard(
        label: 'Approval rate',
        value: '74%',
        icon: Icons.check_circle_outline,
        trend: EdenStatTrend.up,
        trendValue: '+3%',
        variant: EdenColors.success,
      ),
      EdenStatCard(
        label: 'Avg case age',
        value: '6.2 days',
        icon: Icons.calendar_today,
      ),
    ]);
  }
}

class _ZeroValueStatCardDemo extends StatelessWidget {
  const _ZeroValueStatCardDemo();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: <Widget>[
        Expanded(
          child: EdenStatCard(
            label: 'New leads',
            value: '0',
            icon: Icons.inbox_outlined,
            trendValue: 'no activity yet',
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: EdenStatCard(
            label: 'Overdue',
            value: '0',
            icon: Icons.check_circle_outline,
            variant: EdenColors.success,
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// EdenDataTable — 4 realistic vertical tables + edge states
// -----------------------------------------------------------------------------

class _TradesJobsTableDemo extends StatelessWidget {
  const _TradesJobsTableDemo();

  @override
  Widget build(BuildContext context) {
    final jobs = TradesScenarios.weekEvents;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 1100,
        child: EdenDataTable(
          striped: true,
          columns: const <EdenTableColumn>[
            EdenTableColumn(label: 'Job ID'),
            EdenTableColumn(label: 'Title', flex: 3),
            EdenTableColumn(label: 'Type'),
            EdenTableColumn(label: 'Assignee', flex: 2),
            EdenTableColumn(label: 'Status'),
            EdenTableColumn(label: 'Urgency'),
            EdenTableColumn(label: 'Start'),
            EdenTableColumn(label: 'Duration'),
          ],
          rows: <EdenTableRow>[
            for (final e in jobs)
              EdenTableRow(cells: <Widget>[
                Text(e.id, style: const TextStyle(fontFamily: 'monospace')),
                Text(e.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(e.type ?? '—'),
                Text(e.assignee ?? '—'),
                EdenBadge(
                  label: e.status ?? '—',
                  variant: _statusVariant(e.status),
                  size: EdenBadgeSize.sm,
                ),
                EdenUrgencyBadge(urgency: _urgencyFor(e.readiness)),
                Text(
                  '${e.start.month}/${e.start.day} '
                  '${e.start.hour.toString().padLeft(2, '0')}:'
                  '${e.start.minute.toString().padLeft(2, '0')}',
                ),
                Text('${e.end.difference(e.start).inMinutes}m'),
              ]),
          ],
        ),
      ),
    );
  }
}

class _SalonClientsTableDemo extends StatelessWidget {
  const _SalonClientsTableDemo();

  @override
  Widget build(BuildContext context) {
    final clients = SalonScenarios.memberClients;
    return EdenDataTable(
      columns: const <EdenTableColumn>[
        EdenTableColumn(label: 'Client', flex: 3),
        EdenTableColumn(label: 'Tier'),
        EdenTableColumn(label: 'City'),
        EdenTableColumn(label: 'Notes', flex: 3),
      ],
      rows: <EdenTableRow>[
        for (final c in clients)
          EdenTableRow(cells: <Widget>[
            Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            c.tier != null
                ? EdenMembershipTierBadge(tier: c.tier!)
                : const SizedBox.shrink(),
            Text('${c.address.city}, ${c.address.regionCode}'),
            Text(
              c.notes ?? '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ]),
      ],
    );
  }
}

class _FuelDeliveriesTableDemo extends StatelessWidget {
  const _FuelDeliveriesTableDemo();

  @override
  Widget build(BuildContext context) {
    final deliveries = FuelScenarios.weekDeliveries;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 900,
        child: EdenDataTable(
          columns: const <EdenTableColumn>[
            EdenTableColumn(label: 'Route ID'),
            EdenTableColumn(label: 'Title', flex: 3),
            EdenTableColumn(label: 'Driver', flex: 2),
            EdenTableColumn(label: 'Type'),
            EdenTableColumn(label: 'Status'),
            EdenTableColumn(label: 'Start'),
          ],
          rows: <EdenTableRow>[
            for (final e in deliveries)
              EdenTableRow(cells: <Widget>[
                Text(e.id, style: const TextStyle(fontFamily: 'monospace')),
                Text(e.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(e.assignee ?? '—'),
                Text(e.type ?? '—'),
                EdenBadge(
                  label: e.status ?? '—',
                  variant: _statusVariant(e.status),
                  size: EdenBadgeSize.sm,
                ),
                Text(
                  '${e.start.month}/${e.start.day} '
                  '${e.start.hour.toString().padLeft(2, '0')}:'
                  '${e.start.minute.toString().padLeft(2, '0')}',
                ),
              ]),
          ],
        ),
      ),
    );
  }
}

class _MedicalVisitsTableDemo extends StatelessWidget {
  const _MedicalVisitsTableDemo();

  @override
  Widget build(BuildContext context) {
    final visits = MedicalScenarios.weekVisits;
    return EdenDataTable(
      columns: const <EdenTableColumn>[
        EdenTableColumn(label: 'Visit ID'),
        EdenTableColumn(label: 'Visit', flex: 3),
        EdenTableColumn(label: 'Provider', flex: 2),
        EdenTableColumn(label: 'Type'),
      ],
      rows: <EdenTableRow>[
        for (final e in visits)
          EdenTableRow(cells: <Widget>[
            Text(e.id, style: const TextStyle(fontFamily: 'monospace')),
            Text(e.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(e.assignee ?? '—'),
            Text(e.type ?? '—'),
          ]),
      ],
    );
  }
}

class _EmptyTableDemo extends StatelessWidget {
  const _EmptyTableDemo();
  @override
  Widget build(BuildContext context) {
    return const EdenDataTable(
      columns: <EdenTableColumn>[
        EdenTableColumn(label: 'Customer'),
        EdenTableColumn(label: 'Status'),
      ],
      rows: <EdenTableRow>[],
    );
  }
}

class _SingleRowTableDemo extends StatelessWidget {
  const _SingleRowTableDemo();
  @override
  Widget build(BuildContext context) {
    return EdenDataTable(
      columns: const <EdenTableColumn>[
        EdenTableColumn(label: 'Job'),
        EdenTableColumn(label: 'Assignee'),
        EdenTableColumn(label: 'Status'),
      ],
      rows: <EdenTableRow>[
        EdenTableRow(cells: <Widget>[
          Text(TradesScenarios.singleEventDay.first.title),
          Text(TradesScenarios.singleEventDay.first.assignee ?? '—'),
          const EdenBadge(
            label: 'scheduled',
            variant: EdenBadgeVariant.neutral,
            size: EdenBadgeSize.sm,
          ),
        ]),
      ],
    );
  }
}

class _OverflowTableDemo extends StatelessWidget {
  const _OverflowTableDemo();

  @override
  Widget build(BuildContext context) {
    final events = TradesScenarios.monthEvents;
    return SizedBox(
      height: 420,
      child: SingleChildScrollView(
        child: EdenDataTable(
          striped: true,
          columns: const <EdenTableColumn>[
            EdenTableColumn(label: 'ID'),
            EdenTableColumn(label: 'Title', flex: 2),
            EdenTableColumn(label: 'Assignee', flex: 2),
            EdenTableColumn(label: 'Status'),
          ],
          rows: <EdenTableRow>[
            for (final e in events.take(50))
              EdenTableRow(cells: <Widget>[
                Text(e.id, style: const TextStyle(fontSize: 11)),
                Text(e.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(e.assignee ?? '—'),
                Text(e.status ?? '—'),
              ]),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// EdenCostSummaryCard — per-vertical demos (cents-based)
// -----------------------------------------------------------------------------

class _TradesCostSummaryDemo extends StatelessWidget {
  const _TradesCostSummaryDemo();

  @override
  Widget build(BuildContext context) {
    const cost = TradesScenarios.jobCostBreakdown;
    return EdenCostSummaryCard(
      title: 'Whitfield HVAC install',
      laborCents: cost.laborCents,
      materialCents: cost.materialCents,
      equipmentCents: cost.equipmentCents,
      extraRows: <EdenCostRow>[
        if (cost.permitsCents != null)
          EdenCostRow(label: 'Permits', cents: cost.permitsCents!),
        if (cost.subContractorsCents != null && cost.subContractorsCents! > 0)
          EdenCostRow(
            label: 'Subcontractor',
            cents: cost.subContractorsCents!,
          ),
      ],
    );
  }
}

class _FuelCostSummaryDemo extends StatelessWidget {
  const _FuelCostSummaryDemo();
  @override
  Widget build(BuildContext context) {
    const cost = FuelScenarios.deliveryCostBreakdown;
    // Map: fuel → material, hauling → labor, surcharge → equipment;
    // tax renders as extra row.
    return EdenCostSummaryCard(
      title: 'Delivery — Northpoint Diesel (1,800 gal)',
      laborCents: cost.haulingCents,
      materialCents: cost.fuelCents,
      equipmentCents: cost.surchargeCents,
      extraRows: const <EdenCostRow>[
        EdenCostRow(label: 'Tax', cents: 61245),
      ],
    );
  }
}

class _MedicalCostSummaryDemo extends StatelessWidget {
  const _MedicalCostSummaryDemo();
  @override
  Widget build(BuildContext context) {
    return const EdenCostSummaryCard(
      title: 'Home visit — MRN 44291 (diabetes panel)',
      laborCents: 12000, // provider time
      materialCents: 4500, // labs / strips
      equipmentCents: 1500, // visit kit consumables
      extraRows: <EdenCostRow>[
        EdenCostRow(label: 'Travel', cents: 2800),
        EdenCostRow(label: 'Insurance adjustment', cents: -5400),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// EdenActivityFeedItem — mixed-vertical feed
// -----------------------------------------------------------------------------

class _MixedActivityFeedDemo extends StatelessWidget {
  const _MixedActivityFeedDemo();

  @override
  Widget build(BuildContext context) {
    final feed = CrossCuttingFixtures.mixedActivityFeed;
    return EdenCard(
      child: Column(
        children: <Widget>[
          for (var i = 0; i < feed.length; i++) ...<Widget>[
            EdenActivityFeedItem(item: feed[i]),
            if (i < feed.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _SingleActivityItemDemo extends StatelessWidget {
  const _SingleActivityItemDemo();

  @override
  Widget build(BuildContext context) {
    return EdenCard(
      child: EdenActivityFeedItem(
        item: CrossCuttingFixtures.mixedActivityFeed.first,
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// EdenMediaRow — per-vertical counts
// -----------------------------------------------------------------------------

class _TradesMediaRowDemo extends StatelessWidget {
  const _TradesMediaRowDemo();
  @override
  Widget build(BuildContext context) {
    return EdenMediaRow(
      items: <EdenMediaRowItem>[
        const EdenMediaRowItem(
          icon: Icons.photo_outlined,
          label: 'photos',
          count: '14',
        ),
        const EdenMediaRowItem(
          icon: Icons.videocam_outlined,
          label: 'videos',
          count: '2',
        ),
        const EdenMediaRowItem(
          icon: Icons.description_outlined,
          label: 'docs',
          count: '5',
        ),
        EdenMediaRowItem(
          icon: Icons.add_circle_outline,
          label: 'attach',
          onAddPressed: () {},
        ),
      ],
    );
  }
}

class _SalonMediaRowDemo extends StatelessWidget {
  const _SalonMediaRowDemo();
  @override
  Widget build(BuildContext context) {
    return const EdenMediaRow(
      items: <EdenMediaRowItem>[
        EdenMediaRowItem(
          icon: Icons.photo_camera_outlined,
          label: 'before',
          count: '3',
        ),
        EdenMediaRowItem(
          icon: Icons.photo_outlined,
          label: 'after',
          count: '3',
        ),
        EdenMediaRowItem(
          icon: Icons.shopping_bag_outlined,
          label: 'products',
          count: '2',
          trailingText: r'$84',
        ),
      ],
    );
  }
}

class _MedicalMediaRowDemo extends StatelessWidget {
  const _MedicalMediaRowDemo();
  @override
  Widget build(BuildContext context) {
    return EdenMediaRow(
      items: <EdenMediaRowItem>[
        const EdenMediaRowItem(
          icon: Icons.image_outlined,
          label: 'imaging',
          count: '2',
        ),
        const EdenMediaRowItem(
          icon: Icons.science_outlined,
          label: 'labs',
          count: '4',
          trailingText: '1 abnormal',
        ),
        EdenMediaRowItem(
          icon: Icons.send_outlined,
          label: 'referrals',
          count: '1',
          onAddPressed: () {},
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// EdenStockLevelIndicator — fuel tank levels demo
// -----------------------------------------------------------------------------

class _FuelTankLevelsDemo extends StatelessWidget {
  const _FuelTankLevelsDemo();

  @override
  Widget build(BuildContext context) {
    const tanks = FuelScenarios.tankLevels;
    return Column(
      children: <Widget>[
        for (final t in tanks)
          Padding(
            padding: const EdgeInsets.only(bottom: EdenSpacing.space3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  t.terminalName,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 4),
                EdenStockLevelIndicator(
                  // Map gallons → currentStock; reorderPoint chosen so that the
                  // tank's actual percentage drives the gauge color correctly.
                  // The widget uses reorderPoint*2 as max capacity (when
                  // reorderPoint > 0) and forces RED when currentStock ≤
                  // reorderPoint. To project a tank reading: set reorderPoint
                  // = capacityGallons * 0.25 (red threshold) and pass the
                  // tank's gallons in directly.
                  currentStock: t.gallons,
                  reorderPoint: (t.capacityGallons * 0.25).round(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Helpers
// -----------------------------------------------------------------------------

EdenBadgeVariant _statusVariant(String? status) {
  switch (status) {
    case 'completed':
      return EdenBadgeVariant.success;
    case 'in_progress':
      return EdenBadgeVariant.primary;
    case 'pending_review':
      return EdenBadgeVariant.warning;
    case 'cancelled':
      return EdenBadgeVariant.danger;
    case 'scheduled':
    default:
      return EdenBadgeVariant.neutral;
  }
}

String _urgencyFor(EdenSchedulerEventReadiness? readiness) {
  switch (readiness) {
    case EdenSchedulerEventReadiness.urgent:
      return 'high';
    case EdenSchedulerEventReadiness.warning:
      return 'medium';
    case EdenSchedulerEventReadiness.ready:
    case null:
      return 'low';
  }
}
