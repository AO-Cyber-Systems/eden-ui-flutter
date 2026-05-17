import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'template_models.dart';

/// Right-rail styles panel — parity rows S-1..S-4.
///
/// Controlled — consumer owns the `value: EdenTemplateStyleSettings` state.
/// All interactions fire [onChangeStyle] with the new settings.
class EdenTemplateStylesPanel extends StatefulWidget {
  const EdenTemplateStylesPanel({
    super.key,
    this.value = const EdenTemplateStyleSettings(),
    required this.onChangeStyle,
    this.brandColorSwatches = const [
      Color(0xFFD4A853),
      Color(0xFF3B82F6),
      Color(0xFF10B981),
      Color(0xFFEF4444),
      Color(0xFF8B5CF6),
      Color(0xFF71717A),
    ],
    this.fontFamilies = const [
      'Plus Jakarta Sans',
      'Inter',
      'Outfit',
      'System Default',
    ],
    this.minFontSize = 8,
    this.maxFontSize = 72,
  });

  final EdenTemplateStyleSettings value;
  final void Function(EdenTemplateStyleSettings) onChangeStyle;
  final List<Color> brandColorSwatches;
  final List<String> fontFamilies;
  final double minFontSize;
  final double maxFontSize;

  @override
  State<EdenTemplateStylesPanel> createState() =>
      _EdenTemplateStylesPanelState();
}

class _EdenTemplateStylesPanelState extends State<EdenTemplateStylesPanel> {
  late TextEditingController _headerCtrl;
  late TextEditingController _bodyCtrl;

  @override
  void initState() {
    super.initState();
    _headerCtrl = TextEditingController(text: _fmt(widget.value.headerFontSize));
    _bodyCtrl = TextEditingController(text: _fmt(widget.value.bodyFontSize));
  }

  @override
  void didUpdateWidget(covariant EdenTemplateStylesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value.headerFontSize != oldWidget.value.headerFontSize) {
      _headerCtrl.text = _fmt(widget.value.headerFontSize);
    }
    if (widget.value.bodyFontSize != oldWidget.value.bodyFontSize) {
      _bodyCtrl.text = _fmt(widget.value.bodyFontSize);
    }
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  String _fmt(double v) => v == v.roundToDouble()
      ? v.toInt().toString()
      : v.toString();

  void _commitFontSize({
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
        parsed.clamp(widget.minFontSize, widget.maxFontSize).toDouble();
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
            'STYLES',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          _SwatchRow(
            swatches: widget.brandColorSwatches,
            selected: widget.value.brandColor,
            onSelect: (c) =>
                widget.onChangeStyle(widget.value.copyWith(brandColor: c)),
          ),
          const SizedBox(height: 16),
          const _Label('Font Family'),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: widget.fontFamilies.contains(widget.value.fontFamily)
                ? widget.value.fontFamily
                : widget.fontFamilies.first,
            isDense: true,
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
            ),
            items: [
              for (final f in widget.fontFamilies)
                DropdownMenuItem<String>(
                  value: f,
                  child: Text(
                    f,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (v) {
              if (v == null) return;
              widget.onChangeStyle(widget.value.copyWith(fontFamily: v));
            },
          ),
          const SizedBox(height: 12),
          const _Label('Header Font Size'),
          const SizedBox(height: 4),
          _NumericField(
            controller: _headerCtrl,
            onCommit: () => _commitFontSize(
              ctrl: _headerCtrl,
              current: widget.value.headerFontSize,
              emit: (v) => widget
                  .onChangeStyle(widget.value.copyWith(headerFontSize: v)),
            ),
          ),
          const SizedBox(height: 12),
          const _Label('Body Font Size'),
          const SizedBox(height: 4),
          _NumericField(
            controller: _bodyCtrl,
            onCommit: () => _commitFontSize(
              ctrl: _bodyCtrl,
              current: widget.value.bodyFontSize,
              emit: (v) =>
                  widget.onChangeStyle(widget.value.copyWith(bodyFontSize: v)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwatchRow extends StatelessWidget {
  const _SwatchRow({
    required this.swatches,
    required this.selected,
    required this.onSelect,
  });

  final List<Color> swatches;
  final Color selected;
  final ValueChanged<Color> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in swatches)
          GestureDetector(
            onTap: () => onSelect(c),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(
                  color: c.toARGB32() == selected.toARGB32()
                      ? Colors.white
                      : Colors.transparent,
                  width: 2,
                ),
                boxShadow: c.toARGB32() == selected.toARGB32()
                    ? [
                        BoxShadow(
                          color: c.withValues(alpha: 0.4),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
      ],
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

class _NumericField extends StatelessWidget {
  const _NumericField({required this.controller, required this.onCommit});

  final TextEditingController controller;
  final VoidCallback onCommit;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
    );
  }
}
