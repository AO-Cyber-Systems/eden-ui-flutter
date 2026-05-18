import 'package:flutter/material.dart';

import '../../eden_ui.dart';
import '../_sample_data/sample_data.dart';

/// Catalog screen for the Companion Shell Foundation primitives
/// (objective 002). Hosts live demos for `EdenAppMode` (slider-driven
/// `resolveAppMode` preview + mode toggle) and future Wave-1/2/3
/// companion primitives.
class CompanionScreen extends StatefulWidget {
  const CompanionScreen({super.key});

  @override
  State<CompanionScreen> createState() => _CompanionScreenState();
}

class _CompanionScreenState extends State<CompanionScreen> {
  late final EdenAppModeController _controller;
  double _viewportWidth = 390;
  double _adaptiveDemoWidth = 390;
  bool _forceCompact = false;
  EdenGpsStatus _gpsStatus = EdenGpsStatus.high;
  double _gpsAccuracy = 5;
  String _shellVertical = 'trades';
  String _gpsVertical = 'trades';

  @override
  void initState() {
    super.initState();
    _controller = EdenAppModeController(initialMode: EdenAppMode.fieldCompanion);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Companion Shell')),
      body: EdenAppModeScope(
        controller: _controller,
        child: ListView(
          padding: const EdgeInsets.all(EdenSpacing.space4),
          children: [
            _Section(
              title: 'EdenAppMode controller + scope',
              child: _AppModeControllerDemo(controller: _controller),
            ),
            const SizedBox(height: EdenSpacing.space4),
            _Section(
              title: 'resolveAppMode (viewport-driven)',
              child: _ResolveAppModeDemo(
                viewportWidth: _viewportWidth,
                onWidthChanged: (v) => setState(() => _viewportWidth = v),
              ),
            ),
            const SizedBox(height: EdenSpacing.space4),
            _Section(
              title: 'EdenAdaptiveLayout demo',
              child: _AdaptiveLayoutDemo(
                width: _adaptiveDemoWidth,
                forceCompact: _forceCompact,
                onWidthChanged: (v) => setState(() => _adaptiveDemoWidth = v),
                onForceCompactChanged: (v) => setState(() => _forceCompact = v),
              ),
            ),
            const SizedBox(height: EdenSpacing.space4),
            _Section(
              title: 'EdenUxModeToggle demo',
              child: _UxModeToggleDemo(controller: _controller),
            ),
            const SizedBox(height: EdenSpacing.space4),
            _Section(
              title: 'EdenFieldViewGate demo',
              child: _FieldViewGateDemo(controller: _controller),
            ),
            const SizedBox(height: EdenSpacing.space4),
            _Section(
              title: 'EdenGpsStatusIndicator demo — vertical-realistic coords',
              child: _GpsStatusDemo(
                status: _gpsStatus,
                accuracy: _gpsAccuracy,
                vertical: _gpsVertical,
                onStatusChanged: (s) => setState(() => _gpsStatus = s),
                onAccuracyChanged: (a) => setState(() => _gpsAccuracy = a),
                onVerticalChanged: (v) => setState(() => _gpsVertical = v),
              ),
            ),
            const SizedBox(height: EdenSpacing.space4),
            _Section(
              title: 'EdenCompanionShell (Wave 3 composition) — pick vertical',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Mount the full shell live — flip the UX toggle inside '
                    'the shell to observe compact↔expanded layout swap. Use '
                    'the picker below to choose a vertical-flavored shell.',
                  ),
                  const SizedBox(height: EdenSpacing.space2),
                  Row(
                    children: <Widget>[
                      const Text('Vertical: '),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _shellVertical,
                          items: const <DropdownMenuItem<String>>[
                            DropdownMenuItem<String>(
                              value: 'trades',
                              child: Text('Trades — Dispatch'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'salon',
                              child: Text('Salon — Front-desk'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'fuel',
                              child: Text('Fuel — Driver'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'medical',
                              child: Text('Medical — Home visit'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'gov',
                              child: Text('Gov — Caseworker'),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _shellVertical = v);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: EdenSpacing.space2),
                  EdenButton(
                    label: 'Open EdenCompanionShell demo',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => _CompanionShellDemoPage(
                          controller: _controller,
                          vertical: _shellVertical,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompanionShellDemoPage extends StatefulWidget {
  const _CompanionShellDemoPage({
    required this.controller,
    required this.vertical,
  });
  final EdenAppModeController controller;
  final String vertical;

  @override
  State<_CompanionShellDemoPage> createState() =>
      _CompanionShellDemoPageState();
}

class _CompanionShellDemoPageState extends State<_CompanionShellDemoPage> {
  String _selectedNavId = 'home';

  @override
  Widget build(BuildContext context) {
    final cfg = _shellConfigFor(widget.vertical);
    return EdenAppModeScope(
      controller: widget.controller,
      child: EdenCompanionShell(
        greeting: cfg.greeting,
        roleLabel: cfg.role,
        rolePalette: cfg.palette,
        sections: cfg.sections,
        navItems: cfg.navItems,
        selectedNavId: _selectedNavId,
        onNavChanged: (id) => setState(() => _selectedNavId = id),
      ),
    );
  }
}

/// Per-vertical EdenCompanionShell configuration: greeting / role label /
/// palette / dashboard sections / bottom-nav items. Each variant pulls
/// realistic vertical-specific snippets from _sample_data/.
({
  String greeting,
  String role,
  EdenRolePalette palette,
  List<EdenDashboardSection> sections,
  List<EdenCompanionNavItem> navItems,
}) _shellConfigFor(String vertical) {
  switch (vertical) {
    case 'salon':
      return (
        greeting: 'Hey Marisol',
        role: 'Stylist',
        palette: EdenRolePalette.salon,
        sections: <EdenDashboardSection>[
          EdenDashboardSection(
            id: 'today',
            title: "Today's chairs",
            body: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                '${SalonScenarios.weekAppointments.length} appointments '
                'this week · cuts / color / chemical',
              ),
            ),
          ),
          const EdenDashboardSection(
            id: 'rebook',
            title: 'Rebook nudge',
            body: Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                '6 platinum clients overdue (avg cadence 6 weeks)',
              ),
            ),
          ),
        ],
        navItems: const <EdenCompanionNavItem>[
          EdenCompanionNavItem(
              id: 'home', label: 'Home', icon: Icons.home_outlined),
          EdenCompanionNavItem(
              id: 'appts', label: 'Appts', icon: Icons.event_available),
          EdenCompanionNavItem(
              id: 'clients', label: 'Clients', icon: Icons.people_outline),
          EdenCompanionNavItem(
              id: 'stock', label: 'Stock', icon: Icons.inventory_2_outlined),
          EdenCompanionNavItem(
              id: 'me', label: 'Me', icon: Icons.person_outline),
        ],
      );
    case 'fuel':
      return (
        greeting: 'Manny',
        role: 'Driver',
        palette: EdenRolePalette.fuel,
        sections: const <EdenDashboardSection>[
          EdenDashboardSection(
            id: 'route',
            title: 'Route today',
            body: Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Route A · 4 stops · Diesel #2 · Truck T7',
              ),
            ),
          ),
          EdenDashboardSection(
            id: 'tanks',
            title: 'Tank readings due',
            body: Padding(
              padding: EdgeInsets.all(8),
              child: Text('3 outpost tanks · log at each stop'),
            ),
          ),
        ],
        navItems: const <EdenCompanionNavItem>[
          EdenCompanionNavItem(
              id: 'home', label: 'Home', icon: Icons.home_outlined),
          EdenCompanionNavItem(
              id: 'route', label: 'Route', icon: Icons.alt_route),
          EdenCompanionNavItem(
              id: 'truck',
              label: 'Truck',
              icon: Icons.local_shipping_outlined),
          EdenCompanionNavItem(
              id: 'logs', label: 'Logs', icon: Icons.list_alt),
          EdenCompanionNavItem(
              id: 'me', label: 'Me', icon: Icons.person_outline),
        ],
      );
    case 'medical':
      return (
        greeting: 'Dr. Patel',
        role: 'Home Visit',
        palette: EdenRolePalette.medical,
        sections: <EdenDashboardSection>[
          EdenDashboardSection(
            id: 'visits',
            title: 'Visits today',
            body: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                '${MedicalScenarios.weekVisits.length} visits this week '
                '· next: MRN 44291 (diabetes panel)',
              ),
            ),
          ),
          const EdenDashboardSection(
            id: 'consents',
            title: 'Pending consents',
            body: Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'MRN 51208 — HIPAA + ROI · capture before visit',
              ),
            ),
          ),
        ],
        navItems: const <EdenCompanionNavItem>[
          EdenCompanionNavItem(
              id: 'home', label: 'Home', icon: Icons.home_outlined),
          EdenCompanionNavItem(
              id: 'visits',
              label: 'Visits',
              icon: Icons.medical_services_outlined),
          EdenCompanionNavItem(
              id: 'patients',
              label: 'Patients',
              icon: Icons.people_outline),
          EdenCompanionNavItem(
              id: 'labs', label: 'Labs', icon: Icons.science_outlined),
          EdenCompanionNavItem(
              id: 'me', label: 'Me', icon: Icons.person_outline),
        ],
      );
    case 'gov':
      return (
        greeting: 'Caseworker Sørensen',
        role: 'Case Reviewer',
        palette: EdenRolePalette.gov,
        sections: const <EdenDashboardSection>[
          EdenDashboardSection(
            id: 'queue',
            title: 'Open cases',
            body: Padding(
              padding: EdgeInsets.all(8),
              child: Text('247 open · 4 SLA breaches today'),
            ),
          ),
          EdenDashboardSection(
            id: 'today',
            title: "Today's docket",
            body: Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Case review CCM-2026-0427 · 09:00–10:30',
              ),
            ),
          ),
        ],
        navItems: const <EdenCompanionNavItem>[
          EdenCompanionNavItem(
              id: 'home', label: 'Home', icon: Icons.home_outlined),
          EdenCompanionNavItem(
              id: 'cases', label: 'Cases', icon: Icons.folder_open_outlined),
          EdenCompanionNavItem(
              id: 'board', label: 'Board', icon: Icons.gavel),
          EdenCompanionNavItem(
              id: 'docs', label: 'Docs', icon: Icons.description_outlined),
          EdenCompanionNavItem(
              id: 'me', label: 'Me', icon: Icons.person_outline),
        ],
      );
    case 'trades':
    default:
      return (
        greeting: 'Good morning, Alice',
        role: 'Field Tech',
        palette: EdenRolePalette.trades,
        sections: <EdenDashboardSection>[
          EdenDashboardSection(
            id: 'today',
            title: "Today's stops",
            body: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                '${TradesScenarios.weekEvents.length} jobs this week · '
                'next: ${TradesScenarios.weekEvents.first.title}',
              ),
            ),
          ),
          const EdenDashboardSection(
            id: 'blockers',
            title: 'Blocked work',
            body: Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                '3 blockers · permit / survey / parts',
              ),
            ),
          ),
          const EdenDashboardSection(
            id: 'insights',
            title: 'AI insights',
            body: Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Look-ahead routing — save ~38 driving minutes Thu',
              ),
            ),
          ),
        ],
        navItems: const <EdenCompanionNavItem>[
          EdenCompanionNavItem(
              id: 'home', label: 'Home', icon: Icons.home_outlined),
          EdenCompanionNavItem(
              id: 'jobs', label: 'Jobs', icon: Icons.build_outlined),
          EdenCompanionNavItem(
              id: 'schedule',
              label: 'Schedule',
              icon: Icons.calendar_today_outlined),
          EdenCompanionNavItem(
              id: 'parts',
              label: 'Parts',
              icon: Icons.inventory_2_outlined),
          EdenCompanionNavItem(
              id: 'me', label: 'Me', icon: Icons.person_outline),
        ],
      );
  }
}

