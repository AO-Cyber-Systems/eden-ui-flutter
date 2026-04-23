import 'package:flutter/material.dart';
import '../../eden_ui.dart';
import '../widgets/section.dart';

class DevflowToolsScreen extends StatefulWidget {
  const DevflowToolsScreen({super.key});

  @override
  State<DevflowToolsScreen> createState() => _DevflowToolsScreenState();
}

class _DevflowToolsScreenState extends State<DevflowToolsScreen> {
  List<EdenEnvEntry> _envEntries = [
    const EdenEnvEntry(
      key: 'DATABASE_URL',
      value: 'postgres://localhost:5432/app',
      source: '1Password',
    ),
    const EdenEnvEntry(
      key: 'REDIS_URL',
      value: 'redis://localhost:6379',
    ),
    const EdenEnvEntry(
      key: 'SECRET_KEY_BASE',
      value: 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0',
      source: '.env',
    ),
  ];

  final String _secretValue = 'sk-ant-1234567890abcdef';
  String _customToken = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('DevFlow — Tools & Config'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        children: [
          // Account Card
          Section(
            title: 'ACCOUNT CARD',
            child: EdenAccountCard(
              name: 'Claude Pro',
              authType: EdenAuthType.oauth,
              status: EdenAccountStatus.active,
              rateLimitRemaining: 4500,
              rateLimitTotal: 5000,
              requestCount: 127,
              avgResponseTime: '245ms',
              errorRate: '0.3%',
              onPause: () {},
              onTest: () {},
            ),
          ),

          // Request Log
          Section(
            title: 'REQUEST LOG',
            child: Column(
              children: [
                EdenRequestLog(
                  method: EdenHttpMethod.post,
                  path: '/v1/messages',
                  statusCode: 200,
                  model: 'claude-sonnet-4-20250514',
                  inputTokens: 1500,
                  outputTokens: 800,
                  responseTime: '245ms',
                  streamed: true,
                  timestamp: DateTime(2026, 3, 21, 10, 30, 12),
                ),
                EdenRequestLog(
                  method: EdenHttpMethod.get,
                  path: '/v1/models',
                  statusCode: 200,
                  responseTime: '12ms',
                  timestamp: DateTime(2026, 3, 21, 10, 29, 58),
                ),
                EdenRequestLog(
                  method: EdenHttpMethod.post,
                  path: '/v1/messages',
                  statusCode: 429,
                  model: 'claude-sonnet-4-20250514',
                  timestamp: DateTime(2026, 3, 21, 10, 28, 45),
                ),
              ],
            ),
          ),

          // Packages
          Section(
            title: 'PACKAGES',
            child: Column(
              children: [
                const EdenPackageRow(
                  name: 'ruby',
                  currentVersion: '3.3.0',
                  type: EdenPackageType.formula,
                  outdated: false,
                ),
                EdenPackageRow(
                  name: 'node',
                  currentVersion: '22.0.0',
                  availableVersion: '22.1.0',
                  type: EdenPackageType.mise,
                  outdated: true,
                  onUpgrade: () {},
                ),
                const EdenPackageRow(
                  name: 'redis',
                  currentVersion: '7.2.4',
                  type: EdenPackageType.formula,
                  pinned: true,
                ),
              ],
            ),
          ),

          // Tool Card
          Section(
            title: 'TOOL CARD',
            child: EdenToolCard(
              name: 'Claude Code',
              description: "Anthropic's official CLI for Claude",
              version: '1.0.23',
              provider: 'Anthropic',
              icon: Icons.terminal,
              installed: true,
              capabilities: [
                'code generation',
                'debugging',
                'refactoring',
              ],
              onConfigure: () {},
              onRemove: () {},
            ),
          ),

          // Env Editor
          Section(
            title: 'ENV EDITOR',
            child: EdenEnvEditor(
              entries: _envEntries,
              onChanged: (entries) {
                setState(() => _envEntries = List<EdenEnvEntry>.from(entries));
              },
            ),
          ),

          // Key Value Table
          const Section(
            title: 'KEY VALUE TABLE',
            child: EdenKeyValueTable(
              items: [
                EdenKeyValue(
                  key: 'user.name',
                  value: 'Justin',
                  monospace: true,
                ),
                EdenKeyValue(
                  key: 'user.email',
                  value: 'justin@example.com',
                  monospace: true,
                ),
                EdenKeyValue(
                  key: 'core.editor',
                  value: 'code --wait',
                  monospace: true,
                ),
                EdenKeyValue(
                  key: 'init.defaultBranch',
                  value: 'main',
                  monospace: true,
                ),
              ],
            ),
          ),

          // Secret Field
          Section(
            title: 'SECRET FIELD',
            child: Column(
              children: [
                EdenSecretField(
                  label: 'API Key',
                  value: _secretValue,
                  readOnly: true,
                  onCopy: () {},
                ),
                const SizedBox(height: EdenSpacing.space3),
                EdenSecretField(
                  label: 'Custom Token',
                  value: _customToken,
                  onChanged: (v) => setState(() => _customToken = v),
                ),
              ],
            ),
          ),

          // Email Row
          Section(
            title: 'EMAIL ROW',
            child: Column(
              children: [
                EdenEmailRow(
                  from: 'deploy@app.test',
                  subject: 'Deployment successful',
                  unread: true,
                  attachmentCount: 1,
                  timestamp: DateTime(2026, 3, 21, 9, 45),
                  onTap: () {},
                ),
                EdenEmailRow(
                  from: 'alerts@app.test',
                  subject: 'High memory usage detected',
                  preview: 'Memory usage on web-01 has exceeded 90% threshold for the past 15 minutes.',
                  unread: false,
                  timestamp: DateTime(2026, 3, 21, 8, 12),
                  onTap: () {},
                ),
              ],
            ),
          ),

          // Email Viewer
          Section(
            title: 'EMAIL VIEWER',
            child: SizedBox(
              height: 350,
              child: EdenEmailViewer(
                subject: 'Deployment successful',
                from: 'deploy@app.test',
                to: 'team@app.test',
                date: DateTime(2026, 3, 21, 9, 45),
                bodyText:
                    'Deployment to production completed successfully.\n\n'
                    'Branch: main\n'
                    'Commit: a1b2c3d\n'
                    'Duration: 2m 34s\n\n'
                    'All health checks passing.',
                headersText:
                    'From: deploy@app.test\n'
                    'To: team@app.test\n'
                    'Subject: Deployment successful\n'
                    'Date: Sat, 21 Mar 2026 09:45:00 +0000\n'
                    'X-Mailer: DevFlow/1.0',
                attachmentCount: 1,
                onBack: () {},
                onMarkRead: () {},
                onDelete: () {},
              ),
            ),
          ),

          // Polling Container
          Section(
            title: 'POLLING CONTAINER',
            child: EdenPollingContainer(
              interval: const Duration(seconds: 10),
              onRefresh: () async {},
              child: const Text('Dashboard data refreshes automatically'),
            ),
          ),

          const SizedBox(height: EdenSpacing.space8),
        ],
      ),
    );
  }
}
