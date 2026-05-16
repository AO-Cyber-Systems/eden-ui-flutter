// lib/dev_app/screens/composers_screen.dart
//
// Objective 008 Wave 3 (TRD 008-06) — dedicated catalog screen for the
// Wave-3 composer widgets from objective 001:
//
//   - EdenConsentFlow         (multi-step consent: clauses → signature → witness → review)
//   - EdenIntakeForm          (branching questionnaire)
//   - EdenRoleDashboardShell  (role-specific home shell with sections)
//   - EdenStarterTemplateCard (per-vertical starter cards)
//   - EdenContextualTip       (inline help tip)
//   - EdenAppTourOverlay      (multi-stop guided tour)
//
// All clause / question / starter content sourced from
// lib/dev_app/_sample_data/. NO inline AI-generated records.

import 'package:flutter/material.dart';

import '../../eden_ui.dart';
import '../_sample_data/sample_data.dart';
import '../widgets/section.dart';

class ComposersScreen extends StatelessWidget {
  const ComposersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Composers')),
      body: ListView(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        children: const <Widget>[
          EdenDivider(label: 'EdenConsentFlow — cross-vertical scenarios'),
          Section(
            title: 'Medical procedure consent (5 clauses + witness)',
            child: _MedicalConsentDemo(),
          ),
          Section(
            title: 'Legal retainer consent (3 clauses)',
            child: _LegalConsentDemo(),
          ),
          Section(
            title: 'Gov disclosure consent (Tier-2 attestation)',
            child: _GovConsentDemo(),
          ),

          EdenDivider(label: 'EdenIntakeForm — cross-vertical scenarios'),
          Section(
            title: 'Medical patient intake (8 questions, 1 branching)',
            child: _MedicalIntakeDemo(),
          ),
          Section(
            title: 'Salon client intake (4 questions)',
            child: _SalonIntakeDemo(),
          ),
          Section(
            title: 'Gov case-opening intake (5 questions)',
            child: _GovIntakeDemo(),
          ),

          EdenDivider(label: 'EdenRoleDashboardShell — 4 vertical roles'),
          Section(
            title: 'Trades dispatcher',
            child: _TradesDispatcherShellDemo(),
          ),
          Section(
            title: 'Salon owner',
            child: _SalonOwnerShellDemo(),
          ),
          Section(
            title: 'Medical nurse',
            child: _MedicalNurseShellDemo(),
          ),
          Section(
            title: 'Gov supervisor',
            child: _GovSupervisorShellDemo(),
          ),

          EdenDivider(label: 'EdenStarterTemplateCard — per-vertical starters'),
          Section(
            title: '5 vertical starter cards (horizontal scroll)',
            child: _StarterCardsRow(),
          ),

          EdenDivider(label: 'EdenContextualTip + EdenAppTourOverlay'),
          Section(
            title: 'Onboarding triplet — tap "Start tour" to step through 3 spots',
            child: _OnboardingTripletDemo(),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// EdenConsentFlow demos
// =============================================================================

class _MedicalConsentDemo extends StatefulWidget {
  const _MedicalConsentDemo();
  @override
  State<_MedicalConsentDemo> createState() => _MedicalConsentDemoState();
}

class _MedicalConsentDemoState extends State<_MedicalConsentDemo> {
  int _resetKey = 0;
  DateTime? _completedAt;

  @override
  Widget build(BuildContext context) {
    if (_completedAt != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Completed at: $_completedAt'),
          TextButton(
            onPressed: () => setState(() {
              _resetKey++;
              _completedAt = null;
            }),
            child: const Text('Restart demo'),
          ),
        ],
      );
    }
    return SizedBox(
      height: 540,
      child: EdenConsentFlow(
        key: ValueKey<String>('medical-consent-$_resetKey'),
        clauses: <EdenConsentClause>[
          for (final c in MedicalScenarios.consentClauses)
            EdenConsentClause(
              id: c.id,
              title: c.title,
              body: c.body,
              requireAffirmation: c.required,
            ),
        ],
        requireWitness: true,
        onComplete: (_) => setState(() => _completedAt = DateTime.now()),
      ),
    );
  }
}

class _LegalConsentDemo extends StatefulWidget {
  const _LegalConsentDemo();
  @override
  State<_LegalConsentDemo> createState() => _LegalConsentDemoState();
}

class _LegalConsentDemoState extends State<_LegalConsentDemo> {
  int _resetKey = 0;
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return TextButton(
        onPressed: () => setState(() {
          _done = false;
          _resetKey++;
        }),
        child: const Text('Restart demo'),
      );
    }
    return SizedBox(
      height: 500,
      child: EdenConsentFlow(
        key: ValueKey<String>('legal-consent-$_resetKey'),
        clauses: const <EdenConsentClause>[
          EdenConsentClause(
            id: 'retainer',
            title: 'Retainer Agreement',
            body:
                'Client engages Firm for legal services described in '
                'Schedule A. Hourly rate \$425, retainer \$5,000 to be applied '
                'against monthly invoices.',
            requireAffirmation: true,
          ),
          EdenConsentClause(
            id: 'conflict',
            title: 'Conflicts of Interest Disclosure',
            body:
                'Client acknowledges receipt of conflict-check results and '
                'consents to representation notwithstanding any disclosed '
                'matters.',
          ),
          EdenConsentClause(
            id: 'fees',
            title: 'Fee Schedule Acknowledgement',
            body:
                'Client has reviewed and agrees to the fee schedule including '
                'expenses, filing fees, and expert witness rates.',
          ),
        ],
        onComplete: (_) => setState(() => _done = true),
      ),
    );
  }
}

