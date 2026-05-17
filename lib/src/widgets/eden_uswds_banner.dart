import 'package:flutter/material.dart';

/// Language for the USWDS banner strings.
///
/// `en` (default) ships English text per USWDS v3.13 spec; `es` ships the
/// Spanish equivalents per Executive Order 13166 (Improving Access to
/// Services for Persons with Limited English Proficiency).
enum EdenUSWDSLanguage { en, es }

/// String table for USWDS banner content per supported language.
///
/// Sources (research-confirmed 2026-05-16):
///   - English: designsystem.digital.gov v3.13 "banner" component
///   - Spanish: designsystem.digital.gov v3.13 Spanish translations
const Map<EdenUSWDSLanguage, Map<String, String>> _bannerStrings = {
  EdenUSWDSLanguage.en: {
    'collapsed_template': 'An official website of the {gov} government',
    'expand_link': "Here's how you know",
    'gov_heading': 'Official websites use .gov',
    'gov_body':
        'A .gov website belongs to an official government organization in the United States.',
    'https_heading': 'Secure .gov websites use HTTPS',
    'https_body':
        "A lock (\u{1F512}) or https:// means you've safely connected to the .gov website. Share sensitive information only on official, secure websites.",
    'semantic_label': 'Official government website banner',
  },
  EdenUSWDSLanguage.es: {
    'collapsed_template': 'Un sitio web oficial del gobierno de los {gov}',
    'expand_link': 'Así es como usted puede verificarlo',
    'gov_heading': 'Los sitios web oficiales usan .gov',
    'gov_body':
        'Un sitio web .gov pertenece a una organización oficial del Gobierno de los Estados Unidos.',
    'https_heading': 'Los sitios web seguros .gov usan HTTPS',
    'https_body':
        'Un candado (\u{1F512}) o https:// significa que se conectó de forma segura al sitio web .gov.',
    'semantic_label': 'Bandera oficial del sitio web del gobierno',
  },
};

/// The federally-mandated "An official website of the United States
/// government" banner per USWDS (U.S. Web Design System) v3.13.
///
/// Required on every federal government website. Renders flag icon +
/// collapsed label + expand affordance + chevron. Tapping expands the
/// "Here's how you know" panel explaining the .gov + HTTPS lock
/// authenticity signals.
///
/// Optional [language] supports English (default) and Spanish per
/// Executive Order 13166.
///
/// Optional [govLabel] overrides 'United States' for state-government or
/// agency-specific contexts (e.g., 'California State', 'Cobb County').
/// When the language is Spanish AND no explicit [govLabel] is provided,
/// the default falls back to the Spanish form ('Estados Unidos').
///
/// Civilian re-use: pair with [EdenAgencyIdentifier] (footer layout) to
/// form the standard USWDS chrome. The widget is also useful in
/// commercial verticals as a general "official banner" affordance —
/// pass a custom `govLabel` to repurpose for state, municipal, or
/// quasi-government use.
class EdenUSWDSBanner extends StatefulWidget {
  const EdenUSWDSBanner({
    super.key,
    this.language = EdenUSWDSLanguage.en,
    this.govLabel,
  });

  /// Language for banner text. Defaults to English.
  final EdenUSWDSLanguage language;

  /// Government label substituted into the collapsed template
  /// ('An official website of the {gov} government' / 'Un sitio web
  /// oficial del gobierno de los {gov}'). When null, defaults to
  /// 'United States' for [EdenUSWDSLanguage.en] and 'Estados Unidos'
  /// for [EdenUSWDSLanguage.es].
  final String? govLabel;

  @override
  State<EdenUSWDSBanner> createState() => _EdenUSWDSBannerState();
}

class _EdenUSWDSBannerState extends State<EdenUSWDSBanner> {
  bool _expanded = false;

  Map<String, String> get _strings => _bannerStrings[widget.language]!;

  static const _defaultGovLabels = <EdenUSWDSLanguage, String>{
    EdenUSWDSLanguage.en: 'United States',
    EdenUSWDSLanguage.es: 'Estados Unidos',
  };

  String get _effectiveGovLabel =>
      widget.govLabel ?? _defaultGovLabels[widget.language]!;

  String get _collapsedLabel =>
      _strings['collapsed_template']!.replaceAll('{gov}', _effectiveGovLabel);

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${_strings['semantic_label']!}, expandable',
      button: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: _toggle,
            child: Container(
              color: const Color(0xFFF0F0F0),
              constraints: const BoxConstraints(minHeight: 36),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.flag, size: 16, color: Color(0xFF1B1B1B)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _collapsedLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1B1B1B),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _strings['expand_link']!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1B1B1B),
                        decoration: TextDecoration.underline,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more_rounded, size: 16),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            ClipRect(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.topCenter,
                child: _ExpandedPanel(strings: _strings),
              ),
            ),
        ],
      ),
    );
  }
}

class _ExpandedPanel extends StatelessWidget {
  const _ExpandedPanel({required this.strings});

  final Map<String, String> strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('uswds-expanded-panel'),
      color: const Color(0xFFFFFFFF),
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 600;
          final tile1 = _Tile(
            icon: Icons.account_balance_outlined,
            heading: strings['gov_heading']!,
            body: strings['gov_body']!,
          );
          final tile2 = _Tile(
            icon: Icons.lock_outlined,
            heading: strings['https_heading']!,
            body: strings['https_body']!,
          );
          return isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: tile1),
                    const SizedBox(width: 16),
                    Expanded(child: tile2),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    tile1,
                    const SizedBox(height: 16),
                    tile2,
                  ],
                );
        },
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.heading,
    required this.body,
  });

  final IconData icon;
  final String heading;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 28, color: const Color(0xFF1B1B1B)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                heading,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
