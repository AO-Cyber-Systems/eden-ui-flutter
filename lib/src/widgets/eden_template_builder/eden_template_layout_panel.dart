import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'template_models.dart';

/// Right-rail layout panel — parity row L-1 (incorporates L-2..L-6 as the
/// editor surface for those settings).
///
/// Controlled — consumer owns the `value: EdenTemplateLayoutSettings` state.
/// All interactions fire [onChangeLayout] with the new settings.
class EdenTemplateLayoutPanel extends StatefulWidget {
  const EdenTemplateLayoutPanel({
    super.key,
    this.value = const EdenTemplateLayoutSettings(),
    required this.onChangeLayout,
    this.maxMarginInches = 4.0,
    this.minMarginInches = 0.0,
  });

  final EdenTemplateLayoutSettings value;
  final void Function(EdenTemplateLayoutSettings) onChangeLayout;
  final double maxMarginInches;
  final double minMarginInches;

  @override
  State<EdenTemplateLayoutPanel> createState() =>
      _EdenTemplateLayoutPanelState();
}

class _EdenTemplateLayoutPanelState extends State<EdenTemplateLayoutPanel> {
  late TextEditingController _topCtrl;
  late TextEditingController _rightCtrl;
  late TextEditingController _bottomCtrl;
  late TextEditingController _leftCtrl;

  @override
  void initState() {
    super.initState();
    _topCtrl = TextEditingController(text: _fmt(widget.value.marginTop));
    _rightCtrl = TextEditingController(text: _fmt(widget.value.marginRight));
    _bottomCtrl =
        TextEditingController(text: _fmt(widget.value.marginBottom));
    _leftCtrl = TextEditingController(text: _fmt(widget.value.marginLeft));
  }

  @override
  void didUpdateWidget(covariant EdenTemplateLayoutPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value.marginTop != oldWidget.value.marginTop) {
      _topCtrl.text = _fmt(widget.value.marginTop);
    }
    if (widget.value.marginRight != oldWidget.value.marginRight) {
      _rightCtrl.text = _fmt(widget.value.marginRight);
    }
    if (widget.value.marginBottom != oldWidget.value.marginBottom) {
      _bottomCtrl.text = _fmt(widget.value.marginBottom);
    }
    if (widget.value.marginLeft != oldWidget.value.marginLeft) {
      _leftCtrl.text = _fmt(widget.value.marginLeft);
    }
  }

  @override
  void dispose() {
    _topCtrl.dispose();
    _rightCtrl.dispose();
    _bottomCtrl.dispose();
    _leftCtrl.dispose();
    super.dispose();
  }

  String _fmt(double v) => v == v.roundToDouble()
      ? v.toInt().toString()
      : v.toString();

  void _commitMargin({
    required TextEditingController ctrl,
    required double current,
    required void Function(double) emit,
  }) {
    final raw = ctrl.text.trim();
    final parsed = double.tryParse(raw);
    if (parsed == null) {
      ctrl.text = _fmt(current);
      return;
    }
    final clamped =
        parsed.clamp(widget.minMarginInches, widget.maxMarginInches).toDouble();
    ctrl.text = _fmt(clamped);
    if (clamped != current) emit(clamped);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'PAGE LAYOUT',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          const _Label('Page Size'),
          const SizedBox(height: 4),
          SegmentedButton<EdenTemplatePageSize>(
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            segments: const [
              ButtonSegment(
                value: EdenTemplatePageSize.letter,
                label: Text('Letter'),
              ),
              ButtonSegment(
                value: EdenTemplatePageSize.a4,
                label: Text('A4'),
              ),
              ButtonSegment(
                value: EdenTemplatePageSize.legal,
                label: Text('Legal'),
              ),
            ],
            selected: {widget.value.pageSize},
            onSelectionChanged: (set) => widget
                .onChangeLayout(widget.value.copyWith(pageSize: set.first)),
          ),
          const SizedBox(height: 12),
          const _Label('Orientation'),
          const SizedBox(height: 4),
          SegmentedButton<EdenTemplateOrientation>(
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            segments: const [
              ButtonSegment(
                value: EdenTemplateOrientation.portrait,
                label: Text('Portrait'),
              ),
              ButtonSegment(
                value: EdenTemplateOrientation.landscape,
                label: Text('Landscape'),
              ),
            ],
            selected: {widget.value.orientation},
            onSelectionChanged: (set) => widget
                .onChangeLayout(widget.value.copyWith(orientation: set.first)),
          ),
          const SizedBox(height: 16),
          const _Label('Margins (in)'),
          const SizedBox(height: 4),
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.6,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _MarginField(
                label: 'Top',
                controller: _topCtrl,
                onCommit: () => _commitMargin(
                  ctrl: _topCtrl,
                  current: widget.value.marginTop,
                  emit: (v) => widget.onChangeLayout(
                    widget.value.copyWith(marginTop: v),
                  ),
                ),
              ),
              _MarginField(
                label: 'Right',
                controller: _rightCtrl,
                onCommit: () => _commitMargin(
                  ctrl: _rightCtrl,
                  current: widget.value.marginRight,
                  emit: (v) => widget.onChangeLayout(
                    widget.value.copyWith(marginRight: v),
                  ),
                ),
              ),
              _MarginField(
                label: 'Bottom',
                controller: _bottomCtrl,
                onCommit: () => _commitMargin(
                  ctrl: _bottomCtrl,
                  current: widget.value.marginBottom,
                  emit: (v) => widget.onChangeLayout(
                    widget.value.copyWith(marginBottom: v),
                  ),
                ),
              ),
              _MarginField(
                label: 'Left',
                controller: _leftCtrl,
                onCommit: () => _commitMargin(
                  ctrl: _leftCtrl,
                  current: widget.value.marginLeft,
                  emit: (v) => widget.onChangeLayout(
                    widget.value.copyWith(marginLeft: v),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _CheckboxRow(
            label: 'Different first page header',
            value: widget.value.differentFirstPageHeader,
            onChanged: (v) => widget.onChangeLayout(
              widget.value.copyWith(differentFirstPageHeader: v),
            ),
          ),
          _CheckboxRow(
            label: 'Page numbers in footer',
            value: widget.value.pageNumbersInFooter,
            onChanged: (v) => widget.onChangeLayout(
              widget.value.copyWith(pageNumbersInFooter: v),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w500,
        color: theme.colorScheme.onSurface,
      ),
    );
  }
}

class _MarginField extends StatelessWidget {
  const _MarginField({
    required this.label,
    required this.controller,
    required this.onCommit,
  });

  final String label;
  final TextEditingController controller;
  final VoidCallback onCommit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 50, child: Text(label, style: const TextStyle(fontSize: 11))),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            onSubmitted: (_) => onCommit(),
            onTapOutside: (_) => onCommit(),
          ),
        ),
      ],
    );
  }
}

class _CheckboxRow extends StatelessWidget {
  const _CheckboxRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
