import 'package:flutter/material.dart';

import '../tokens/spacing.dart';
import 'eden_authenticated_image.dart';

/// Capture source for a meter reading. Consumer maps domain semantics.
enum EdenMeterReadingSource { manual, telemetry, customerReported }

/// Emitted on submit. Consumer persists via their own RPC.
@immutable
class EdenMeterReadingDraft {
  const EdenMeterReadingDraft({
    required this.gallons,
    required this.source,
    required this.timestamp,
    required this.operatorId,
    this.photoSignedUrl,
    this.notes,
  });

  final double gallons;
  final EdenMeterReadingSource source;
  final DateTime timestamp;
  final String operatorId;
  final String? photoSignedUrl;
  final String? notes;
}

/// Form widget for capturing a fuel meter reading. Generalizes to any
/// photo-backed measurement (utility meter reads, inventory spot counts).
///
/// Composes [EdenAuthenticatedImage] for the captured photo preview. The
/// library does NOT mint auth tokens, refresh sessions, or know about
/// transport — consumer supplies headers via [imageHeadersBuilder] and wires
/// camera/gallery capture via [onPhotoPick].
///
/// Validation:
///   - `gallons` must parse as non-negative decimal with ≤4 decimal places.
///   - `operatorId` must be non-empty / non-whitespace.
///
/// Submit emits [EdenMeterReadingDraft] via [onSubmit].
class EdenMeterReadingEntry extends StatefulWidget {
  const EdenMeterReadingEntry({
    super.key,
    this.onSubmit,
    this.onPhotoPick,
    this.imageHeadersBuilder,
    this.initialDraft,
    this.submitLabel = 'Record reading',
    this.unitLabel = 'gal',
  });

  /// Fired when user taps submit with a valid form.
  final ValueChanged<EdenMeterReadingDraft>? onSubmit;

  /// Consumer's photo capture handler. Returns a signed URL on success,
  /// null on cancel.
  final Future<String?> Function()? onPhotoPick;

  /// Forwarded to [EdenAuthenticatedImage] when rendering the captured
  /// photo preview.
  final Future<Map<String, String>?> Function()? imageHeadersBuilder;

  /// Pre-populate the form (e.g. for editing an existing draft).
  final EdenMeterReadingDraft? initialDraft;
  final String submitLabel;
  final String unitLabel;

  @override
  State<EdenMeterReadingEntry> createState() => _EdenMeterReadingEntryState();
}

class _EdenMeterReadingEntryState extends State<EdenMeterReadingEntry> {
  late final TextEditingController _gallonsCtrl;
  late final TextEditingController _operatorCtrl;
  late final TextEditingController _notesCtrl;
  late EdenMeterReadingSource _source;
  late DateTime _timestamp;
  String? _photoSignedUrl;

  // Accept non-negative decimal with 0-4 fractional digits.
  static final RegExp _gallonsRe = RegExp(r'^\d+(\.\d{0,4})?$');

  @override
  void initState() {
    super.initState();
    final d = widget.initialDraft;
    _gallonsCtrl = TextEditingController(
      text: d == null ? '' : _gallonsToText(d.gallons),
    );
    _operatorCtrl = TextEditingController(text: d?.operatorId ?? '');
    _notesCtrl = TextEditingController(text: d?.notes ?? '');
    _source = d?.source ?? EdenMeterReadingSource.manual;
    _timestamp = d?.timestamp ?? DateTime.now();
    _photoSignedUrl = d?.photoSignedUrl;
    _gallonsCtrl.addListener(_revalidate);
    _operatorCtrl.addListener(_revalidate);
  }

  static String _gallonsToText(double g) {
    final s = g.toStringAsFixed(4);
    // Strip trailing zeros + dangling dot.
    var t = s;
    if (t.contains('.')) {
      t = t.replaceFirst(RegExp(r'0+$'), '');
      t = t.replaceFirst(RegExp(r'\.$'), '');
    }
    return t;
  }

