// EdenSignatureCapturePage — full-screen signature capture flow.
//
// Donor: AOCyber-Trades/trades-flutter/lib/features/field_crew/presentation/
// signature_capture_page.dart (259 LOC). Donor uses a CustomPainter
// PLACEHOLDER (no real signature pad). Port REPLACES the placeholder with
// the existing [EdenSignaturePad] widget (already in the library, used by
// EdenConsentFlow per Wave A TRD 001-09).
//
// Library imports ZERO signature-capture pubspec deps. EdenSignaturePad
// is the only canvas.

import 'package:flutter/material.dart';

import '../tokens/spacing.dart';
import 'eden_signature_pad.dart';

/// Immutable result of a successful signature capture.
class EdenSignatureCaptureResult {
  const EdenSignatureCaptureResult({
    required this.strokes,
    required this.signedAt,
    this.metadata = const {},
  });

  final List<EdenSignatureStroke> strokes;
  final DateTime signedAt;
  final Map<String, String> metadata;
}

/// Full-screen single-task signature capture flow.
///
/// **Usage:** push as a route and await the result via `Navigator.pop`:
///
/// ```dart
/// final result = await Navigator.of(context).push<EdenSignatureCaptureResult?>(
///   MaterialPageRoute(builder: (_) => EdenSignatureCapturePage(
///     title: 'Customer Signature',
///     signerName: 'Mr. Johnson',
///     metadata: const {'work_order_id': 'WO-4821'},
///   )),
/// );
/// ```
///
/// The page returns:
///   - `null` if the user backs out without saving.
///   - An [EdenSignatureCaptureResult] when the user taps Save Signature.
///
/// [onSigned] is an optional async hook fired BEFORE the pop. If [onSigned]
/// throws, the page does NOT pop and a SnackBar surfaces the error.
class EdenSignatureCapturePage extends StatefulWidget {
  const EdenSignatureCapturePage({
    super.key,
    this.title = 'Signature',
    this.instructions = 'Please sign in the box below',
    this.signerName,
    this.metadata = const {},
    this.initialStrokes = const [],
    this.onSigned,
    this.showAppBarClear = true,
  });

  final String title;
  final String instructions;
  final String? signerName;
  final Map<String, String> metadata;
  final List<EdenSignatureStroke> initialStrokes;
  final Future<void> Function(EdenSignatureCaptureResult)? onSigned;

  /// When true (default), an AppBar "Clear" TextButton is shown in the
  /// actions area whenever the pad has strokes. Set to false to hide it
  /// (e.g. for read-only review screens).
  final bool showAppBarClear;

  @override
  State<EdenSignatureCapturePage> createState() =>
      _EdenSignatureCapturePageState();
}

class _EdenSignatureCapturePageState extends State<EdenSignatureCapturePage> {
  late List<EdenSignatureStroke> _strokes;
  // Pad-rebuild key — bumping this clears the inner pad's strokes by
  // remounting it with the new (empty) initialStrokes list.
  int _padKey = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _strokes = List<EdenSignatureStroke>.of(widget.initialStrokes);
  }

  bool get _hasStrokes => _strokes.isNotEmpty;

  void _onStrokesChanged(List<EdenSignatureStroke> strokes) {
    setState(() => _strokes = List<EdenSignatureStroke>.of(strokes));
  }

  void _clear() {
    setState(() {
      _strokes = const [];
      _padKey++;
    });
  }

  Future<void> _save() async {
    if (!_hasStrokes || _isSaving) return;
    setState(() => _isSaving = true);
    final result = EdenSignatureCaptureResult(
      strokes: List<EdenSignatureStroke>.of(_strokes),
      signedAt: DateTime.now(),
      metadata: Map<String, String>.from(widget.metadata),
    );
    try {
      if (widget.onSigned != null) {
        await widget.onSigned!.call(result);
      }
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to save signature: $e'),
        backgroundColor: const Color(0xFFEF4444),
      ));
    }
  }

  String _formattedDate(DateTime dt) =>
      '${dt.month}/${dt.day}/${dt.year}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (widget.showAppBarClear && _hasStrokes)
            TextButton(
              onPressed: _isSaving ? null : _clear,
              child: const Text('Clear'),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(EdenSpacing.space6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.instructions,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: EdenSpacing.space4),
            Expanded(
              child: LayoutBuilder(
                builder: (ctx, constraints) {
                  return EdenSignaturePad(
                    key: ValueKey('eden_sig_pad_$_padKey'),
                    height: constraints.maxHeight,
                    showControls: false,
                    initialStrokes:
                        _padKey == 0 ? widget.initialStrokes : const [],
                    readOnly: _isSaving,
                    onSignatureChanged: _onStrokesChanged,
                  );
                },
              ),
            ),
            const SizedBox(height: EdenSpacing.space4),
            // Signer-name divider row
            Row(
              children: [
                const Expanded(child: Divider()),
                const SizedBox(width: 8),
                Text(
                  widget.signerName ?? 'Signer',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Signed on ${_formattedDate(DateTime.now())}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: EdenSpacing.space4),
            // Action button row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        (_hasStrokes && !_isSaving) ? _clear : null,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Clear'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: EdenSpacing.space4),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed:
                        (_hasStrokes && !_isSaving) ? _save : null,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(_isSaving ? 'Saving...' : 'Save Signature'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: EdenSpacing.space4),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
