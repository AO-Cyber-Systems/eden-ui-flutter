import 'dart:async';

import 'package:flutter/material.dart';

import '../tokens/spacing.dart';
import 'map_providers/eden_map_provider.dart';
import 'map_providers/eden_map_types.dart';

/// Five-field US-shape address form with provider-driven autocomplete.
///
/// Transport-agnostic: imports no map SDK. The injected [provider] handles
/// `autocompletePlaces` + `resolvePlace`; this widget wires the UI.
///
/// When [provider] is a [NoOpMapProvider] (the default-fallback shape for
/// gov / offline builds), the autocomplete suggestion list is suppressed
/// and the fields behave as plain TextFields. Manual entry still produces
/// [onChanged] callbacks so downstream forms can validate + submit without
/// a real map SDK wired up.
///
/// **Caveat:** after the user selects a suggestion (which populates all 5
/// fields from `provider.resolvePlace(...)`), subsequent manual edits to
/// any single field do NOT re-trigger resolution. The [onChanged] callback
/// emits the CURRENT field state, not the last-resolved place — so the
/// `latLng` field of the emitted address is null after manual edits unless
/// the form does its own geocoding.
class EdenAddressInput extends StatefulWidget {
  const EdenAddressInput({
    super.key,
    required this.provider,
    this.initialAddress,
    this.onChanged,
    this.minAutocompleteChars = 3,
    this.autocompleteDebounce = const Duration(milliseconds: 300),
    this.autocompleteLimit = 5,
    this.enabled = true,
    this.line1Label = 'Street address',
    this.line2Label = 'Apt, suite, etc. (optional)',
    this.cityLabel = 'City',
    this.regionLabel = 'State / region',
    this.postalLabel = 'Postal code',
  });

  final EdenMapProvider provider;
  final EdenAddress? initialAddress;
  final ValueChanged<EdenAddress>? onChanged;

  /// Minimum number of characters typed in line1 before autocomplete fires.
  final int minAutocompleteChars;

  /// Debounce window — autocomplete fires only after the user stops typing
  /// for this duration. Prevents one provider call per keystroke.
  final Duration autocompleteDebounce;

  /// Forwarded as `limit:` to `provider.autocompletePlaces`.
  final int autocompleteLimit;

  final bool enabled;

  final String line1Label;
  final String line2Label;
  final String cityLabel;
  final String regionLabel;
  final String postalLabel;

  @override
  State<EdenAddressInput> createState() => _EdenAddressInputState();
}

class _EdenAddressInputState extends State<EdenAddressInput> {
  late final TextEditingController _line1;
  late final TextEditingController _line2;
  late final TextEditingController _city;
  late final TextEditingController _region;
  late final TextEditingController _postal;

  Timer? _debounceTimer;
  List<EdenPlaceSuggestion> _suggestions = const <EdenPlaceSuggestion>[];

  /// Latest provider call id; used to discard stale autocomplete responses
  /// when a faster successor query lands first.
  int _autocompleteCallId = 0;

  /// Country code carried from initialAddress / resolved place — surfaced
  /// only via the emitted [EdenAddress] (we don't render a country field in
  /// the v1 widget; downstream apps that need country selection compose
  /// their own picker around it).
  String _countryCode = '';

