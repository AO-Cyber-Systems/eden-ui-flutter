import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import 'eden_card.dart';
import 'eden_equipment_record_card.dart';
import 'eden_input.dart';

/// Severity of the warranty failure.
enum EdenWarrantyClaimSeverity { catastrophic, partial, cosmetic }

/// Optional dropdown helper for selecting a part by SKU.
@immutable
class EdenWarrantyClaimPartCandidate {
  const EdenWarrantyClaimPartCandidate({
    required this.sku,
    required this.label,
  });

  final String sku;
  final String label;
}

/// Emit-only draft captured by [EdenWarrantyClaim.onSubmit].
@immutable
class EdenWarrantyClaimDraft {
  const EdenWarrantyClaimDraft({
    required this.equipmentId,
    required this.partLabel,
    this.partSku,
    required this.failureDescription,
    required this.failureDate,
    this.photoUrls = const [],
    this.technicianNotes,
    this.replacementPartSku,
    required this.severity,
    required this.submittedBy,
  });

  final String equipmentId;
  final String partLabel;
  final String? partSku;
  final String failureDescription;
  final DateTime failureDate;
  final List<String> photoUrls;
  final String? technicianNotes;
  final String? replacementPartSku;
  final EdenWarrantyClaimSeverity severity;
  final String submittedBy;
}

/// 3-step warranty claim form (Equipment & Part → Failure & Photos → Review).
///
/// Composes [EdenEquipmentRecordCard] (compact variant) in step 1, photo
/// callback pattern in step 2, summary view in step 3.
class EdenWarrantyClaim extends StatefulWidget {
  const EdenWarrantyClaim({
    super.key,
    required this.equipment,
    required this.onSubmit,
    required this.submittedBy,
    this.onCancel,
    this.onPickPhoto,
    this.partCandidates,
  });

  final EdenEquipmentRecordData equipment;
  final ValueChanged<EdenWarrantyClaimDraft> onSubmit;
  final String submittedBy;
  final VoidCallback? onCancel;
  final Future<String> Function(BuildContext)? onPickPhoto;
  final List<EdenWarrantyClaimPartCandidate>? partCandidates;

  @override
  State<EdenWarrantyClaim> createState() => _EdenWarrantyClaimState();
}

class _EdenWarrantyClaimState extends State<EdenWarrantyClaim> {
  int _step = 0;

  final TextEditingController _partLabelCtrl = TextEditingController();
  String? _partSku;
  final TextEditingController _descriptionCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  EdenWarrantyClaimSeverity _severity = EdenWarrantyClaimSeverity.partial;
  DateTime _failureDate = DateTime.now();
  final List<String> _photos = [];

