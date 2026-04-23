import 'package:flutter/material.dart';
import '../../eden_ui.dart';
import '../widgets/section.dart';

class DevflowInfraScreen extends StatelessWidget {
  const DevflowInfraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('DevFlow — Infrastructure'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        children: [
          // Live Indicator
          const Section(
            title: 'LIVE INDICATOR',
            child: Row(
              children: [
                EdenLiveIndicator(
                  state: EdenConnectionState.connected,
                  label: 'API',
                ),
                SizedBox(width: EdenSpacing.space6),
                EdenLiveIndicator(
                  state: EdenConnectionState.disconnected,
                  label: 'WebSocket',
                ),
                SizedBox(width: EdenSpacing.space6),
                EdenLiveIndicator(
                  state: EdenConnectionState.reconnecting,
                  label: 'Database',
                ),
              ],
            ),
          ),

          // Services
          Section(
            title: 'SERVICES',
            child: Column(
              children: [
                EdenServiceRow(
                  name: 'PostgreSQL',
                  description: 'Database server',
                  status: EdenServiceStatus.running,
                  onStop: () {},
                  onRestart: () {},
                ),
                EdenServiceRow(
                  name: 'Redis',
                  description: 'Cache layer',
                  status: EdenServiceStatus.stopped,
                  onStart: () {},
                ),
                const EdenServiceRow(
                  name: 'Nginx',
                  description: 'Reverse proxy',
                  status: EdenServiceStatus.error,
                  version: '1.25.3',
                ),
              ],
            ),
          ),

          // Ports
          Section(
            title: 'PORTS',
            child: Column(
              children: [
                EdenPortRow(
                  port: 3000,
                  process: 'ruby',
                  pid: '1234',
                  onKill: () {},
                ),
                EdenPortRow(
                  port: 5432,
                  process: 'postgres',
                  pid: '5678',
                  onKill: () {},
                ),
                EdenPortRow(
                  port: 6379,
                  process: 'redis',
                  pid: '9012',
                  onKill: () {},
                ),
              ],
            ),
          ),

          // Domains
          const Section(
            title: 'DOMAINS',
            child: Column(
              children: [
                EdenDomainRow(
                  domain: 'app.test',
                  sslStatus: EdenSslStatus.valid,
                  sslExpiry: '2027-06-15',
                  dnsStatus: EdenDnsStatus.resolved,
                ),
                EdenDomainRow(
                  domain: 'api.test',
                  sslStatus: EdenSslStatus.expiringSoon,
                  sslExpiry: '2026-04-01',
                  dnsStatus: EdenDnsStatus.resolved,
                ),
                EdenDomainRow(
                  domain: '*.staging.test',
                  isWildcard: true,
                  sslStatus: EdenSslStatus.expired,
                  dnsStatus: EdenDnsStatus.warning,
                ),
              ],
            ),
          ),

          // Certificate
          Section(
            title: 'CERTIFICATE',
            child: EdenCertificateCard(
              subject: '*.app.test',
              issuer: 'mkcert',
              expiry: '2027-01-15',
              status: EdenCertificateStatus.valid,
              onRegenerate: () {},
            ),
          ),

          // Health Checks
          Section(
            title: 'HEALTH CHECKS',
            child: Column(
              children: [
                const EdenHealthCheck(
                  name: 'Node.js',
                  category: 'Runtime',
                  status: EdenHealthCheckStatus.pass,
                ),
                const EdenHealthCheck(
                  name: 'Docker',
                  category: 'Container',
                  status: EdenHealthCheckStatus.warn,
                  fixHint: 'brew install docker',
                ),
                EdenHealthCheck(
                  name: 'PostgreSQL',
                  category: 'Database',
                  status: EdenHealthCheckStatus.fail,
                  fixHint: 'brew install postgresql@16',
                  onInstall: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: EdenSpacing.space8),
        ],
      ),
    );
  }
}