  /// Last-resolved latLng. Cleared after any manual edit so we don't lie
  /// about coordinates downstream.
  EdenLatLng? _latLng;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialAddress;
    _line1 = TextEditingController(text: initial?.streetLine1 ?? '');
    _line2 = TextEditingController(text: initial?.streetLine2 ?? '');
    _city = TextEditingController(text: initial?.city ?? '');
    _region = TextEditingController(text: initial?.regionCode ?? '');
    _postal = TextEditingController(text: initial?.postalCode ?? '');
    _countryCode = initial?.countryCode ?? '';
    _latLng = initial?.latLng;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _line1.dispose();
    _line2.dispose();
    _city.dispose();
    _region.dispose();
    _postal.dispose();
    super.dispose();
  }

  EdenAddress _currentAddress() {
    return EdenAddress(
      streetLine1: _line1.text,
      streetLine2: _line2.text.isEmpty ? null : _line2.text,
      city: _city.text,
      regionCode: _region.text,
      postalCode: _postal.text,
      countryCode: _countryCode,
      latLng: _latLng,
    );
  }

  void _emitChange() {
    widget.onChanged?.call(_currentAddress());
  }

  void _onLine1Changed(String value) {
    // Manual edit invalidates the cached coordinates.
    _latLng = null;
    _emitChange();

    _debounceTimer?.cancel();
    if (value.length < widget.minAutocompleteChars) {
      if (_suggestions.isNotEmpty) {
        setState(() => _suggestions = const []);
      }
      return;
    }

    // Skip autocomplete entirely when paired with NoOpMapProvider —
    // graceful degradation when no real map SDK is wired up.
    if (widget.provider is NoOpMapProvider) {
      if (_suggestions.isNotEmpty) {
        setState(() => _suggestions = const []);
      }
      return;
    }

    _debounceTimer = Timer(widget.autocompleteDebounce, () {
      _runAutocomplete(value);
    });
  }

  Future<void> _runAutocomplete(String query) async {
    final id = ++_autocompleteCallId;
    final results = await widget.provider.autocompletePlaces(
      query,
      limit: widget.autocompleteLimit,
    );
    if (!mounted || id != _autocompleteCallId) return;
    setState(() => _suggestions = results);
  }

  Future<void> _onSuggestionTapped(EdenPlaceSuggestion s) async {
    final resolved = await widget.provider.resolvePlace(s.placeId);
    if (!mounted) return;
    if (resolved != null) {
      _line1.text = resolved.streetLine1;
      _line2.text = resolved.streetLine2 ?? '';
      _city.text = resolved.city;
      _region.text = resolved.regionCode;
      _postal.text = resolved.postalCode;
      _countryCode = resolved.countryCode;
      _latLng = resolved.latLng;
    }
    setState(() => _suggestions = const []);
    _emitChange();
  }

  void _onOtherFieldChanged(String _) {
    // Manual edits to city/region/postal invalidate the cached lat/lng —
    // we no longer know that the user's text matches the resolved place.
    _latLng = null;
    _emitChange();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _line1,
          enabled: widget.enabled,
          decoration: InputDecoration(
            labelText: widget.line1Label,
            border: const OutlineInputBorder(),
          ),
          onChanged: _onLine1Changed,
        ),
        if (_suggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: EdenSpacing.space1),
            child: Material(
              elevation: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final s in _suggestions)
                    ListTile(
                      dense: true,
                      title: Text(s.primaryText),
                      subtitle: s.secondaryText == null
                          ? null
                          : Text(s.secondaryText!),
                      onTap: () => _onSuggestionTapped(s),
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: EdenSpacing.space2),
        TextField(
          controller: _line2,
          enabled: widget.enabled,
          decoration: InputDecoration(
            labelText: widget.line2Label,
            border: const OutlineInputBorder(),
          ),
          onChanged: _onOtherFieldChanged,
        ),
        const SizedBox(height: EdenSpacing.space2),
        TextField(
          controller: _city,
          enabled: widget.enabled,
          decoration: InputDecoration(
            labelText: widget.cityLabel,
            border: const OutlineInputBorder(),
          ),
          onChanged: _onOtherFieldChanged,
        ),
        const SizedBox(height: EdenSpacing.space2),
        TextField(
          controller: _region,
          enabled: widget.enabled,
          decoration: InputDecoration(
            labelText: widget.regionLabel,
            border: const OutlineInputBorder(),
          ),
          onChanged: _onOtherFieldChanged,
        ),
        const SizedBox(height: EdenSpacing.space2),
        TextField(
          controller: _postal,
          enabled: widget.enabled,
          decoration: InputDecoration(
            labelText: widget.postalLabel,
            border: const OutlineInputBorder(),
          ),
          onChanged: _onOtherFieldChanged,
        ),
      ],
    );
  }
}
