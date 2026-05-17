import 'package:flutter/material.dart';

import '../tokens/spacing.dart';
import 'eden_blocking_alerts.dart';
import 'eden_section_header.dart';
import 'eden_soap_note.dart';
import 'eden_vitals_row.dart';
import 'eden_workflow_stepper.dart';

/// Workflow steps for the visit/encounter scaffold.
enum EdenVisitStep { chiefComplaint, vitals, soap, ordersAndRx, signOff }

/// Order / Rx line item value class (library-owned).
@immutable
class EdenVisitOrder {
  const EdenVisitOrder({
    required this.id,
    required this.kind,
    required this.description,
    required this.code,
    this.dose,
    this.frequency,
    this.quantity,
    this.refills,
    this.priority,
    this.notes,
  });

  final String id;
  final String kind;
  final String description;
  final String code;
  final String? dose;
  final String? frequency;
  final int? quantity;
  final int? refills;
  final String? priority;
  final String? notes;
}

/// Composite visit / encounter data — patient + encounter isolated.
@immutable
class EdenVisitEncounterData {
  const EdenVisitEncounterData({
    required this.patientId,
    required this.encounterId,
    required this.encounterDate,
    required this.provider,
    required this.encounterType,
    this.chiefComplaint = '',
    this.vitals = const <EdenVitalSign>[],
    this.soapNote,
    this.orders = const <EdenVisitOrder>[],
    this.signedBy,
    this.signedAt,
    this.blockingAlerts = const [],
  });

  final String patientId;
  final String encounterId;
  final DateTime encounterDate;
  final String provider;
  final String encounterType;
  final String chiefComplaint;
  final List<EdenVitalSign> vitals;
  final EdenSoapNoteData? soapNote;
  final List<EdenVisitOrder> orders;
  final String? signedBy;
  final DateTime? signedAt;
  final List<EdenBlockingAlertData> blockingAlerts;

  EdenVisitEncounterData copyWith({
    String? chiefComplaint,
    List<EdenVitalSign>? vitals,
    EdenSoapNoteData? soapNote,
    List<EdenVisitOrder>? orders,
    String? signedBy,
    DateTime? signedAt,
  }) {
    return EdenVisitEncounterData(
      patientId: patientId,
      encounterId: encounterId,
      encounterDate: encounterDate,
      provider: provider,
      encounterType: encounterType,
      chiefComplaint: chiefComplaint ?? this.chiefComplaint,
      vitals: vitals ?? this.vitals,
      soapNote: soapNote ?? this.soapNote,
      orders: orders ?? this.orders,
      signedBy: signedBy ?? this.signedBy,
      signedAt: signedAt ?? this.signedAt,
      blockingAlerts: blockingAlerts,
    );
  }
}

/// During-appointment workflow page shell for medical Visit/Encounter
/// screens. Composes EdenWorkflowStepper + per-step body widgets +
/// persistent blocking-alerts right rail.
class EdenVisitEncounterScaffold extends StatefulWidget {
  EdenVisitEncounterScaffold({
    super.key,
    required this.data,
    required this.patientId,
    this.initialStep = EdenVisitStep.chiefComplaint,
    this.onStepChange,
    this.onChiefComplaintChange,
    this.onSoapChange,
    this.onOrdersChange,
    this.onSignOff,
    this.signaturePadSlot,
    this.padding,
  })  : assert(
          data.patientId == patientId,
          'EdenVisitEncounterScaffold: data.patientId must match patientId param '
          '(HIPAA isolation).',
        ),
        assert(
          data.vitals.every((v) => v.patientId == patientId),
          'EdenVisitEncounterScaffold: vitals contain mismatched patientId '
          '(PHI bleed).',
        ),
        assert(
          data.soapNote == null || data.soapNote!.patientId == patientId,
          'EdenVisitEncounterScaffold: soapNote.patientId mismatch (PHI bleed).',
        );