  @override
  void dispose() {
    _gallonsCtrl.dispose();
    _operatorCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _revalidate() => setState(() {});

  bool get _gallonsValid {
    final t = _gallonsCtrl.text.trim();
    if (t.isEmpty) return false;
    return _gallonsRe.hasMatch(t);
  }

  bool get _operatorValid => _operatorCtrl.text.trim().isNotEmpty;

  bool get _formValid => _gallonsValid && _operatorValid;

  String _sourceLabel(EdenMeterReadingSource s) => switch (s) {
        EdenMeterReadingSource.manual => 'Manual entry',
        EdenMeterReadingSource.telemetry => 'Telemetry',
        EdenMeterReadingSource.customerReported => 'Customer reported',
      };

  static String _formatDateTime(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final h = dt.hour;
    final m = dt.minute;
    final am = h < 12;
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} '
        'at $h12:${m.toString().padLeft(2, '0')} ${am ? 'AM' : 'PM'}';
  }

  Future<void> _onCapturePhoto() async {
    final url = await widget.onPhotoPick?.call();
    if (!mounted) return;
    if (url != null) setState(() => _photoSignedUrl = url);
  }

  Future<void> _onOverrideTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_timestamp),
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() {
        _timestamp = DateTime(
          _timestamp.year,
          _timestamp.month,
          _timestamp.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  void _onSubmit() {
    if (!_formValid) return;
    final notes = _notesCtrl.text.trim();
    widget.onSubmit?.call(EdenMeterReadingDraft(
      gallons: double.parse(_gallonsCtrl.text.trim()),
      source: _source,
      timestamp: _timestamp,
      operatorId: _operatorCtrl.text.trim(),
      photoSignedUrl: _photoSignedUrl,
      notes: notes.isEmpty ? null : notes,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
        TextField(
          controller: _gallonsCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Gallons',
            suffixText: widget.unitLabel,
          ),
        ),
        const SizedBox(height: EdenSpacing.space3),
        const Text('Source', style: TextStyle(fontWeight: FontWeight.w600)),
        for (final src in EdenMeterReadingSource.values)
          RadioListTile<EdenMeterReadingSource>(
            value: src,
            groupValue: _source,
            onChanged: (v) => setState(() => _source = v!),
            title: Text(_sourceLabel(src)),
          ),
        const SizedBox(height: EdenSpacing.space3),
        TextField(
          controller: _operatorCtrl,
          decoration: const InputDecoration(labelText: 'Operator ID'),
        ),
        const SizedBox(height: EdenSpacing.space3),
        TextField(
          controller: _notesCtrl,
          maxLines: 3,
          maxLength: 500,
          decoration: const InputDecoration(labelText: 'Notes (optional)'),
        ),
        const SizedBox(height: EdenSpacing.space3),
        Row(
          children: [
            Expanded(child: Text('Time: ${_formatDateTime(_timestamp)}')),
            TextButton.icon(
              icon: const Icon(Icons.access_time, size: 18),
              label: const Text('Override'),
              onPressed: _onOverrideTime,
            ),
          ],
        ),
        const SizedBox(height: EdenSpacing.space3),
        if (_photoSignedUrl == null)
          ElevatedButton.icon(
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Capture photo'),
            onPressed: widget.onPhotoPick == null ? null : _onCapturePhoto,
          )
        else
          Column(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: EdenAuthenticatedImage(
                  url: _photoSignedUrl!,
                  headersBuilder: widget.imageHeadersBuilder,
                  width: 120,
                  height: 120,
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _photoSignedUrl = null),
                child: const Text('Remove photo'),
              ),
            ],
          ),
        const SizedBox(height: EdenSpacing.space3),
        ElevatedButton(
          onPressed: _formValid ? _onSubmit : null,
          child: Text(widget.submitLabel),
        ),
      ],
      ),
    );
  }
}