  @override
  void dispose() {
    _partLabelCtrl.dispose();
    _descriptionCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  bool get _step1Valid => _partLabelCtrl.text.trim().isNotEmpty;
  bool get _step2Valid => _descriptionCtrl.text.trim().isNotEmpty;
  bool get _canSubmit => _step1Valid && _step2Valid;

  EdenWarrantyClaimDraft _buildDraft() => EdenWarrantyClaimDraft(
        equipmentId: widget.equipment.id,
        partLabel: _partLabelCtrl.text.trim(),
        partSku: _partSku,
        failureDescription: _descriptionCtrl.text.trim(),
        failureDate: _failureDate,
        photoUrls: List<String>.unmodifiable(_photos),
        technicianNotes:
            _notesCtrl.text.isEmpty ? null : _notesCtrl.text.trim(),
        severity: _severity,
        submittedBy: widget.submittedBy,
      );

  @override
  Widget build(BuildContext context) {
    return EdenCard(
      child: Padding(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStepIndicator(context),
            const SizedBox(height: EdenSpacing.space3),
            switch (_step) {
              0 => _buildStep1(context),
              1 => _buildStep2(context),
              _ => _buildStep3(context),
            },
            const SizedBox(height: EdenSpacing.space3),
            _buildNavBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(BuildContext context) {
    const labels = ['Equipment & Part', 'Failure & Photos', 'Review'];
    return Row(
      children: [
        for (int i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i <= _step
                        ? Theme.of(context).colorScheme.primary
                        : EdenColors.neutral[200],
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      color: i <= _step
                          ? Theme.of(context).colorScheme.onPrimary
                          : EdenColors.neutral[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(labels[i],
                    style: Theme.of(context).textTheme.labelSmall,
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStep1(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        EdenEquipmentRecordCard(
          data: widget.equipment,
          variant: EdenEquipmentRecordVariant.compact,
        ),
        const SizedBox(height: EdenSpacing.space3),
        Text('Failed part',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        if (widget.partCandidates != null &&
            widget.partCandidates!.isNotEmpty)
          DropdownButtonFormField<String>(
            initialValue: _partSku,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Select a part...',
              isDense: true,
            ),
            items: [
              for (final c in widget.partCandidates!)
                DropdownMenuItem<String>(value: c.sku, child: Text(c.label)),
            ],
            onChanged: (sku) => setState(() {
              _partSku = sku;
              if (sku != null) {
                final match = widget.partCandidates!
                    .firstWhere((c) => c.sku == sku);
                _partLabelCtrl.text = match.label;
              }
            }),
          ),
        const SizedBox(height: 8),
        EdenInput(
          controller: _partLabelCtrl,
          label: 'Part label',
          hint: 'e.g. Run capacitor 45/5 µF',
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildStep2(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        EdenInput(
          controller: _descriptionCtrl,
          label: 'Failure description',
          hint: 'Describe what failed and how',
          maxLines: 4,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: EdenSpacing.space3),
        Text('Severity', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: [
            for (final s in EdenWarrantyClaimSeverity.values)
              ChoiceChip(
                label: Text(s.name),
                selected: _severity == s,
                onSelected: (_) => setState(() => _severity = s),
              ),
          ],
        ),
        const SizedBox(height: EdenSpacing.space3),
        EdenInput(
          controller: _notesCtrl,
          label: 'Technician notes (optional)',
          maxLines: 3,
        ),
        if (widget.onPickPhoto != null) ...[
          const SizedBox(height: EdenSpacing.space3),
          Text('Photos', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          if (_photos.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _photos
                  .map((u) => Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: EdenColors.neutral[200],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.photo, size: 28),
                      ))
                  .toList(),
            ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const Key('warranty-add-photo'),
              onPressed: () async {
                final url = await widget.onPickPhoto!(context);
                setState(() => _photos.add(url));
              },
              icon: const Icon(Icons.add_a_photo, size: 16),
              label: const Text('Add Photo'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStep3(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Review',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        _summaryRow('Equipment', widget.equipment.name),
        _summaryRow('Type', widget.equipment.type),
        _summaryRow('Part', _partLabelCtrl.text),
        if (_partSku != null) _summaryRow('Part SKU', _partSku!),
        _summaryRow('Severity', _severity.name),
        _summaryRow('Failure description', _descriptionCtrl.text),
        if (_notesCtrl.text.isNotEmpty)
          _summaryRow('Notes', _notesCtrl.text),
        _summaryRow('Photos', '${_photos.length}'),
        _summaryRow('Submitted by', widget.submittedBy),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: Theme.of(context).textTheme.labelSmall),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildNavBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (widget.onCancel != null && _step == 0)
          TextButton(
              onPressed: widget.onCancel, child: const Text('Cancel'))
        else if (_step > 0)
          TextButton(
            key: const Key('warranty-back'),
            onPressed: () => setState(() => _step--),
            child: const Text('Back'),
          )
        else
          const SizedBox.shrink(),
        if (_step < 2)
          ElevatedButton(
            key: const Key('warranty-next'),
            onPressed: _stepValid() ? () => setState(() => _step++) : null,
            child: const Text('Next'),
          )
        else
          ElevatedButton(
            key: const Key('warranty-submit'),
            onPressed:
                _canSubmit ? () => widget.onSubmit(_buildDraft()) : null,
            child: const Text('Submit claim'),
          ),
      ],
    );
  }

  bool _stepValid() {
    if (_step == 0) return _step1Valid;
    if (_step == 1) return _step2Valid;
    return true;
  }
}
