import 'package:flutter/material.dart';
import '../../eden_ui.dart';
import '../widgets/section.dart';

/// Showcase screen for business pattern components:
/// EdenSeverityBadge, EdenStatGrid, EdenPipelineBar.
class BusinessScreen extends StatelessWidget {
  const BusinessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Business Patterns')),
      body: ListView(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        children: [
          // ---------------------------------------------------------------
          // Severity Badge
          // ---------------------------------------------------------------
          Section(
            title: 'Severity Badge — All Levels',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: EdenSeverityLevel.values
                  .map((level) => EdenSeverityBadge(
                        level: level,
                        description: level.label,
                      ))
                  .toList(),
            ),
          ),
          Section(
            title: 'Severity Badge — Compact',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: EdenSeverityLevel.values
                  .map((level) => EdenSeverityBadge(
                        level: level,
                        compact: true,
                        description: level.label,
                      ))
                  .toList(),
            ),
          ),
          Section(
            title: 'Severity Badge — Custom Overrides',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                EdenSeverityBadge(
                  level: EdenSeverityLevel.safe,
                  customLabel: 'Read-Only',
                  customIcon: Icons.visibility,
                ),
                EdenSeverityBadge(
                  level: EdenSeverityLevel.destructive,
                  customLabel: 'Danger Zone',
                  customColor: Colors.deepOrange,
                ),
              ],
            ),
          ),

          const EdenDivider(label: 'Stat Grid'),

          // ---------------------------------------------------------------
          // Stat Grid
          // ---------------------------------------------------------------
          Section(
            title: 'Stat Grid — 4 Cards',
            child: EdenStatGrid(
              padding: EdgeInsets.zero,
              items: const [
                EdenStatGridItem(
                  label: 'Open Bids',
                  value: '12',
                  icon: Icons.folder_open,
                  trend: EdenStatTrend.up,
                  trendValue: '+15%',
                  trendLabel: 'vs last month',
                ),
                EdenStatGridItem(
                  label: 'Won',
                  value: '8',
                  icon: Icons.check_circle,
                  variant: Colors.green,
                  trend: EdenStatTrend.up,
                  trendValue: '+3',
                ),
                EdenStatGridItem(
                  label: 'Revenue',
                  value: '\$142K',
                  icon: Icons.attach_money,
                  variant: Colors.blue,
                  trend: EdenStatTrend.down,
                  trendValue: '-4%',
                  trendLabel: 'vs last quarter',
                ),
                EdenStatGridItem(
                  label: 'Active Jobs',
                  value: '23',
                  icon: Icons.engineering,
                ),
              ],
            ),
          ),
          Section(
            title: 'Stat Grid — With Action Labels',
            child: EdenStatGrid(
              padding: EdgeInsets.zero,
              items: [
                EdenStatGridItem(
                  label: 'Pending Approvals',
                  value: '5',
                  icon: Icons.pending_actions,
                  variant: Colors.orange,
                  actionLabel: 'Review all ->',
                  onTap: () {},
                ),
                EdenStatGridItem(
                  label: 'Overdue Tasks',
                  value: '2',
                  icon: Icons.warning,
                  variant: Colors.red,
                  actionLabel: 'View overdue ->',
                  onTap: () {},
                ),
              ],
            ),
          ),

          const EdenDivider(label: 'Pipeline Bar'),

          // ---------------------------------------------------------------
          // Pipeline Bar
          // ---------------------------------------------------------------
          Section(
            title: 'Pipeline Bar — Full',
            child: EdenPipelineBar(
              title: 'Bid Pipeline',
              totalLabel: '\$24,500 total value',
              segments: const [
                EdenPipelineSegment(
                  label: 'Draft',
                  value: 5000,
                  color: Color(0xFF71717A),
                  count: 3,
                  formattedValue: '\$5,000',
                ),
                EdenPipelineSegment(
                  label: 'Sent',
                  value: 8000,
                  color: Color(0xFFF59E0B),
                  count: 5,
                  formattedValue: '\$8,000',
                ),
                EdenPipelineSegment(
                  label: 'Won',
                  value: 9000,
                  color: Color(0xFF22C55E),
                  count: 4,
                  formattedValue: '\$9,000',
                ),
                EdenPipelineSegment(
                  label: 'Lost',
                  value: 2500,
                  color: Color(0xFFEF4444),
                  count: 2,
                  formattedValue: '\$2,500',
                ),
              ],
            ),
          ),
          Section(
            title: 'Pipeline Bar — Bar Only (No Legend)',
            child: EdenPipelineBar(
              barHeight: 12,
              showLegend: false,
              segments: const [
                EdenPipelineSegment(label: 'Complete', value: 70, color: Colors.green),
                EdenPipelineSegment(label: 'In Progress', value: 20, color: Colors.blue),
                EdenPipelineSegment(label: 'Remaining', value: 10, color: Colors.grey),
              ],
            ),
          ),
          Section(
            title: 'Pipeline Bar — Hiring Funnel',
            child: EdenPipelineBar(
              title: 'Hiring Funnel',
              totalLabel: '142 applicants',
              segments: const [
                EdenPipelineSegment(
                  label: 'Applied',
                  value: 80,
                  color: Color(0xFF94A3B8),
                  count: 80,
                ),
                EdenPipelineSegment(
                  label: 'Screened',
                  value: 35,
                  color: Color(0xFF3B82F6),
                  count: 35,
                ),
                EdenPipelineSegment(
                  label: 'Interview',
                  value: 18,
                  color: Color(0xFFA855F7),
                  count: 18,
                ),
                EdenPipelineSegment(
                  label: 'Offer',
                  value: 7,
                  color: Color(0xFF10B981),
                  count: 7,
                ),
                EdenPipelineSegment(
                  label: 'Hired',
                  value: 2,
                  color: Color(0xFFD4A853),
                  count: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