class _GpsStatusDemo extends StatelessWidget {
  const _GpsStatusDemo({
    required this.status,
    required this.accuracy,
    required this.vertical,
    required this.onStatusChanged,
    required this.onAccuracyChanged,
    required this.onVerticalChanged,
  });

  final EdenGpsStatus status;
  final double accuracy;
  final String vertical;
  final ValueChanged<EdenGpsStatus> onStatusChanged;
  final ValueChanged<double> onAccuracyChanged;
  final ValueChanged<String> onVerticalChanged;

  /// Vertical-realistic GPS coordinates for the demo cycle:
  /// - trades:  Atlanta suburb (Marietta job site)
  /// - salon:   NYC retail (Bleecker St)
  /// - fuel:    Chicago industrial outskirt
  /// - medical: Atlanta home-visit (Lullwater Rd)
  /// - gov:     Cobb County campus
  EdenLatLng _coordsFor(String v) {
    switch (v) {
      case 'salon':
        return const EdenLatLng(lat: 40.7281, lng: -73.9942);
      case 'fuel':
        return const EdenLatLng(lat: 41.8497, lng: -87.7449);
      case 'medical':
        return const EdenLatLng(lat: 33.7704, lng: -84.3329);
      case 'gov':
        return const EdenLatLng(lat: 33.9526, lng: -84.5499);
      case 'trades':
      default:
        return const EdenLatLng(lat: 33.9526, lng: -84.5499);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Text('Vertical: '),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButton<String>(
                isExpanded: true,
                value: vertical,
                onChanged: (v) {
                  if (v != null) onVerticalChanged(v);
                },
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(
                      value: 'trades', child: Text('Trades (Marietta)')),
                  DropdownMenuItem<String>(
                      value: 'salon', child: Text('Salon (NYC)')),
                  DropdownMenuItem<String>(
                      value: 'fuel', child: Text('Fuel (Chicago)')),
                  DropdownMenuItem<String>(
                      value: 'medical', child: Text('Medical (Atlanta)')),
                  DropdownMenuItem<String>(
                      value: 'gov', child: Text('Gov (Cobb)')),
                ],
              ),
            ),
          ],
        ),
        Row(
          children: <Widget>[
            const Text('Status: '),
            Expanded(
              child: DropdownButton<EdenGpsStatus>(
                isExpanded: true,
                value: status,
                onChanged: (v) {
                  if (v != null) onStatusChanged(v);
                },
                items: <DropdownMenuItem<EdenGpsStatus>>[
                  for (final s in EdenGpsStatus.values)
                    DropdownMenuItem<EdenGpsStatus>(
                        value: s, child: Text(s.name)),
                ],
              ),
            ),
          ],
        ),
        Text('Accuracy: ${accuracy.round()} m'),
        Slider(
          value: accuracy,
          min: 0,
          max: 100,
          divisions: 100,
          label: '${accuracy.round()} m',
          onChanged: onAccuracyChanged,
        ),
        const SizedBox(height: EdenSpacing.space2),
        const Text(
          'Mode-aware: flip the UX toggle above. admin → coords hidden; '
          'fieldCompanion/askUser → coords visible.',
        ),
        const SizedBox(height: EdenSpacing.space2),
        EdenGpsStatusIndicator(
          status: status,
          accuracyMeters: status == EdenGpsStatus.unavailable ? null : accuracy,
          position:
              status == EdenGpsStatus.unavailable ? null : _coordsFor(vertical),
        ),
      ],
    );
  }
}

