import 'package:flutter/material.dart';

import '../../eden_ui.dart';
import '../widgets/section.dart';

/// Dev-catalog screen for Objective 011 USWDS conformance widgets.
///
/// TRD 011-11 creates the file with the USWDSBanner section.
/// TRD 011-12 appends the AgencyIdentifier section (header + footer).
/// Subsequent TRDs append:
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
        children: [
          const Section(
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
          Section(
            title: 'EdenAgencyIdentifier — Agency seal + name (header + footer)',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Header layout',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const EdenAgencyIdentifier(
                  identity: EdenAgencyIdentity(
                    agencyName: 'Department of Defense',
                    parentDepartment: 'Federal Government',
                    seal: Icon(
                      Icons.shield_outlined,
                      size: 32,
                      color: Color(0xFF1B1B1B),
                    ),
                  ),
                  layout: EdenAgencyIdentifierLayout.header,
                ),
                const SizedBox(height: 8),
                const EdenAgencyIdentifier(
                  identity: EdenAgencyIdentity(
                    agencyName: 'General Services Administration',
                    parentDepartment: 'Federal Government',
                  ),
                  layout: EdenAgencyIdentifierLayout.header,
                ),
                const SizedBox(height: 24),
                const Text('Footer layout',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Builder(builder: (context) {
                  return EdenAgencyIdentifier(
                    identity: const EdenAgencyIdentity(
                      agencyName: 'Department of Health and Human Services',
                      parentDepartment: 'Federal Government',
                      seal: Icon(
                        Icons.local_hospital_outlined,
                        size: 48,
                        color: Color(0xFFFFFFFF),
                      ),
                      contactLinks: [
                        EdenAgencyContactLink(label: 'About HHS', url: '/about'),
                        EdenAgencyContactLink(label: 'Privacy Policy', url: '/privacy'),
                        EdenAgencyContactLink(label: 'FOIA Requests', url: '/foia'),
                        EdenAgencyContactLink(label: 'Accessibility', url: '/accessibility'),
                        EdenAgencyContactLink(label: 'No FEAR Act', url: '/no-fear-act'),
                      ],
                    ),
                    layout: EdenAgencyIdentifierLayout.footer,
                    onContactLinkTap: (link) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Tapped: ${link.label} → ${link.url}'),
                        ),
                      );
                    },
                  );
                }),
              ],
            ),
          ),
          // TRD 011-13 will append: Section(title: 'EdenMemorableDate — USWDS M/D/Y input', child: ...).
          // TRD 011-14 will append: Section(title: 'EdenLanguageSelector — Language toggle', child: ...).
        ],
      ),
    );
  }
}
