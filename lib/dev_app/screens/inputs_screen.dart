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
          const Section(
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
          const Section(
            title: 'With Helper Text',
            child: EdenInput(
              label: 'Username',
              hint: 'Enter your username',
              helperText: 'Must be at least 3 characters.',
            ),
          ),
          const Section(
            title: 'Error State',
            child: EdenInput(
              label: 'Password',
              hint: 'Enter password',
              obscureText: true,
              errorText: 'Password is too short.',
              suffixIcon: Icons.visibility_off,
            ),
          ),
          const Section(
            title: 'Disabled Input',
            child: EdenInput(
              label: 'Read-only',
              hint: 'This input is disabled',
              enabled: false,
            ),
          ),
          const Section(
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
                const EdenToggle(
                  value: false,
                  onChanged: null,
                  label: 'Disabled toggle',
                  disabled: true,
                ),
              ],
            ),
          ),

          const EdenDivider(label: 'Wave A — Cross-vertical primitives'),
          const Section(
            title: 'Phone Input',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EdenPhoneInput(),
                SizedBox(height: 12),
                EdenPhoneInput(verifyButton: true),
              ],
            ),
          ),
          const Section(
            title: 'OTP Input (6 digits)',
            child: EdenOtpInput(autofocus: false),
          ),
          const Section(
            title: 'OTP Input (4 digits)',
            child: EdenOtpInput(length: 4, autofocus: false),
          ),

          const EdenDivider(label: 'Wave A — Address & map components'),
          const Section(
            title: 'EdenAddressInput + EdenMapPreview (powered by RecordingMapProvider)',
            child: _AddressInputDemo(),
          ),
          const Section(
            title: 'EdenMapPreview with NoOpMapProvider (graceful degradation)',
            child: EdenMapPreview(
              provider: NoOpMapProvider(),
              bounds: EdenMapBounds(
                southwest: EdenLatLng(lat: 37.70, lng: -122.50),
                northeast: EdenLatLng(lat: 37.85, lng: -122.35),
              ),
              height: 160,
            ),
          ),
          const Section(
            title: 'EdenAddressInput with NoOpMapProvider (manual entry only)',
            child: EdenAddressInput(provider: NoOpMapProvider()),
          ),
        ],
      ),
    );
  }
}

/// Side-by-side address input + map preview demo backed by an in-memory
/// RecordingMapProvider with deterministic San Francisco data so the demo
/// works fully offline.
class _AddressInputDemo extends StatefulWidget {
  const _AddressInputDemo();

  @override
  State<_AddressInputDemo> createState() => _AddressInputDemoState();
}

class _AddressInputDemoState extends State<_AddressInputDemo> {
  static const _sfLatLng = EdenLatLng(lat: 37.7793, lng: -122.4192);

  static const _bounds = EdenMapBounds(
    southwest: EdenLatLng(lat: 37.70, lng: -122.50),
    northeast: EdenLatLng(lat: 37.85, lng: -122.35),
  );

  late final RecordingMapProvider _provider;
  EdenAddress? _current;

  @override
  void initState() {
    super.initState();
    _provider = RecordingMapProvider(
      cannedAddress: const EdenAddress(
        streetLine1: '1 Apple Park Way',
        city: 'Cupertino',
        regionCode: 'CA',
        postalCode: '95014',
        countryCode: 'US',
        latLng: _sfLatLng,
      ),
      cannedSuggestions: const <EdenPlaceSuggestion>[
        EdenPlaceSuggestion(
          placeId: 'place_apple_hq',
          primaryText: 'Apple Park',
          secondaryText: '1 Apple Park Way, Cupertino, CA',
        ),
        EdenPlaceSuggestion(
          placeId: 'place_twitter_hq',
          primaryText: 'Twitter HQ',
          secondaryText: '1355 Market St, San Francisco, CA',
        ),
        EdenPlaceSuggestion(
          placeId: 'place_salesforce_tower',
          primaryText: 'Salesforce Tower',
          secondaryText: '415 Mission St, San Francisco, CA',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final markers = _current?.latLng == null
        ? const <EdenMapMarker>[]
        : <EdenMapMarker>[
            EdenMapMarker(
              id: 'current',
              position: _current!.latLng!,
              label: _current!.streetLine1,
            ),
          ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EdenAddressInput(
          provider: _provider,
          onChanged: (a) => setState(() => _current = a),
        ),
        const SizedBox(height: 12),
        EdenMapPreview(
          provider: _provider,
          bounds: _bounds,
          markers: markers,
          height: 180,
        ),
      ],
    );
  }
}