class _FieldViewGateDemo extends StatelessWidget {
  const _FieldViewGateDemo({required this.controller});
  final EdenAppModeController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Flip the mode toggle above to swap which card is visible.',
        ),
        const SizedBox(height: EdenSpacing.space3),
        EdenFieldViewGate.companionOnly(
          fallback: const _GateCard(
            icon: Icons.visibility_off,
            label: 'Companion card hidden — not in field mode',
          ),
          child: const _GateCard(
            icon: Icons.smartphone,
            label: 'Companion-only widget',
          ),
        ),
        const SizedBox(height: EdenSpacing.space2),
        EdenFieldViewGate.adminOnly(
          fallback: const _GateCard(
            icon: Icons.visibility_off,
            label: 'Admin card hidden — not in admin mode',
          ),
          child: const _GateCard(
            icon: Icons.desktop_windows,
            label: 'Admin-only widget',
          ),
        ),
      ],
    );
  }
}

class _GateCard extends StatelessWidget {
  const _GateCard({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return EdenCard(
      child: Padding(
        padding: const EdgeInsets.all(EdenSpacing.space3),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            Expanded(child: Text(label)),
          ],
        ),
      ),
    );
  }
}

class _UxModeToggleDemo extends StatelessWidget {
  const _UxModeToggleDemo({required this.controller});
  final EdenAppModeController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Active mode: ${controller.currentMode.name}'),
            const SizedBox(height: EdenSpacing.space3),
            const Text('Compact (icon-only):'),
            const SizedBox(height: EdenSpacing.space2),
            EdenUxModeToggle.compact(controller: controller),
            const SizedBox(height: EdenSpacing.space3),
            const Text('Labeled (icon + text):'),
            const SizedBox(height: EdenSpacing.space2),
            EdenUxModeToggle.labeled(controller: controller),
          ],
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return EdenCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: EdenSpacing.space3),
          child,
        ],
      ),
    );
  }
}

