import 'package:flutter/material.dart';
import '../../eden_ui.dart';
import '../widgets/section.dart';

class DevflowProjectScreen extends StatefulWidget {
  const DevflowProjectScreen({super.key});

  @override
  State<DevflowProjectScreen> createState() => _DevflowProjectScreenState();
}

class _DevflowProjectScreenState extends State<DevflowProjectScreen> {
  bool _objective1Expanded = true;
  bool _objective2Expanded = false;

  final List<EdenLogEntry> _logEntries = [
    EdenLogEntry(
      message: 'Rails server started on http://0.0.0.0:3000',
      timestamp: DateTime(2026, 3, 21, 10, 0, 0, 123),
      level: EdenLogLevel.info,
      source: 'rails',
    ),
    EdenLogEntry(
      message: 'Compiling entrypoints...',
      timestamp: DateTime(2026, 3, 21, 10, 0, 1, 456),
      level: EdenLogLevel.info,
      source: 'webpack',
    ),
    EdenLogEntry(
      message: 'database "app_development" already exists',
      timestamp: DateTime(2026, 3, 21, 10, 0, 2, 12),
      level: EdenLogLevel.warning,
      source: 'postgres',
    ),
    EdenLogEntry(
      message: 'GET /api/v1/users 200 OK (12ms)',
      timestamp: DateTime(2026, 3, 21, 10, 0, 3, 789),
      level: EdenLogLevel.debug,
      source: 'rails',
    ),
    EdenLogEntry(
      message: 'Asset compilation complete in 3.2s',
      timestamp: DateTime(2026, 3, 21, 10, 0, 4, 200),
      level: EdenLogLevel.info,
      source: 'webpack',
    ),
    EdenLogEntry(
      message: 'PG::ConnectionBad: could not connect to server',
      timestamp: DateTime(2026, 3, 21, 10, 0, 5, 500),
      level: EdenLogLevel.error,
      source: 'postgres',
    ),
    EdenLogEntry(
      message: 'Reconnecting to database in 5 seconds...',
      timestamp: DateTime(2026, 3, 21, 10, 0, 6, 100),
      level: EdenLogLevel.warning,
      source: 'rails',
    ),
    EdenLogEntry(
      message: 'POST /api/v1/sessions 201 Created (45ms)',
      timestamp: DateTime(2026, 3, 21, 10, 0, 7, 800),
      level: EdenLogLevel.debug,
      source: 'rails',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('DevFlow — Projects & Workflow'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        children: [
          // Workflow Stepper
          const Section(
            title: 'WORKFLOW STEPPER',
            child: EdenWorkflowStepper(
              steps: [
                EdenWorkflowStep(
                  label: 'New',
                  state: EdenWorkflowStepState.completed,
                ),
                EdenWorkflowStep(
                  label: 'Discuss',
                  state: EdenWorkflowStepState.completed,
                ),
                EdenWorkflowStep(
                  label: 'Plan',
                  state: EdenWorkflowStepState.completed,
                ),
                EdenWorkflowStep(
                  label: 'Execute',
                  state: EdenWorkflowStepState.active,
                ),
                EdenWorkflowStep(
                  label: 'Verify',
                  state: EdenWorkflowStepState.pending,
                ),
                EdenWorkflowStep(
                  label: 'Complete',
                  state: EdenWorkflowStepState.pending,
                ),
              ],
            ),
          ),

          // Project Cards
          Section(
            title: 'PROJECT CARDS',
            child: Row(
              children: [
                Expanded(
                  child: EdenProjectCard(
                    name: 'eden-app',
                    path: '~/dev/eden-app',
                    framework: 'Rails',
                    status: EdenProjectStatus.running,
                    hasDevflow: true,
                    onOpenTerminal: () {},
                    onOpenEditor: () {},
                    onOpenFinder: () {},
                    onOpenLogs: () {},
                  ),
                ),
                const SizedBox(width: EdenSpacing.space4),
                Expanded(
                  child: EdenProjectCard(
                    name: 'aocodex',
                    path: '~/dev/aocodex',
                    framework: 'Node',
                    status: EdenProjectStatus.stopped,
                    hasDevflow: false,
                    onOpenTerminal: () {},
                    onOpenEditor: () {},
                  ),
                ),
              ],
            ),
          ),

          // Objective Progress
          Section(
            title: 'OBJECTIVE PROGRESS',
            child: Column(
              children: [
                EdenObjectiveProgress(
                  title: '01 — Foundation & Infrastructure',
                  statusLabel: 'In Progress',
                  expanded: _objective1Expanded,
                  onToggleExpand: () {
                    setState(() => _objective1Expanded = !_objective1Expanded);
                  },
                  jobs: const [
                    EdenObjectiveJobStatus(
                      name: 'Project scaffolding',
                      state: EdenJobState.completed,
                    ),
                    EdenObjectiveJobStatus(
                      name: 'Database schema',
                      state: EdenJobState.completed,
                    ),
                    EdenObjectiveJobStatus(
                      name: 'Authentication setup',
                      state: EdenJobState.completed,
                    ),
                    EdenObjectiveJobStatus(
                      name: 'CI/CD pipeline',
                      state: EdenJobState.running,
                    ),
                    EdenObjectiveJobStatus(
                      name: 'Monitoring & alerts',
                      state: EdenJobState.pending,
                    ),
                  ],
                ),
                const SizedBox(height: EdenSpacing.space4),
                EdenObjectiveProgress(
                  title: '02 — Container Detection',
                  statusLabel: 'Complete',
                  expanded: _objective2Expanded,
                  onToggleExpand: () {
                    setState(() => _objective2Expanded = !_objective2Expanded);
                  },
                  jobs: const [
                    EdenObjectiveJobStatus(
                      name: 'Docker detection',
                      state: EdenJobState.completed,
                    ),
                    EdenObjectiveJobStatus(
                      name: 'Compose file parsing',
                      state: EdenJobState.completed,
                    ),
                    EdenObjectiveJobStatus(
                      name: 'Container lifecycle',
                      state: EdenJobState.completed,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Terminal Output
          const Section(
            title: 'TERMINAL OUTPUT',
            child: EdenTerminalOutput(
              command: 'devflow doctor',
              output:
                  'Checking prerequisites...\n'
                  '  [pass]  Ruby 3.3.0\n'
                  '  [pass]  Node.js 22.0.0\n'
                  '  [warn]  Docker not running\n'
                  '  [pass]  PostgreSQL 16.2\n'
                  '  [fail]  Redis not installed\n'
                  '\n'
                  '4 passed, 1 warning, 1 failed\n'
                  'Run "devflow doctor --fix" to resolve issues.',
            ),
          ),

          // Log Viewer
          Section(
            title: 'LOG VIEWER',
            child: SizedBox(
              height: 300,
              child: EdenLogViewer(
                entries: _logEntries,
              ),
            ),
          ),

          const SizedBox(height: EdenSpacing.space8),
        ],
      ),
    );
  }
}
