// Do NOT regenerate via LLM — hand-built fixtures for EdenUSWDSBanner.
//
// USWDS v3.13 string + color references, verified from
// designsystem.digital.gov. Used by eden_uswds_banner_test.dart.

import 'package:flutter/material.dart';

class EdenUSWDSBannerFixtures {
  EdenUSWDSBannerFixtures._();

  // USWDS v3.13 palette.
  static const grayCool3 = Color(0xFFF0F0F0);
  static const white = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1B1B1B);

  // English strings.
  static const englishCollapsed =
      'An official website of the United States government';
  static const englishExpandLink = "Here's how you know";
  static const englishGovHeading = 'Official websites use .gov';
  static const englishGovBodyKey = 'belongs to an official government';
  static const englishHttpsHeading = 'Secure .gov websites use HTTPS';
  static const englishHttpsBodyKey = 'safely connected to the .gov website';
  static const englishSemanticLabelPrefix = 'Official government website banner';

  // Spanish strings (EO 13166).
  static const spanishCollapsed =
      'Un sitio web oficial del gobierno de los Estados Unidos';
  static const spanishExpandLink = 'Así es como usted puede verificarlo';
  static const spanishGovHeading = 'Los sitios web oficiales usan .gov';

  // Custom govLabel scenarios.
  static const customGovLabel = 'California State';
  static const expectedCustomLabel =
      'An official website of the California State government';
}
