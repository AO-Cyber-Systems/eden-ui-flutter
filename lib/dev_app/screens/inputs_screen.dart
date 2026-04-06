import 'package:flutter/material.dart';
import '../../eden_ui.dart';
import '../widgets/interactive_controls.dart';
import '../widgets/section.dart';

class InputsScreen extends StatefulWidget {
  const InputsScreen({super.key});

  @override
  State<InputsScreen> createState() => _InputsScreenState();
}

class _InputsScreenState extends State<InputsScreen> {
  bool _toggleValue = true;
  bool _toggle2 = false;
  bool _inputEnabled = true;
  bool _inputShowError = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inputs')),
      body: ListView(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        children: [
          InteractivePlayground(
            title: 'Interactive Explorer',
            preview: EdenInput(
              label: 'Demo Input',
              hint: 'Type something...',
              enabled: _inputEnabled,
              errorText: _inputShowError ? 'This field has an error.' : null,
            ),
            controls: [
              ToggleControl(label: 'Enabled', value: _inputEnabled, onChanged: (v) => setState(() => _inputEnabled = v)),
              ToggleControl(label: 'Error', value: _inputShowError, onChanged: (v) => setState(() => _inputShowError = v)),
            ],
          ),
          const SizedBox(height: EdenSpacing.space4),
          Section(
            title: 'Basic Input',
            child: EdenInput(
              label: 'Email',
              hint: 'you@example.com',
              prefixIcon: Icons.email_outlined,
            ),
          ),
          Section(
            title: 'Input Sizes',
            child: Column(
              children: EdenInputSize.values.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: EdenInput(
                  label: s.name.toUpperCase(),
                  hint: '${s.name} input',
                  size: s,
                ),
              )).toList(),
            ),
          ),
          Section(
            title: 'With Helper Text',
            child: EdenInput(
              label: 'Username',
              hint: 'Enter your username',
              helperText: 'Must be at least 3 characters.',
            ),
          ),
          Section(
            title: 'Error State',
            child: EdenInput(
              label: 'Password',
              hint: 'Enter password',
              obscureText: true,
              errorText: 'Password is too short.',
              suffixIcon: Icons.visibility_off,
            ),
          ),
          Section(
            title: 'Disabled Input',
            child: EdenInput(
              label: 'Read-only',
              hint: 'This input is disabled',
              enabled: false,
            ),
          ),
          Section(
            title: 'Textarea',
            child: EdenInput(
              label: 'Message',
              hint: 'Type your message...',
              maxLines: 4,
            ),
          ),
          const EdenDivider(label: 'Toggles'),
          Section(
            title: 'Toggle Switches',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EdenToggle(
                  value: _toggleValue,
                  onChanged: (v) => setState(() => _toggleValue = v),
                  label: 'Notifications enabled',
                ),
                const SizedBox(height: 8),
                EdenToggle(
                  value: _toggle2,
                  onChanged: (v) => setState(() => _toggle2 = v),
                  label: 'Dark mode',
                ),
                const SizedBox(height: 8),
                EdenToggle(
                  value: false,
                  onChanged: null,
                  label: 'Disabled toggle',
                  disabled: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