class _GovConsentDemo extends StatefulWidget {
  const _GovConsentDemo();
  @override
  State<_GovConsentDemo> createState() => _GovConsentDemoState();
}

class _GovConsentDemoState extends State<_GovConsentDemo> {
  int _resetKey = 0;
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return TextButton(
        onPressed: () => setState(() {
          _done = false;
          _resetKey++;
        }),
        child: const Text('Restart demo'),
      );
    }
    return SizedBox(
      height: 540,
      child: EdenConsentFlow(
        key: ValueKey<String>('gov-consent-$_resetKey'),
        requireWitness: true,
        clauses: const <EdenConsentClause>[
          EdenConsentClause(
            id: 'tier2',
            title: 'Tier-2 Case File Access Attestation',
            body:
                'Caseworker affirms that access to case CCM-2026-0427 is '
                'in support of an authorized review and that contents will '
                'not be discussed outside cleared personnel.',
            requireAffirmation: true,
          ),
          EdenConsentClause(
            id: 'foia',
            title: 'FOIA Hold Acknowledgement',
            body:
                'Caseworker confirms they will preserve all working papers '
                'related to this case for the duration of any FOIA hold.',
          ),
          EdenConsentClause(
            id: 'audit',
            title: 'Audit Trail Notice',
            body:
                'All actions taken on this case will be logged and reviewable '
                'by supervisory staff and compliance.',
          ),
        ],
        onComplete: (_) => setState(() => _done = true),
      ),
    );
  }
}

// =============================================================================
// EdenIntakeForm demos
// =============================================================================

class _MedicalIntakeDemo extends StatefulWidget {
  const _MedicalIntakeDemo();
  @override
  State<_MedicalIntakeDemo> createState() => _MedicalIntakeDemoState();
}

class _MedicalIntakeDemoState extends State<_MedicalIntakeDemo> {
  int _resetKey = 0;
  Map<String, dynamic>? _answers;

  @override
  Widget build(BuildContext context) {
    if (_answers != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Completed with ${_answers!.length} answers',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          for (final entry in _answers!.entries)
            Text('• ${entry.key}: ${entry.value}'),
          TextButton(
            onPressed: () => setState(() {
              _answers = null;
              _resetKey++;
            }),
            child: const Text('Restart'),
          ),
        ],
      );
    }
    return SizedBox(
      height: 380,
      child: EdenIntakeForm(
        key: ValueKey<String>('medical-intake-$_resetKey'),
        questions: <EdenIntakeQuestion>[
          for (final q in MedicalScenarios.intakeQuestions)
            EdenIntakeQuestion(
              id: q.id,
              label: q.prompt,
              type: _mapIntakeType(q.type),
              options: q.options,
              required: q.required,
              visibleWhen: q.visibleWhenAnswerId == null
                  ? null
                  : (answers) =>
                      answers[q.visibleWhenAnswerId] ==
                      q.visibleWhenAnswerEquals,
            ),
        ],
        onComplete: (a) => setState(() => _answers = a),
      ),
    );
  }
}