  final EdenVisitEncounterData data;
  final String patientId;
  final EdenVisitStep initialStep;
  final void Function(EdenVisitStep)? onStepChange;
  final void Function(String)? onChiefComplaintChange;
  final void Function(EdenSoapNoteData)? onSoapChange;
  final void Function(List<EdenVisitOrder>)? onOrdersChange;
  final void Function(EdenVisitEncounterData)? onSignOff;
  final Widget? signaturePadSlot;
  final EdgeInsetsGeometry? padding;

  @override
  State<EdenVisitEncounterScaffold> createState() =>
      _EdenVisitEncounterScaffoldState();
}

class _EdenVisitEncounterScaffoldState
    extends State<EdenVisitEncounterScaffold> {
  late EdenVisitStep _currentStep;
  late TextEditingController _chiefComplaintCtrl;

  static const _stepLabels = <EdenVisitStep, String>{
    EdenVisitStep.chiefComplaint: 'Chief Complaint',
    EdenVisitStep.vitals: 'Vitals',
    EdenVisitStep.soap: 'SOAP',
    EdenVisitStep.ordersAndRx: 'Orders + Rx',
    EdenVisitStep.signOff: 'Sign-off',
  };

  static const _stepOrder = <EdenVisitStep>[
    EdenVisitStep.chiefComplaint,
    EdenVisitStep.vitals,
    EdenVisitStep.soap,
    EdenVisitStep.ordersAndRx,
    EdenVisitStep.signOff,
  ];

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
    _chiefComplaintCtrl =
        TextEditingController(text: widget.data.chiefComplaint);
  }

  @override
  void dispose() {
    _chiefComplaintCtrl.dispose();
    super.dispose();
  }

  void _onStep(int index) {
    final s = _stepOrder[index];
    setState(() => _currentStep = s);
    widget.onStepChange?.call(s);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(context),
          const SizedBox(height: EdenSpacing.space2),
          _stepper(context),
          const SizedBox(height: EdenSpacing.space3),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    key: const Key('visit-step-body'),
                    padding: const EdgeInsets.all(EdenSpacing.space2),
                    child: _stepBody(context),
                  ),
                ),
                const VerticalDivider(width: 1),
                SizedBox(
                  width: 280,
                  child: SingleChildScrollView(
                    key: const Key('visit-right-rail'),
                    padding: const EdgeInsets.all(EdenSpacing.space2),
                    child: _rightRail(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    final theme = Theme.of(context);
    final d = widget.data;
    final dateStr = _formatDateTime(d.encounterDate);
    return Container(
      padding: const EdgeInsets.all(EdenSpacing.space3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Text(
        '${d.encounterType} — $dateStr — ${d.provider}',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _stepper(BuildContext context) {
    final steps = <EdenWorkflowStep>[];
    for (var i = 0; i < _stepOrder.length; i++) {
      final s = _stepOrder[i];
      final EdenWorkflowStepState state;
      final currentIdx = _stepOrder.indexOf(_currentStep);
      if (i < currentIdx) {
        state = EdenWorkflowStepState.completed;
      } else if (i == currentIdx) {
        state = EdenWorkflowStepState.active;
      } else {
        state = EdenWorkflowStepState.pending;
      }
      steps.add(EdenWorkflowStep(label: _stepLabels[s]!, state: state));
    }
    return EdenWorkflowStepper(steps: steps, onStepTap: _onStep);
  }

  Widget _stepBody(BuildContext context) {
    switch (_currentStep) {
      case EdenVisitStep.chiefComplaint:
        return _chiefComplaintBody(context);
      case EdenVisitStep.vitals:
        return _vitalsBody(context);
      case EdenVisitStep.soap:
        return _soapBody(context);
      case EdenVisitStep.ordersAndRx:
        return _ordersBody(context);
      case EdenVisitStep.signOff:
        return _signOffBody(context);
    }
  }

  Widget _chiefComplaintBody(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Chief Complaint',
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: EdenSpacing.space2),
        TextField(
          key: const Key('chief-complaint-input'),
          controller: _chiefComplaintCtrl,
          minLines: 3,
          maxLines: null,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
            hintText: 'Patient-stated reason for visit',
          ),
          onChanged: (v) => widget.onChiefComplaintChange?.call(v),
        ),
      ],
    );
  }

  Widget _vitalsBody(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Vitals (triage)',
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: EdenSpacing.space2),
        if (widget.data.vitals.isEmpty)
          Text(
            'No vitals captured yet — triage in progress.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          )
        else
          EdenVitalsRow(
            vitals: widget.data.vitals,
            patientId: widget.patientId,
            showTimestamps: true,
          ),
      ],
    );
  }

  Widget _soapBody(BuildContext context) {
    final note = widget.data.soapNote ??
        EdenSoapNoteData(patientId: widget.patientId);
    return EdenSOAPNote(
      data: note,
      patientId: widget.patientId,
      onChanged: widget.onSoapChange,
    );
  }

  Widget _ordersBody(BuildContext context) {
    // v1 fallback Orders + Rx UI (obj 012 EdenLineItemEditor compose
    // deferred to a follow-up: validation doc §3.1.M2 e-prescribe form
    // remains out-of-scope per Out of Scope below).
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Orders + Rx',
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: EdenSpacing.space2),
        if (widget.data.orders.isEmpty)
          Text(
            'No orders added yet.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.data.orders.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: theme.dividerColor,
            ),
            itemBuilder: (context, i) {
              final o = widget.data.orders[i];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: EdenSpacing.space2,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${o.kind.toUpperCase()} — ${o.description}',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Code: ${o.code}'
                      '${o.dose != null ? ' · Dose: ${o.dose}' : ''}'
                      '${o.frequency != null ? ' · ${o.frequency}' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        const SizedBox(height: EdenSpacing.space3),
        OutlinedButton.icon(
          key: const Key('add-order-button'),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add order'),
          onPressed: () {
            final next = [
              ...widget.data.orders,
              EdenVisitOrder(
                id: 'ord-${DateTime.now().millisecondsSinceEpoch}',
                kind: 'lab',
                description: 'New order',
                code: 'TBD',
              ),
            ];
            widget.onOrdersChange?.call(next);
          },
        ),
      ],
    );
  }

  Widget _signOffBody(BuildContext context) {
    final theme = Theme.of(context);
    final d = widget.data;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Sign-off — Provider Attestation',
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: EdenSpacing.space2),
        Container(
          padding: const EdgeInsets.all(EdenSpacing.space3),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'I have personally examined this patient and the information '
            'above is accurate to the best of my knowledge.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: EdenSpacing.space3),
        if (widget.signaturePadSlot != null) widget.signaturePadSlot!,
        const SizedBox(height: EdenSpacing.space3),
        ElevatedButton.icon(
          key: const Key('sign-off-button'),
          icon: const Icon(Icons.check),
          label: Text(d.signedBy == null ? 'Sign-off' : 'Re-sign'),
          onPressed: () {
            final now = DateTime.now();
            final signed = d.copyWith(
              signedBy: d.signedBy ?? widget.data.provider,
              signedAt: now,
            );
            widget.onSignOff?.call(signed);
          },
        ),
        if (d.signedBy != null) ...[
          const SizedBox(height: EdenSpacing.space2),
          Text(
            'Signed by ${d.signedBy}${d.signedAt != null ? ' on ${_formatDateTime(d.signedAt!)}' : ''}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _rightRail(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const EdenSectionHeader(title: 'Active Alerts'),
        if (widget.data.blockingAlerts.isEmpty)
          Builder(
            builder: (context) {
              final theme = Theme.of(context);
              return Text(
                'No active alerts',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              );
            },
          )
        else
          EdenBlockingAlerts(alerts: widget.data.blockingAlerts),
      ],
    );
  }
}

String _formatDateTime(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  final hh = d.hour.toString().padLeft(2, '0');
  final mm = d.minute.toString().padLeft(2, '0');
  return '$y-$m-$day $hh:$mm';
}
