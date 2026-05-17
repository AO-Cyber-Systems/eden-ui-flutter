// lib/dev_app/screens/theme_profiles_screen.dart
//
// Visual catalog: shows all 5 EdenThemeProfile aesthetics side-by-side
// with sample component triptych (button + badge + body card) under each.
// Per OBJECTIVE.md (009) Constraint 4 + Playbook habit 4: profile
// descriptions are hand-written from VERTICAL_UX_RESEARCH_2026-05-16.md
// §2.4.2 — Do NOT regenerate via LLM.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';

/// Catalog screen demonstrating all 5 [EdenThemeProfile] aesthetics.
///
/// Each profile is rendered inside its own [EdenAdaptiveTheme] wrapper so the
/// sample triptych (button + status badge + body card) renders with that
/// profile's colors / fonts / status palette. Brand-preset chips below the
/// triptych let the user toggle through recommended presets for the profile
/// — selecting a chip rebuilds the card with that brand applied (local card
/// state only; no app-wide effect).
class ThemeProfilesScreen extends StatelessWidget {
  const ThemeProfilesScreen({super.key});

  // Hand-written profile metadata per OBJECTIVE.md Constraint 4.
  // Sourced verbatim from VERTICAL_UX_RESEARCH_2026-05-16.md §2.4.2.
  static const _profileMeta = <EdenThemeProfile,
      ({
    String displayName,
    String description,
    List<String> recommendedVerticals
  })>{
    EdenThemeProfile.commercialWarm: (
      displayName: 'Commercial Warm',
      description: 'Default — warm gold on neutral. Salon, retail mid-market.',
      recommendedVerticals: ['default', 'commercial', 'salon'],
    ),
    EdenThemeProfile.medicalInstitutional: (
      displayName: 'Medical Institutional',
      description: 'Teal/cyan institutional. Sharper corners, IBM Plex Sans body.',
      recommendedVerticals: ['medical'],
    ),
    EdenThemeProfile.govFederal: (
      displayName: 'Gov Federal',
      description: 'USWDS-conformant. Public Sans, 4pt radii, ≥48pt touch floor.',
      recommendedVerticals: ['gov', 'federal'],
    ),
    EdenThemeProfile.retailVibrant: (
      displayName: 'Retail Vibrant',
      description: 'High-saturation magenta primary. POS / Shopify-style brand.',
      recommendedVerticals: ['retail'],
    ),
    EdenThemeProfile.legalProfessional: (
      displayName: 'Legal Professional',
      description: 'Slate primary + Crimson Pro display. Law-firm gravitas.',
      recommendedVerticals: ['legal'],
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Profiles'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        child: Wrap(
          spacing: EdenSpacing.space4,
          runSpacing: EdenSpacing.space4,
          children: [
            for (final profile in EdenThemeProfile.values)
              SizedBox(
                width: 320,
                child: _ProfileCard(
                  profile: profile,
                  meta: _profileMeta[profile]!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatefulWidget {
  const _ProfileCard({required this.profile, required this.meta});
  final EdenThemeProfile profile;
  final ({
    String displayName,
    String description,
    List<String> recommendedVerticals
  }) meta;

  @override
  State<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<_ProfileCard> {
  EdenBrandPreset? _selectedBrand;

  List<EdenBrandPreset> get _recommendedBrands {
    // Combine presets recommended for any of the profile's verticals.
    // Dedupe by id, cap at 4 to keep the chip row tidy at iPhone-narrow.
    final all = <String, EdenBrandPreset>{};
    for (final v in widget.meta.recommendedVerticals) {
      for (final p in EdenBrandPresetRegistry.forVertical(v)) {
        all[p.id] = p;
      }
    }
    return all.values.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    return EdenAdaptiveTheme(
      profile: widget.profile,
      brand: _selectedBrand,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(EdenSpacing.space4),
          child: Builder(
            // Builder so descendants resolve the wrapping Theme.
            builder: (context) {
              final theme = Theme.of(context);
              final palette = theme.extension<EdenStatusPalette>() ??
                  EdenStatusPalette.commercial();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.meta.displayName,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: EdenSpacing.space1),
                  Text(
                    widget.meta.description,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: EdenSpacing.space4),
                  // Sample triptych — button + status badge
                  Row(
                    children: [
                      FilledButton(
                        onPressed: () {},
                        child: const Text('Submit'),
                      ),
                      const SizedBox(width: EdenSpacing.space2),
                      _StatusPill(palette: palette, label: 'Active'),
                    ],
                  ),
                  const SizedBox(height: EdenSpacing.space3),
                  // Body sample card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(EdenSpacing.space3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      borderRadius: EdenRadii.borderRadiusMd,
                    ),
                    child: Text(
                      'Sample body text rendered in the active profile font.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  if (_recommendedBrands.isNotEmpty) ...[
                    const SizedBox(height: EdenSpacing.space4),
                    Text(
                      'Brand presets',
                      style: theme.textTheme.labelMedium,
                    ),
                    const SizedBox(height: EdenSpacing.space2),
                    Wrap(
                      spacing: EdenSpacing.space2,
                      runSpacing: EdenSpacing.space2,
                      children: [
                        for (final preset in _recommendedBrands)
                          ChoiceChip(
                            label: Text(preset.displayName),
                            selected: _selectedBrand?.id == preset.id,
                            onSelected: (selected) {
                              setState(() {
                                _selectedBrand = selected ? preset : null;
                              });
                            },
                          ),
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.palette, required this.label});
  final EdenStatusPalette palette;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space2,
        vertical: EdenSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: palette.successBg,
        borderRadius: EdenRadii.borderRadiusFull,
        border: Border.all(color: palette.successBorder),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(color: palette.successFg),
      ),
    );
  }
}