class _SalonIntakeDemo extends StatefulWidget {
  const _SalonIntakeDemo();
  @override
  State<_SalonIntakeDemo> createState() => _SalonIntakeDemoState();
}

class _SalonIntakeDemoState extends State<_SalonIntakeDemo> {
  int _resetKey = 0;
  bool _done = false;
  @override
  Widget build(BuildContext context) {
    if (_done) {
      return TextButton(
        onPressed: () => setState(() {
          _done = false;
          _resetKey++;
        }),
        child: const Text('Restart'),
      );
    }
    return SizedBox(
      height: 360,
      child: EdenIntakeForm(
        key: ValueKey<String>('salon-intake-$_resetKey'),
        questions: const <EdenIntakeQuestion>[
          EdenIntakeQuestion(
            id: 'name',
            label: 'Preferred name',
            type: EdenIntakeQuestionType.text,
            required: true,
          ),
          EdenIntakeQuestion(
            id: 'service',
            label: 'Service today',
            type: EdenIntakeQuestionType.singleChoice,
            options: <String>['Cut', 'Color', 'Balayage', 'Chemical', 'Updo'],
            required: true,
          ),
          EdenIntakeQuestion(
            id: 'allergies',
            label: 'Sensitivities or allergies',
            type: EdenIntakeQuestionType.longText,
          ),
          EdenIntakeQuestion(
            id: 'rebook',
            label: 'Want a rebook reminder?',
            type: EdenIntakeQuestionType.yesNo,
          ),
        ],
        onComplete: (_) => setState(() => _done = true),
      ),
    );
  }
}

class _GovIntakeDemo extends StatefulWidget {
  const _GovIntakeDemo();
  @override
  State<_GovIntakeDemo> createState() => _GovIntakeDemoState();
}

class _GovIntakeDemoState extends State<_GovIntakeDemo> {
  int _resetKey = 0;
  bool _done = false;
  @override
  Widget build(BuildContext context) {
    if (_done) {
      return TextButton(
        onPressed: () => setState(() {
          _done = false;
          _resetKey++;
        }),
        child: const Text('Restart'),
      );
    }
    return SizedBox(
      height: 360,
      child: EdenIntakeForm(
        key: ValueKey<String>('gov-intake-$_resetKey'),
        questions: const <EdenIntakeQuestion>[
          EdenIntakeQuestion(
            id: 'caseType',
            label: 'Case type',
            type: EdenIntakeQuestionType.singleChoice,
            options: <String>['Tier 1', 'Tier 2', 'Tier 3', 'Compliance'],
            required: true,
          ),
          EdenIntakeQuestion(
            id: 'priority',
            label: 'Priority',
            type: EdenIntakeQuestionType.singleChoice,
            options: <String>['Routine', 'High', 'Critical'],
            required: true,
          ),
          EdenIntakeQuestion(
            id: 'narrative',
            label: 'Summary of the case',
            type: EdenIntakeQuestionType.longText,
            required: true,
          ),
          EdenIntakeQuestion(
            id: 'classified',
            label: 'Contains classified material?',
            type: EdenIntakeQuestionType.yesNo,
            required: true,
          ),
          EdenIntakeQuestion(
            id: 'compartments',
            label: 'Compartments (comma-separated)',
            type: EdenIntakeQuestionType.text,
          ),
        ],
        onComplete: (_) => setState(() => _done = true),
      ),
    );
  }
}

