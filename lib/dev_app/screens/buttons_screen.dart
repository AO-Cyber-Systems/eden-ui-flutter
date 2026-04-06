import 'package:flutter/material.dart';
import '../../eden_ui.dart';
import '../widgets/interactive_controls.dart';
import '../widgets/section.dart';

class ButtonsScreen extends StatefulWidget {
  const ButtonsScreen({super.key});

  @override
  State<ButtonsScreen> createState() => _ButtonsScreenState();
}

class _ButtonsScreenState extends State<ButtonsScreen> {
  EdenButtonVariant _selectedVariant = EdenButtonVariant.primary;
  EdenButtonSize _selectedSize = EdenButtonSize.md;
  bool _isOutline = false;
  bool _isPill = false;
  bool _isDisabled = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buttons')),
      body: ListView(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        children: [
          // Interactive playground
          InteractivePlayground(
            title: 'Interactive Explorer',
            preview: EdenButton(
              label: 'Button',
              variant: _selectedVariant,
              size: _selectedSize,
              outline: _isOutline,
              pill: _isPill,
              disabled: _isDisabled,
              loading: _isLoading,
              onPressed: () {},
            ),
            controls: [
              EnumSelector<EdenButtonVariant>(
                values: EdenButtonVariant.values,
                selected: _selectedVariant,
                onChanged: (v) => setState(() => _selectedVariant = v),
              ),
              EnumSelector<EdenButtonSize>(
                values: EdenButtonSize.values,
                selected: _selectedSize,
                onChanged: (v) => setState(() => _selectedSize = v),
              ),
              ToggleControl(label: 'Outline', value: _isOutline, onChanged: (v) => setState(() => _isOutline = v)),
              ToggleControl(label: 'Pill', value: _isPill, onChanged: (v) => setState(() => _isPill = v)),
              ToggleControl(label: 'Disabled', value: _isDisabled, onChanged: (v) => setState(() => _isDisabled = v)),
              ToggleControl(label: 'Loading', value: _isLoading, onChanged: (v) => setState(() => _isLoading = v)),
            ],
          ),
          const SizedBox(height: EdenSpacing.space4),

          // Existing static sections
          Section(
            title: 'Variants',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: EdenButtonVariant.values.map((v) => EdenButton(
                label: v.name[0].toUpperCase() + v.name.substring(1),
                variant: v,
                onPressed: () {},
              )).toList(),
            ),
          ),
          Section(
            title: 'Outline Variants',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: EdenButtonVariant.values.map((v) => EdenButton(
                label: v.name[0].toUpperCase() + v.name.substring(1),
                variant: v,
                outline: true,
                onPressed: () {},
              )).toList(),
            ),
          ),
          Section(
            title: 'Sizes',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: EdenButtonSize.values.map((s) => EdenButton(
                label: s.name.toUpperCase(),
                size: s,
                onPressed: () {},
              )).toList(),
            ),
          ),
          Section(
            title: 'Pill Shape',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                EdenButton(label: 'Pill Primary', pill: true, onPressed: () {}),
                EdenButton(label: 'Pill Outline', pill: true, outline: true, onPressed: () {}),
                EdenButton(label: 'Pill Danger', pill: true, variant: EdenButtonVariant.danger, onPressed: () {}),
              ],
            ),
          ),
          Section(
            title: 'With Icons',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                EdenButton(label: 'Add', icon: Icons.add, onPressed: () {}),
                EdenButton(label: 'Download', trailingIcon: Icons.download, variant: EdenButtonVariant.secondary, onPressed: () {}),
                EdenButton(label: 'Delete', icon: Icons.delete, variant: EdenButtonVariant.danger, onPressed: () {}),
              ],
            ),
          ),
          Section(
            title: 'States',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                EdenButton(label: 'Disabled', disabled: true, onPressed: () {}),
                EdenButton(label: 'Loading', loading: true, onPressed: () {}),
              ],
            ),
          ),
          Section(
            title: 'Full Width',
            child: EdenButton(label: 'Full Width Button', fullWidth: true, onPressed: () {}),
          ),
        ],
      ),
    );
  }
}
