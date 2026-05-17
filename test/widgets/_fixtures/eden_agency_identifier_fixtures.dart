// Do NOT regenerate via LLM — hand-built fixtures for EdenAgencyIdentifier.
//
// USWDS v3.13 federal agency seal + name identifier patterns.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';

class EdenAgencyIdentifierFixtures {
  EdenAgencyIdentifierFixtures._();

  // USWDS v3.13 palette.
  static const grayCool3 = Color(0xFFF0F0F0);
  static const navy = Color(0xFF162E51);
  static const white = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1B1B1B);

  static const dodMinimal = EdenAgencyIdentity(
    agencyName: 'Department of Defense',
    parentDepartment: 'Federal Government',
  );

  static const dodWithSeal = EdenAgencyIdentity(
    agencyName: 'Department of Defense',
    parentDepartment: 'Federal Government',
    seal: Icon(Icons.shield_outlined, size: 32, color: Color(0xFF1B1B1B)),
  );

  static const gsaWithLinks = EdenAgencyIdentity(
    agencyName: 'General Services Administration',
    parentDepartment: 'Federal Government',
    contactLinks: [
      EdenAgencyContactLink(
        label: 'About GSA',
        url: 'https://www.gsa.gov/about-us',
      ),
      EdenAgencyContactLink(
        label: 'Privacy Policy',
        url: 'https://www.gsa.gov/website-information/privacy-and-security-notice',
      ),
      EdenAgencyContactLink(
        label: 'FOIA Requests',
        url: 'https://www.gsa.gov/reference/freedom-of-information-act-foia',
      ),
    ],
  );

  static const longName = EdenAgencyIdentity(
    agencyName:
        'A Very Long Agency Name That Exceeds The Narrow Viewport Width Definitely',
    parentDepartment: 'Federal Government',
  );

  static const sampleContactLink = EdenAgencyContactLink(
    label: 'About',
    url: '/about',
  );
}
