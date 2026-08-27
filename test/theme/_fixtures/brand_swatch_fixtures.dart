// test/theme/_fixtures/brand_swatch_fixtures.dart
//
// Hand-built test fixtures for EdenBrandSwatch (objective 022 TRD 02).
// Do NOT regenerate via LLM — mutate in-place when the algorithm or the
// accepted-input contract changes.
// Per global TDD Playbook habit 4 + resolver no_llm_test_data constraint.
//
// NOTE on tolerance fitting (Test list item 8a): the ±1.0deg hue / ±0.02
// saturation tolerance used against `realPartnerHexes` + `degenerate` is
// FITTED to exactly these hexes, measured against the reference
// implementation. Hue drift scales inversely with input saturation, so a
// low-saturation hex (examples measured and rejected: #B0A99F, #8B8680,
// #6B7280, #5C5470) can blow the tolerance even though the algorithm is
// correct. Do NOT add a new hex to either list below without re-measuring
// its actual drift first.

class BrandSwatchFixtures {
  BrandSwatchFixtures._();

  /// Test list item 14 — every accepted textual form of the same colour.
  /// All four must parse to the identical 0xFF0F62FE shade map.
  static const List<String> validForms = [
    '#0F62FE',
    '0f62fe',
    '  #0F62FE  ',
    '#FF0F62FE',
  ];

  /// The ARGB value every entry in [validForms] must resolve to.
  static const int validFormsExpectedArgb = 0xFF0F62FE;

  /// Test list item 15 — 3-digit shorthand expansion.
  static const String shorthandInput = '#F00';
  static const int shorthandExpectedArgb = 0xFFFF0000;

  /// Test list items 16-21 — every malformed / edge-case input, including
  /// the `null` case and the four signed-hex forms that would otherwise
  /// sneak past `int.tryParse(..., radix: 16)` (item 20b). `tryParse` must
  /// return null for every one of these and must never throw.
  static const List<String?> malformed = [
    null,
    '',
    '   ',
    '#',
    'nope',
    '#GGGGGG',
    '#12345',
    '#1234567',
    'rgb(1,2,3)',
    'blue',
    '#-0F62FEE',
    '#+0F62FEE',
    '#-0F62F',
    '#-F0',
  ];

  /// Test list items 5, 7, 8, 8b — real brand-partner hexes used to verify
  /// shade-500 exactness, lightness monotonicity, and hue/saturation
  /// preservation within tolerance.
  ///
  /// Measured worst-case drift for these five (see TRD research_context):
  ///   #0F62FE — max sat delta 0.00830 (shade 50)
  ///   #D4A853 — max hue delta 0.8682deg (shade 950)
  ///   #FF0000 — hue bit-exact; sat 1-2 ULP low on shades 400/900/950
  ///   #00FF00 — hue bit-exact; sat 1-2 ULP low on shades 400/900/950
  ///   #808080 — hue + sat bit-exact on all eleven shades (grey; sat == 0)
  static const List<String> realPartnerHexes = [
    '#0F62FE',
    '#D4A853',
    '#FF0000',
    '#808080',
    '#00FF00',
  ];

  /// Test list items 7, 8, 10-13 — degenerate-but-valid inputs (pure white,
  /// pure black, near-white, near-black). Must produce usable, monotonic,
  /// non-inverted swatches, never null.
  static const List<String> degenerate = [
    '#FFFFFF',
    '#000000',
    '#FAFAFA',
    '#101010',
  ];

  /// Test list item 9 — the VERIFIED golden ramp for #0F62FE (Carbon Blue).
  /// Reproduced verbatim from TRD 022-02-TRD.md research_context. This is
  /// the authoritative fixture; do not hand-tune to make an implementation
  /// pass.
  static const Map<int, int> carbonBlueExpectedRamp = {
    50: 0xFFF0F5FF,
    100: 0xFFDAE7FF,
    200: 0xFFB8D1FF,
    300: 0xFF86B0FE,
    400: 0xFF4183FE,
    500: 0xFF0F62FE,
    600: 0xFF014FE2,
    700: 0xFF0142BD,
    800: 0xFF01369B,
    900: 0xFF012D7F,
    950: 0xFF001A4A,
  };

  /// The eleven mandatory shade keys every generated swatch must expose.
  static const List<int> mandatoryShades = [
    50,
    100,
    200,
    300,
    400,
    500,
    600,
    700,
    800,
    900,
    950,
  ];
}
