import 'package:flutter/material.dart';
import '../../eden_ui.dart';
import '../_sample_data/sample_data.dart';
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

          // -----------------------------------------------------------------
          // Objective 008 Wave 2 (TRD 008-04) — cross-vertical input demos.
          // -----------------------------------------------------------------

          const EdenDivider(label: 'EdenPhoneInput — 8-country grid'),
          const Section(
            title: 'Phone inputs across markets (US/CA/GB/AU/DE/FR/JP/IN)',
            child: _PhoneInputCountryGrid(),
          ),
          const Section(
            title: 'Verify button — idle / disabled',
            child: _PhoneInputVerifyStatesDemo(),
          ),

          const EdenDivider(label: 'EdenOtpInput — length variants'),
          const Section(
            title: '4-digit / 6-digit / 8-digit',
            child: _OtpLengthGrid(),
          ),
          const Section(
            title: 'States — enabled / disabled',
            child: _OtpStatesGrid(),
          ),

          const EdenDivider(label: 'EdenAddressInput — Cross-vertical realistic'),
          const Section(
            title: 'Trades — Atlanta job site (HVAC install)',
            child: _CrossVerticalAddressDemo(vertical: 'trades'),
          ),
          const Section(
            title: 'Salon — NYC retail strip',
            child: _CrossVerticalAddressDemo(vertical: 'salon'),
          ),
          const Section(
            title: 'Fuel — Chicago industrial outskirt',
            child: _CrossVerticalAddressDemo(vertical: 'fuel'),
          ),
          const Section(
            title: 'Medical — Atlanta home-visit',
            child: _CrossVerticalAddressDemo(vertical: 'medical'),
          ),
          const Section(
            title: 'Gov — Cobb County campus',
            child: _CrossVerticalAddressDemo(vertical: 'gov'),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Objective 008 Wave 2 (TRD 008-04) demo widgets. Demo-only — no
// modifications to lib/src/widgets/.
// =============================================================================

class _PhoneInputCountryGrid extends StatelessWidget {
  const _PhoneInputCountryGrid();

  @override
  Widget build(BuildContext context) {
    // 8 supported countries — order matches lib/src/widgets/eden_phone_input.dart.
    const isoCodes = <String>['US', 'CA', 'GB', 'AU', 'DE', 'FR', 'JP', 'IN'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final iso in isoCodes)
          Padding(
            padding: const EdgeInsets.only(bottom: EdenSpacing.space3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  width: 36,
                  child: Text(
                    iso,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: EdenPhoneInput(initialCountryIso2: iso)),
              ],
            ),
          ),
      ],
    );
  }
}

class _PhoneInputVerifyStatesDemo extends StatelessWidget {
  const _PhoneInputVerifyStatesDemo();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('Idle verify button:'),
        const SizedBox(height: 6),
        EdenPhoneInput(verifyButton: true, onVerifyPressed: () {}),
        const SizedBox(height: EdenSpacing.space3),
        const Text('Disabled input + verify:'),
        const SizedBox(height: 6),
        const EdenPhoneInput(verifyButton: true, enabled: false),
      ],
    );
  }
}

class _OtpLengthGrid extends StatelessWidget {
  const _OtpLengthGrid();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('4-digit'),
        SizedBox(height: 6),
        EdenOtpInput(length: 4, autofocus: false),
        SizedBox(height: EdenSpacing.space3),
        Text('6-digit (default)'),
        SizedBox(height: 6),
        EdenOtpInput(autofocus: false),
        SizedBox(height: EdenSpacing.space3),
        Text('8-digit'),
        SizedBox(height: 6),
        EdenOtpInput(length: 8, autofocus: false),
      ],
    );
  }
}

class _OtpStatesGrid extends StatelessWidget {
  const _OtpStatesGrid();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Enabled (empty)'),
        SizedBox(height: 6),
        EdenOtpInput(autofocus: false),
        SizedBox(height: EdenSpacing.space3),
        Text('Disabled'),
        SizedBox(height: 6),
        EdenOtpInput(autofocus: false, enabled: false),
      ],
    );
  }
}

/// Vertical-flavored EdenAddressInput demo. Picks one of the cross-cutting
/// customer fixtures matching `vertical`, builds a RecordingMapProvider with
/// canned suggestions, and shows the input alongside an EdenMapPreview.
class _CrossVerticalAddressDemo extends StatefulWidget {
  const _CrossVerticalAddressDemo({required this.vertical});
  final String vertical;

  @override
  State<_CrossVerticalAddressDemo> createState() =>
      _CrossVerticalAddressDemoState();
}

class _CrossVerticalAddressDemoState extends State<_CrossVerticalAddressDemo> {
  late final RecordingMapProvider _provider;
  late final EdenAddress _seed;
  EdenAddress? _current;

  @override
  void initState() {
    super.initState();
    _seed = _addressFor(widget.vertical);
    _provider = RecordingMapProvider(
      cannedAddress: _seed,
      cannedSuggestions: <EdenPlaceSuggestion>[
        EdenPlaceSuggestion(
          placeId: '${widget.vertical}-1',
          primaryText: _seed.streetLine1,
          secondaryText: '${_seed.city}, ${_seed.regionCode}',
        ),
      ],
    );
    _current = _seed;
  }

  EdenMapBounds _boundsFor(EdenAddress addr) {
    final ll = addr.latLng;
    if (ll == null) {
      // Default to a wide US-centered bounding box for graceful display.
      return const EdenMapBounds(
        southwest: EdenLatLng(lat: 24.0, lng: -125.0),
        northeast: EdenLatLng(lat: 49.0, lng: -66.0),
      );
    }
    const delta = 0.02;
    return EdenMapBounds(
      southwest: EdenLatLng(lat: ll.lat - delta, lng: ll.lng - delta),
      northeast: EdenLatLng(lat: ll.lat + delta, lng: ll.lng + delta),
    );
  }

  EdenAddress _addressFor(String vertical) {
    // Map verticals to representative customer fixtures.
    final picks = <String, int>{
      'trades': 0, // Marcus Whitfield — Marietta GA
      'salon': 1, // Aisha — NYC
      'fuel': 3, // Northpoint Diesel — Chicago
      'medical': 4, // J. Doe — Atlanta
      'gov': 6, // Linnea — Marietta gov campus
    };
    final idx = picks[vertical] ?? 0;
    return CrossCuttingFixtures.customers[idx].address;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        EdenAddressInput(
          provider: _provider,
          initialAddress: _seed,
          onChanged: (a) => setState(() => _current = a),
        ),
        const SizedBox(height: EdenSpacing.space3),
        SizedBox(
          height: 140,
          child: EdenMapPreview(
            provider: _provider,
            bounds: _boundsFor(_current ?? _seed),
            markers: _current?.latLng == null
                ? const <EdenMapMarker>[]
                : <EdenMapMarker>[
                    EdenMapMarker(
                      id: 'current',
                      position: _current!.latLng!,
                      label: _current!.streetLine1,
                    ),
                  ],
          ),
        ),
      ],
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
