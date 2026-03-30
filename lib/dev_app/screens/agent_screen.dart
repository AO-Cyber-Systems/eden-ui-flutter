import 'package:flutter/material.dart';
import '../../eden_ui.dart';
import '../widgets/section.dart';

/// Showcase screen for agent builder components:
/// EdenCatalogPicker, EdenApprovalFlow, EdenExecutionLog.
class AgentScreen extends StatefulWidget {
  const AgentScreen({super.key});

  @override
  State<AgentScreen> createState() => _AgentScreenState();
}

class _AgentScreenState extends State<AgentScreen> {
  final _selectedToolIds = <String>{'db-query', 'send-email'};

  // Approval flow state
  final _levels = <EdenApprovalLevel>[
    const EdenApprovalLevel(
      id: 'safe',
      label: 'Safe',
      color: Color(0xFF22C55E),
      icon: Icons.check_circle_outline,
    ),
    const EdenApprovalLevel(
      id: 'scoped',
      label: 'Scoped',
      color: Color(0xFF3B82F6),
      icon: Icons.shield_outlined,
    ),
    const EdenApprovalLevel(
      id: 'review',
      label: 'Review',
      color: Color(0xFFF59E0B),
      icon: Icons.rate_review_outlined,
      requiresApproval: true,
      approverRole: 'manager',
      timeoutMinutes: 60,
    ),
    const EdenApprovalLevel(
      id: 'destructive',
      label: 'Destructive',
      color: Color(0xFFEF4444),
      icon: Icons.warning_amber_rounded,
      requiresApproval: true,
      approverRole: 'admin',
      timeoutMinutes: 30,
    ),
  ];

  void _handleApprovalChange(EdenApprovalChange change) {
    setState(() {
      final idx = _levels.indexWhere((l) => l.id == change.levelId);
      if (idx == -1) return;
      final old = _levels[idx];
      _levels[idx] = EdenApprovalLevel(
        id: old.id,
        label: old.label,
        color: old.color,
        icon: old.icon,
        requiresApproval: change.requiresApproval ?? old.requiresApproval,
        approverRole: change.approverRole ?? old.approverRole,
        timeoutMinutes: change.timeoutMinutes ?? old.timeoutMinutes,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agent Builder')),
      body: ListView(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        children: [
          // ---------------------------------------------------------------
          // Catalog Picker
          // ---------------------------------------------------------------
          Section(
            title: 'Catalog Picker — Two-Column',
            child: Container(
              height: 350,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                borderRadius: EdenRadii.borderRadiusLg,
              ),
              clipBehavior: Clip.antiAlias,
              child: EdenCatalogPicker(
                items: const [
                  EdenCatalogItem(
                    id: 'db-query',
                    name: 'Query Database',
                    description: 'Read-only SQL access to project data',
                    category: 'Data Access',
                    icon: Icons.storage,
                  ),
                  EdenCatalogItem(
                    id: 'db-write',
                    name: 'Write Database',
                    description: 'Insert/update project records',
                    category: 'Data Access',
                    icon: Icons.edit_note,
                  ),
                  EdenCatalogItem(
                    id: 'send-email',
                    name: 'Send Email',
                    description: 'SMTP email delivery via SendGrid',
                    category: 'Communication',
                    icon: Icons.email,
                  ),
                  EdenCatalogItem(
                    id: 'send-sms',
                    name: 'Send SMS',
                    description: 'Text message via Twilio',
                    category: 'Communication',
                    icon: Icons.sms,
                  ),
                  EdenCatalogItem(
                    id: 'read-file',
                    name: 'Read File',
                    description: 'Read from document storage',
                    category: 'File System',
                    icon: Icons.description,
                  ),
                  EdenCatalogItem(
                    id: 'webhook',
                    name: 'Call Webhook',
                    description: 'HTTP POST to external endpoint',
                    category: 'API Integration',
                    icon: Icons.webhook,
                  ),
                ],
                selectedIds: _selectedToolIds,
                onToggle: (id) {
                  setState(() {
                    if (_selectedToolIds.contains(id)) {
                      _selectedToolIds.remove(id);
                    } else {
                      _selectedToolIds.add(id);
                    }
                  });
                },
                searchHint: 'Search tools...',
                selectedLabel: 'Attached Tools',
                emptySelectedLabel: 'No tools attached yet',
              ),
            ),
          ),

          const EdenDivider(label: 'Approval Flow'),

          // ---------------------------------------------------------------
          // Approval Flow
          // ---------------------------------------------------------------
          Section(
            title: 'Approval Flow Editor',
            child: Container(
              height: 350,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                borderRadius: EdenRadii.borderRadiusLg,
              ),
              clipBehavior: Clip.antiAlias,
              child: EdenApprovalFlow(
                title: 'Approval Configuration',
                description:
                    'Configure which classification levels require approval before execution.',
                levels: _levels,
                roles: const [
                  'any',
                  'technician',
                  'dispatcher',
                  'manager',
                  'admin',
                ],
                onChanged: _handleApprovalChange,
                onSave: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Approval flow saved')),
                  );
                },
              ),
            ),
          ),

          const EdenDivider(label: 'Execution Log'),

          // ---------------------------------------------------------------
          // Execution Log
          // ---------------------------------------------------------------
          Section(
            title: 'Execution History Log',
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                borderRadius: EdenRadii.borderRadiusLg,
              ),
              clipBehavior: Clip.antiAlias,
              child: EdenExecutionLog(
                records: [
                  EdenExecutionRecord(
                    timestamp:
                        DateTime.now().subtract(const Duration(minutes: 5)),
                    trigger: 'Project Created',
                    actions: const ['Assign Tech', 'Send Notification'],
                    result: EdenExecutionResult.success,
                    duration: const Duration(seconds: 12),
                  ),
                  EdenExecutionRecord(
                    timestamp:
                        DateTime.now().subtract(const Duration(minutes: 32)),
                    trigger: 'Status Changed',
                    actions: const [
                      'Update Dashboard',
                      'Notify Owner',
                      'Log Audit',
                    ],
                    result: EdenExecutionResult.partial,
                    duration: const Duration(minutes: 1, seconds: 45),
                    errorMessage:
                        'Notification service timeout after 30s — retried 3 times. Owner email delivery failed: SMTP 550 mailbox full.',
                  ),
                  EdenExecutionRecord(
                    timestamp:
                        DateTime.now().subtract(const Duration(hours: 2)),
                    trigger: 'Invoice Past Due',
                    actions: const ['Send Reminder', 'Flag Account'],
                    result: EdenExecutionResult.success,
                    duration: const Duration(seconds: 8),
                  ),
                  EdenExecutionRecord(
                    timestamp:
                        DateTime.now().subtract(const Duration(hours: 5)),
                    trigger: 'Material Request',
                    actions: const ['Create PO', 'Notify Purchasing'],
                    result: EdenExecutionResult.failure,
                    duration: const Duration(seconds: 3),
                    errorMessage:
                        'Supplier API returned 503 Service Unavailable. PO creation aborted — no fallback supplier configured.',
                  ),
                  EdenExecutionRecord(
                    timestamp: DateTime.now()
                        .subtract(const Duration(days: 1, hours: 3)),
                    trigger: 'Appointment Completed',
                    actions: const [
                      'Generate Report',
                      'Update Project Status',
                    ],
                    result: EdenExecutionResult.success,
                    duration: const Duration(seconds: 22),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
