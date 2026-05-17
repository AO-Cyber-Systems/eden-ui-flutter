import 'package:flutter/material.dart';

import '../../eden_ui.dart';
import '../widgets/section.dart';

/// Dev-catalog screen for Objective 011 USWDS conformance widgets.
///
/// TRD 011-11 creates the file with the USWDSBanner section.
/// Subsequent TRDs append:
///   - 011-12 → EdenAgencyIdentifier
///   - 011-13 → EdenMemorableDate
///   - 011-14 → EdenLanguageSelector
class UswdsScreen extends StatelessWidget {
  const UswdsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('USWDS Conformance')),
      body: ListView(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        children: const [
          Section(
            title: 'EdenUSWDSBanner — Official government website banner',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('English (default)',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                EdenUSWDSBanner(),
                SizedBox(height: 24),
                Text('Spanish (EO 13166)',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                EdenUSWDSBanner(language: EdenUSWDSLanguage.es),
                SizedBox(height: 24),
                Text('State government (California)',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                EdenUSWDSBanner(govLabel: 'California State'),
                SizedBox(height: 24),
                Text('Municipal (Cobb County)',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                EdenUSWDSBanner(govLabel: 'Cobb County'),
              ],
            ),
          ),
          // TRD 011-12 will append: Section(title: 'EdenAgencyIdentifier — Agency seal + name (header + footer)', child: ...).
          // TRD 011-13 will append: Section(title: 'EdenMemorableDate — USWDS M/D/Y input', child: ...).
          // TRD 011-14 will append: Section(title: 'EdenLanguageSelector — Language toggle', child: ...).
        ],
      ),
    );
  }
}
