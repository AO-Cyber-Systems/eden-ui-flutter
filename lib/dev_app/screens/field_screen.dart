import 'package:flutter/material.dart';
import '../../eden_ui.dart';
import '../widgets/section.dart';

/// Catalog screen for Objective 007 — B-Trades-A field/companion pages.
///
/// Subsections added incrementally as TRDs 007-01..007-08 ship. Each
/// subsection mounts the corresponding widget with hand-built fixture data
/// + a small "Last event: ..." console line where applicable, so reviewers
/// can verify callbacks end-to-end inside the dev catalog.
class FieldScreen extends StatelessWidget {
  const FieldScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Field / Companion Pages — Obj 007')),
      body: ListView(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        children: const [
          // Wave 1 — Mobile-shell primitives
          _QuickAccessGridDemo(),
          // (TRD 007-08 will append _MobileAiFabDemo here)
          // (TRD 007-05/06 will append GPS-aware page demos here)
          // (TRD 007-02/04 will append capture-flow page demos here)
          // (TRD 007-01/03 will append form-flow page demos here)
        ],
      ),
    );
  }
}

class _QuickAccessGridDemo extends StatefulWidget {
  const _QuickAccessGridDemo();
  @override
  State<_QuickAccessGridDemo> createState() => _QuickAccessGridDemoState();
}

class _QuickAccessGridDemoState extends State<_QuickAccessGridDemo> {
  String? _lastTap;

  @override
  Widget build(BuildContext context) {
    return Section(
      title: 'EdenMobileQuickAccessGrid',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EdenMobileQuickAccessGrid(
            title: 'Quick Access',
            items: const [
              EdenMobileQuickAccessItem(
                  id: 'find_parts',
                  icon: Icons.search,
                  label: 'Find Parts'),
              EdenMobileQuickAccessItem(
                  id: 'request_parts',
                  icon: Icons.inventory_2_outlined,
                  label: 'Request Parts'),
              EdenMobileQuickAccessItem(
                id: 'quick_bid',
                icon: Icons.attach_money,
                label: 'Quick Bid',
                accent: Color(0xFFD4A853),
              ),
              EdenMobileQuickAccessItem(
                  id: 'contacts',
                  icon: Icons.phone_outlined,
                  label: 'Contacts'),
              EdenMobileQuickAccessItem(
                  id: 'po_status',
                  icon: Icons.assignment_outlined,
                  label: 'PO Status'),
              EdenMobileQuickAccessItem(
                id: 'escalate',
                icon: Icons.warning_amber_outlined,
                label: 'Escalate',
                accent: Color(0xFFEF4444),
              ),
            ],
            onTap: (id) => setState(() => _lastTap = id),
          ),
          const SizedBox(height: 8),
          Text('Last tap: ${_lastTap ?? "—"}'),
        ],
      ),
    );
  }
}