class _AppModeControllerDemo extends StatelessWidget {
  const _AppModeControllerDemo({required this.controller});
  final EdenAppModeController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current mode: ${controller.currentMode.name}'),
            const SizedBox(height: EdenSpacing.space3),
            Wrap(
              spacing: 8,
              children: [
                for (final m in EdenAppMode.values)
                  ChoiceChip(
                    label: Text(m.name),
                    selected: controller.currentMode == m,
                    onSelected: (_) => controller.setMode(m),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _AdaptiveLayoutDemo extends StatelessWidget {
  const _AdaptiveLayoutDemo({
    required this.width,
    required this.forceCompact,
    required this.onWidthChanged,
    required this.onForceCompactChanged,
  });

  final double width;
  final bool forceCompact;
  final ValueChanged<double> onWidthChanged;
  final ValueChanged<bool> onForceCompactChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Demo width: ${width.round()}pt'),
        Slider(
          value: width,
          min: 320,
          max: 1600,
          divisions: 128,
          label: '${width.round()}pt',
          onChanged: onWidthChanged,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('forceCompact'),
          value: forceCompact,
          onChanged: onForceCompactChanged,
        ),
        const SizedBox(height: EdenSpacing.space2),
        SizedBox(
          width: width,
          height: 80,
          child: EdenAdaptiveLayout(
            forceCompact: forceCompact,
            compactBuilder: (_) => _TierBadge(
              tier: 'Compact (<600pt)',
              color: Colors.blue.shade100,
            ),
            mediumBuilder: (_) => _TierBadge(
              tier: 'Medium (600–840pt)',
              color: Colors.amber.shade100,
            ),
            expandedBuilder: (_) => _TierBadge(
              tier: 'Expanded (≥840pt)',
              color: Colors.green.shade100,
            ),
          ),
        ),
      ],
    );
  }
}

class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.tier, required this.color});
  final String tier;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(tier, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class _ResolveAppModeDemo extends StatelessWidget {
  const _ResolveAppModeDemo({
    required this.viewportWidth,
    required this.onWidthChanged,
  });

  final double viewportWidth;
  final ValueChanged<double> onWidthChanged;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveAppMode(
      viewport: Size(viewportWidth, 800),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Viewport width: ${viewportWidth.round()}pt'),
        Slider(
          value: viewportWidth,
          min: 320,
          max: 1600,
          divisions: 128,
          label: '${viewportWidth.round()}pt',
          onChanged: onWidthChanged,
        ),
        Text('resolveAppMode → ${resolved.name}'),
        const SizedBox(height: EdenSpacing.space2),
        Text(
          'Compact (<600): fieldCompanion · Medium (600–840): askUser · '
          'Expanded (≥840): admin',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
