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
          _MobileAiFabDemo(),
          // Wave 2 — GPS-aware pages
          _CheckInPageDemo(),
          _LocationMapPageDemo(),
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

class _MobileAiFabDemo extends StatefulWidget {
  const _MobileAiFabDemo();
  @override
  State<_MobileAiFabDemo> createState() => _MobileAiFabDemoState();
}

class _MobileAiFabDemoState extends State<_MobileAiFabDemo> {
  EdenAiPersona _persona = EdenAiPersona.fieldTech;
  String _lastSent = '—';

  Stream<EdenChatStreamChunk> _echoSender(EdenChatRequest req) async* {
    setState(() => _lastSent = req.content);
    yield EdenChatStreamChunk(
        type: EdenChatChunkType.content, content: 'Echo: ${req.content}');
    yield const EdenChatStreamChunk(type: EdenChatChunkType.done);
  }

  Future<String> _inertCreate(
          {required String personaId, required String title}) async =>
      'conv-demo';

  @override
  Widget build(BuildContext context) {
    return Section(
      title: 'EdenMobileAiFab + EdenMobileAiChatSheet',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('Tap the FAB to open the chat sheet'),
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: EdenMobileAiFab(
                    pageContext: 'mobile_home',
                    entityType: 'appointment',
                    entityId: 'apt-123',
                    entityLabel: 'Smith Job — 9:00 AM',
                    activePersona: _persona,
                    onPersonaChanged: (p) => setState(() => _persona = p),
                    sendMessage: _echoSender,
                    createConversation: _inertCreate,
                    quickActions: const [
                      EdenMobileAiQuickAction(
                          label: 'Find Parts', icon: Icons.search),
                      EdenMobileAiQuickAction(
                          label: 'Equipment Info',
                          icon: Icons.info_outline),
                      EdenMobileAiQuickAction(
                          label: 'Report Issue',
                          icon: Icons.report_outlined),
                    ],
                    unreadCount: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('Last sent: $_lastSent'),
        ],
      ),
    );
  }
}

class _LocationMapPageDemo extends StatelessWidget {
  const _LocationMapPageDemo();
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Section(
      title: 'EdenLocationMapPage',
      child: SizedBox(
        height: 600,
        child: EdenLocationMapPage(
          provider: const NoOpMapProvider(),
          pins: [
            EdenLocationPin(
              id: 'demo-1',
              name: 'Mike T.',
              position: const EdenLatLng(lat: 37.7749, lng: -122.4194),
              accuracyMeters: 12,
              batteryLevel: 78,
              lastSeenAt: now.subtract(const Duration(minutes: 3)),
            ),
            EdenLocationPin(
              id: 'demo-2',
              name: 'Sarah K.',
              position: const EdenLatLng(lat: 37.7849, lng: -122.4094),
              accuracyMeters: 8,
              batteryLevel: 92,
              lastSeenAt: now.subtract(const Duration(seconds: 45)),
            ),
            EdenLocationPin(
              id: 'demo-3',
              name: 'Christopher M.',
              position: const EdenLatLng(lat: 37.7949, lng: -122.3994),
              accuracyMeters: 25,
              batteryLevel: 22,
              lastSeenAt: now.subtract(const Duration(hours: 2)),
            ),
          ],
          onPinTapped: (id) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Demo pin tap: $id')),
          ),
          onRefresh: () {},
          appBarTitle: 'Active Technicians',
        ),
      ),
    );
  }
}

class _CheckInPageDemo extends StatelessWidget {
  const _CheckInPageDemo();
  @override
  Widget build(BuildContext context) {
    return Section(
      title: 'EdenCheckInPage',
      child: SizedBox(
        height: 600,
        child: EdenCheckInPage(
          appointment: const EdenCheckInAppointment(
            id: 'apt-123',
            title: 'HVAC Repair — Johnson',
            address: '742 Evergreen Terrace',
            icon: Icons.event_available,
          ),
          gpsStatus: EdenGpsStatus.high,
          gpsAccuracyMeters: 5.2,
          gpsPosition: const EdenLatLng(lat: 37.7749, lng: -122.4194),
          events: [
            EdenCheckInEvent(
              id: 'demo-e1',
              type: EdenCheckInEventType.checkIn,
              timestamp: DateTime.now()
                  .subtract(const Duration(hours: 1, minutes: 5)),
              isGeofenceVerified: true,
            ),
          ],
          onSubmit: (s) async {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Demo submit: ${s.type.name}')),
            );
          },
        ),
      ),
    );
  }
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
