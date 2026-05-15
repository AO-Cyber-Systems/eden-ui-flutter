import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// Country descriptor: ISO-3166 alpha-2 code, dial code, flag emoji, name.
@immutable
class EdenPhoneCountry {
  const EdenPhoneCountry({
    required this.iso2,
    required this.dialCode,
    required this.flagEmoji,
    required this.name,
  });

  final String iso2;
  final String dialCode;
  final String flagEmoji;
  final String name;
}

/// Internal per-country format hint for national-number masking.
class _PhoneFormat {
  const _PhoneFormat(this.template);

  /// Template string where '#' = digit slot. Other chars rendered literally.
  /// Example US: '(###) ###-####'.
  final String template;

  /// Maximum number of digits accepted (count of '#').
  int get digits => template.split('#').length - 1;
}

/// International phone input with country picker + masked text input.
///
/// Transport-agnostic. Surfaces a [verifyButton] slot and [onVerifyPressed]
/// callback for the SMS-verify pattern, but does NOT make any HTTP/SMS calls;
/// downstream apps wire their own provider.
///
/// Output via [onChanged] is always E.164 format (e.g., '+15551234567').
class EdenPhoneInput extends StatefulWidget {
  const EdenPhoneInput({
    super.key,
    this.initialCountryIso2 = 'US',
    this.initialValue,
    this.onChanged,
    this.verifyButton = false,
    this.verifyButtonLabel = 'Verify',
    this.onVerifyPressed,
    this.enabled = true,
    this.narrowBreakpoint = 480.0,
  });

  final String initialCountryIso2;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final bool verifyButton;
  final String verifyButtonLabel;
  final VoidCallback? onVerifyPressed;
  final bool enabled;

  /// Width (logical px) below which the country picker collapses to flag-only.
  final double narrowBreakpoint;

  @override
  State<EdenPhoneInput> createState() => _EdenPhoneInputState();
}

class _EdenPhoneInputState extends State<EdenPhoneInput> {
  static const List<EdenPhoneCountry> _countries = <EdenPhoneCountry>[
    EdenPhoneCountry(iso2: 'US', dialCode: '+1', flagEmoji: '🇺🇸', name: 'United States'),
    EdenPhoneCountry(iso2: 'CA', dialCode: '+1', flagEmoji: '🇨🇦', name: 'Canada'),
    EdenPhoneCountry(iso2: 'GB', dialCode: '+44', flagEmoji: '🇬🇧', name: 'United Kingdom'),
    EdenPhoneCountry(iso2: 'AU', dialCode: '+61', flagEmoji: '🇦🇺', name: 'Australia'),
    EdenPhoneCountry(iso2: 'DE', dialCode: '+49', flagEmoji: '🇩🇪', name: 'Germany'),
    EdenPhoneCountry(iso2: 'FR', dialCode: '+33', flagEmoji: '🇫🇷', name: 'France'),
    EdenPhoneCountry(iso2: 'JP', dialCode: '+81', flagEmoji: '🇯🇵', name: 'Japan'),
    EdenPhoneCountry(iso2: 'IN', dialCode: '+91', flagEmoji: '🇮🇳', name: 'India'),
  ];

  /// Per-ISO national-number format template. Countries without an entry
  /// accept E.164 raw digits with no mask.
  static const Map<String, _PhoneFormat> _formats = <String, _PhoneFormat>{
    'US': _PhoneFormat('(###) ###-####'),
    'CA': _PhoneFormat('(###) ###-####'),
  };

  late EdenPhoneCountry _country;
  late TextEditingController _controller;
  String _digits = '';

  @override
  void initState() {
    super.initState();
    _country = _countries.firstWhere(
      (c) => c.iso2 == widget.initialCountryIso2,
      orElse: () => _countries.first,
    );
    _controller = TextEditingController(text: widget.initialValue ?? '');
    if (widget.initialValue != null) {
      _digits = widget.initialValue!.replaceAll(RegExp(r'\D'), '');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _applyMask(String digits, _PhoneFormat? format) {
    if (format == null) return digits;
    final buf = StringBuffer();
    var di = 0;
    for (final ch in format.template.split('')) {
      if (ch == '#') {
        if (di >= digits.length) break;
        buf.write(digits[di]);
        di++;
      } else {
        if (di >= digits.length) break;
        buf.write(ch);
      }
    }
    return buf.toString();
  }

  String _toE164(String digits) {
    return '${_country.dialCode}$digits';
  }

  void _onTextChanged(String value) {
    final format = _formats[_country.iso2];
    final maxDigits = format?.digits ?? 15;
    final rawDigits = value.replaceAll(RegExp(r'\D'), '');
    final limitedDigits =
        rawDigits.length > maxDigits ? rawDigits.substring(0, maxDigits) : rawDigits;
    final masked = _applyMask(limitedDigits, format);

    if (masked != _controller.text) {
      _controller.value = TextEditingValue(
        text: masked,
        selection: TextSelection.collapsed(offset: masked.length),
      );
    }
    setState(() {
      _digits = limitedDigits;
    });
    widget.onChanged?.call(_toE164(limitedDigits));
  }

  Future<void> _pickCountry(BuildContext context) async {
    final picked = await showModalBottomSheet<EdenPhoneCountry>(
      context: context,
      builder: (sheetCtx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: _countries.map((c) {
              return ListTile(
                leading: Text(c.flagEmoji, style: const TextStyle(fontSize: 20)),
                title: Text(c.name),
                trailing: Text(c.dialCode),
                onTap: () => Navigator.of(sheetCtx).pop(c),
              );
            }).toList(),
          ),
        );
      },
    );
    if (picked != null) {
      setState(() {
        _country = picked;
      });
      // Reapply mask for new country (digits stay; format may change).
      final format = _formats[_country.iso2];
      final masked = _applyMask(_digits, format);
      _controller.value = TextEditingValue(
        text: masked,
        selection: TextSelection.collapsed(offset: masked.length),
      );
      widget.onChanged?.call(_toE164(_digits));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < widget.narrowBreakpoint;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Country picker.
            InkWell(
              key: const ValueKey('eden_phone_country_picker'),
              onTap: widget.enabled ? () => _pickCountry(context) : null,
              borderRadius: EdenRadii.borderRadiusMd,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: EdenSpacing.space3,
                  vertical: EdenSpacing.space2,
                ),
                decoration: BoxDecoration(
                  borderRadius: EdenRadii.borderRadiusMd,
                  border:
                      Border.all(color: Theme.of(context).colorScheme.outline),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_country.flagEmoji,
                        style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 4),
                    Text(_country.iso2,
                        style: Theme.of(context).textTheme.bodySmall),
                    if (!isNarrow) ...[
                      const SizedBox(width: 4),
                      Text(
                        _country.dialCode,
                        key: const ValueKey('eden_phone_inline_dial_code'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: EdenSpacing.space2),
            // Phone input field.
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: widget.enabled,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d\s\-\(\)]')),
                ],
                decoration: InputDecoration(
                  hintText: _formats[_country.iso2]?.template ??
                      _country.dialCode,
                  border: OutlineInputBorder(
                    borderRadius: EdenRadii.borderRadiusMd,
                  ),
                ),
                onChanged: _onTextChanged,
              ),
            ),
            if (widget.verifyButton) ...[
              const SizedBox(width: EdenSpacing.space2),
              ElevatedButton(
                onPressed: widget.enabled ? widget.onVerifyPressed : null,
                child: Text(widget.verifyButtonLabel),
              ),
            ],
          ],
        );
      },
    );
  }
}