EdenIntakeQuestionType _mapIntakeType(String t) {
  switch (t) {
    case 'longText':
      return EdenIntakeQuestionType.longText;
    case 'singleChoice':
      return EdenIntakeQuestionType.singleChoice;
    case 'multipleChoice':
      return EdenIntakeQuestionType.multipleChoice;
    case 'number':
      return EdenIntakeQuestionType.number;
    case 'date':
      return EdenIntakeQuestionType.date;
    case 'yesNo':
      return EdenIntakeQuestionType.yesNo;
    case 'text':
    default:
      return EdenIntakeQuestionType.text;
  }
}

// =============================================================================
// EdenRoleDashboardShell demos
// =============================================================================

class _TradesDispatcherShellDemo extends StatelessWidget {
  const _TradesDispatcherShellDemo();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 480,
      child: EdenRoleDashboardShell(
        greeting: 'Good morning, Sarah',
        roleLabel: 'Dispatcher',
        rolePalette: EdenRolePalette.trades,
        avatar: const CircleAvatar(child: Text('SD')),
        sections: <EdenDashboardSection>[
          EdenDashboardSection(
            id: 'today',
            title: "Today's jobs",
            priority: EdenDashboardSectionPriority.high,
            body: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                '${TradesScenarios.weekEvents.length} jobs this week · '
                'next: ${TradesScenarios.weekEvents.first.title}',
              ),
            ),
          ),
          const EdenDashboardSection(
            id: 'alerts',
            title: 'Blocking',
            body: EdenBlockingAlerts(
              alerts: TradesScenarios.blockingAlerts,
            ),
          ),
          const EdenDashboardSection(
            id: 'insights',
            title: 'AI insights',
            body: Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Re-routing Bob to Cobb Thursday saves ~38 minutes.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SalonOwnerShellDemo extends StatelessWidget {
  const _SalonOwnerShellDemo();
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 420,
      child: EdenRoleDashboardShell(
        greeting: 'Hey Maya',
        roleLabel: 'Owner',
        rolePalette: EdenRolePalette.salon,
        sections: <EdenDashboardSection>[
          EdenDashboardSection(
            id: 'today',
            title: "Today's chairs",
            body: Padding(
              padding: EdgeInsets.all(8),
              child: Text('8 appointments · 4 stylists on floor'),
            ),
          ),
          EdenDashboardSection(
            id: 'rev',
            title: 'Revenue pulse',
            body: Padding(
              padding: EdgeInsets.all(8),
              child: Text(r'$4,250 booked today · $148 avg ticket'),
            ),
          ),
          EdenDashboardSection(
            id: 'stock',
            title: 'Low stock',
            body: Padding(
              padding: EdgeInsets.all(8),
              child: Text('2 bottles · Redken bonding shampoo (reorder=4)'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicalNurseShellDemo extends StatelessWidget {
  const _MedicalNurseShellDemo();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 420,
      child: EdenRoleDashboardShell(
        greeting: 'Hi Rosa',
        roleLabel: 'Visit Nurse',
        rolePalette: EdenRolePalette.medical,
        sections: <EdenDashboardSection>[
          EdenDashboardSection(
            id: 'visits',
            title: 'Visits today',
            priority: EdenDashboardSectionPriority.high,
            body: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                '${MedicalScenarios.weekVisits.length} visits this week '
                '· first: MRN 51208 (wound care)',
              ),
            ),
          ),
          const EdenDashboardSection(
            id: 'consents',
            title: 'Pending consents',
            body: Padding(
              padding: EdgeInsets.all(8),
              child: Text('MRN 51208 — HIPAA + ROI'),
            ),
          ),
          const EdenDashboardSection(
            id: 'supplies',
            title: 'Visit kit',
            body: Padding(
              padding: EdgeInsets.all(8),
              child: Text('Needles (4 / reorder=6) — re-up before next visit'),
            ),
          ),
        ],
      ),
    );
  }
}

class _GovSupervisorShellDemo extends StatelessWidget {
  const _GovSupervisorShellDemo();
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 420,
      child: EdenRoleDashboardShell(
        greeting: 'Good morning, Hiroshi',
        roleLabel: 'Supervisor',
        rolePalette: EdenRolePalette.gov,
        sections: <EdenDashboardSection>[
          EdenDashboardSection(
            id: 'queue',
            title: 'Open cases',
            priority: EdenDashboardSectionPriority.high,
            body: Padding(
              padding: EdgeInsets.all(8),
              child: Text('247 open · 4 SLA breaches today'),
            ),
          ),
          EdenDashboardSection(
            id: 'approvals',
            title: 'Awaiting your sign-off',
            body: Padding(
              padding: EdgeInsets.all(8),
              child: Text('11 cases — board meeting Tuesday 2pm'),
            ),
          ),
          EdenDashboardSection(
            id: 'audit',
            title: 'Quarterly audit',
            body: Padding(
              padding: EdgeInsets.all(8),
              child: Text('Friday 1pm · 4hr block'),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// EdenStarterTemplateCard demos
// =============================================================================

class _StarterCardsRow extends StatelessWidget {
  const _StarterCardsRow();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: const <Widget>[
          EdenStarterTemplateCard(
            title: 'Trades · Job template',
            description: 'HVAC service call · pre-filled with truck + crew',
            thumbnail: Icon(Icons.build, size: 32),
            effortLabel: '~5 min',
          ),
          SizedBox(width: 12),
          EdenStarterTemplateCard(
            title: 'Salon · New service',
            description: 'Balayage 3h slot · standard color recipe',
            thumbnail: Icon(Icons.content_cut, size: 32),
            effortLabel: '~3 min',
          ),
          SizedBox(width: 12),
          EdenStarterTemplateCard(
            title: 'Fuel · Delivery run',
            description: 'Route A · Diesel #2 · 4 stops · Truck T7',
            thumbnail: Icon(Icons.local_shipping_outlined, size: 32),
            effortLabel: '~10 min',
          ),
          SizedBox(width: 12),
          EdenStarterTemplateCard(
            title: 'Medical · Home visit',
            description: 'Diabetes panel template · visit kit checklist',
            thumbnail: Icon(Icons.medical_services_outlined, size: 32),
            effortLabel: '~7 min',
          ),
          SizedBox(width: 12),
          EdenStarterTemplateCard(
            title: 'Gov · Case opening',
            description: 'Tier-2 intake · auto-routes to caseload',
            thumbnail: Icon(Icons.folder_open_outlined, size: 32),
            effortLabel: '~8 min',
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// EdenAppTourOverlay + EdenContextualTip demo
// =============================================================================

class _OnboardingTripletDemo extends StatefulWidget {
  const _OnboardingTripletDemo();
  @override
  State<_OnboardingTripletDemo> createState() => _OnboardingTripletDemoState();
}

class _OnboardingTripletDemoState extends State<_OnboardingTripletDemo> {
  final GlobalKey _key1 = GlobalKey();
  final GlobalKey _key2 = GlobalKey();
  final GlobalKey _key3 = GlobalKey();
  final GlobalKey _tipKey = GlobalKey();
  bool _tipVisible = true;

  @override
  Widget build(BuildContext context) {
    return EdenAppTourOverlay(
      steps: <EdenTourStep>[
        EdenTourStep(
          key: _key1,
          title: 'Stop 1 · Inline tip',
          description:
              'EdenContextualTip is a thin inline help bubble. Tap × to dismiss.',
        ),
        EdenTourStep(
          key: _key2,
          title: 'Stop 2 · Action button',
          description: 'Primary actions live here. Tap to start a flow.',
        ),
        EdenTourStep(
          key: _key3,
          title: 'Stop 3 · Inbox icon',
          description: 'Notifications & queued items show up here.',
        ),
      ],
      child: Builder(
        builder: (innerContext) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            EdenButton(
              label: 'Start tour',
              onPressed: () =>
                  EdenAppTourOverlay.of(innerContext)?.startTour(),
            ),
            const SizedBox(height: 12),
            EdenContextualTip(
              key: _key1,
              target: _tipKey,
              message: 'New here? Tap "Start tour" to step through 3 spots.',
              visible: _tipVisible,
              onDismiss: () => setState(() => _tipVisible = false),
            ),
            const SizedBox(height: 12),
            EdenButton(
              key: _key2,
              label: 'Create job',
              onPressed: () {},
            ),
            const SizedBox(height: 12),
            Icon(
              key: _key3,
              Icons.inbox_outlined,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
