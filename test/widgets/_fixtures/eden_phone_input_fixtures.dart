// Do NOT regenerate via LLM — hand-built fixtures for EdenPhoneInput + EdenOtpInput.
//
// Country list (8 supported in v1) + sample phone numbers + OTP codes.
// Add/modify by hand only.

import 'package:flutter/foundation.dart';

/// Country descriptor used by EdenPhoneInput's country picker.
@immutable
class EdenPhoneCountryFixture {
  const EdenPhoneCountryFixture({
    required this.iso2,
    required this.dialCode,
    required this.flagEmoji,
    required this.name,
    required this.sampleNational,
    required this.sampleE164,
  });

  final String iso2;
  final String dialCode;
  final String flagEmoji;
  final String name;
  final String sampleNational;
  final String sampleE164;
}

class EdenPhoneInputFixtures {
  EdenPhoneInputFixtures._();

  /// V1 supported country list — 8 countries.
  static const List<EdenPhoneCountryFixture> countries =
      <EdenPhoneCountryFixture>[
    EdenPhoneCountryFixture(
      iso2: 'US',
      dialCode: '+1',
      flagEmoji: '🇺🇸',
      name: 'United States',
      sampleNational: '5551234567',
      sampleE164: '+15551234567',
    ),
    EdenPhoneCountryFixture(
      iso2: 'CA',
      dialCode: '+1',
      flagEmoji: '🇨🇦',
      name: 'Canada',
      sampleNational: '4165551234',
      sampleE164: '+14165551234',
    ),
    EdenPhoneCountryFixture(
      iso2: 'GB',
      dialCode: '+44',
      flagEmoji: '🇬🇧',
      name: 'United Kingdom',
      sampleNational: '2079460958',
      sampleE164: '+442079460958',
    ),
    EdenPhoneCountryFixture(
      iso2: 'AU',
      dialCode: '+61',
      flagEmoji: '🇦🇺',
      name: 'Australia',
      sampleNational: '0298765432',
      sampleE164: '+61298765432',
    ),
    EdenPhoneCountryFixture(
      iso2: 'DE',
      dialCode: '+49',
      flagEmoji: '🇩🇪',
      name: 'Germany',
      sampleNational: '03012345678',
      sampleE164: '+493012345678',
    ),
    EdenPhoneCountryFixture(
      iso2: 'FR',
      dialCode: '+33',
      flagEmoji: '🇫🇷',
      name: 'France',
      sampleNational: '0123456789',
      sampleE164: '+33123456789',
    ),
    EdenPhoneCountryFixture(
      iso2: 'JP',
      dialCode: '+81',
      flagEmoji: '🇯🇵',
      name: 'Japan',
      sampleNational: '0312345678',
      sampleE164: '+81312345678',
    ),
    EdenPhoneCountryFixture(
      iso2: 'IN',
      dialCode: '+91',
      flagEmoji: '🇮🇳',
      name: 'India',
      sampleNational: '9876543210',
      sampleE164: '+919876543210',
    ),
  ];
}

class EdenOtpInputFixtures {
  EdenOtpInputFixtures._();

  /// Six-digit OTP test code.
  static const String sixDigitCode = '123456';

  /// Four-digit OTP test code.
  static const String fourDigitCode = '4321';
}
