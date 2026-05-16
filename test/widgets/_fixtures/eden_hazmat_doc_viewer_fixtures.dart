// Do NOT regenerate via LLM — hand-built fixtures for EdenHazmatDocViewer.
import 'package:eden_ui_flutter/eden_ui.dart';

/// Hand-built fixtures for EdenHazmatDocViewer tests.
class EdenHazmatDocViewerFixtures {
  EdenHazmatDocViewerFixtures._();

  static const EdenAttachment manifestPdf = EdenAttachment(
    name: 'manifest-2026-05-16.pdf',
    size: 124500,
    type: 'application/pdf',
    url: 'https://example.com/manifest.pdf',
  );

  static const EdenAttachment manifestNoUrl = EdenAttachment(
    name: 'manifest-2026-05-16.pdf',
    size: 0,
    type: 'application/pdf',
  );

  static const EdenAttachment msdsPdf = EdenAttachment(
    name: 'msds-propane.pdf',
    size: 89200,
    type: 'application/pdf',
    url: 'https://example.com/msds.pdf',
  );

  static const EdenHazmatDocData full = EdenHazmatDocData(
    manifestAttachment: manifestPdf,
    msdsAttachment: msdsPdf,
    driverCertLabel: 'DOT HM-126F • Driver J. Smith',
  );

  static const EdenHazmatDocData expiring = EdenHazmatDocData(
    manifestAttachment: manifestPdf,
    msdsAttachment: msdsPdf,
    driverCertLabel: 'DOT HM-126F • Driver J. Smith',
    certStatus: EdenHazmatCertStatus.expiringSoon,
  );

  static const EdenHazmatDocData expired = EdenHazmatDocData(
    manifestAttachment: manifestPdf,
    msdsAttachment: msdsPdf,
    driverCertLabel: 'DOT HM-126F • Driver J. Smith',
    certStatus: EdenHazmatCertStatus.expired,
  );

  static const EdenHazmatDocData noneCert = EdenHazmatDocData(
    manifestAttachment: manifestPdf,
    msdsAttachment: msdsPdf,
    driverCertLabel: 'Driver J. Smith',
    certStatus: EdenHazmatCertStatus.none,
  );

  static const EdenHazmatDocData noDriverCert = EdenHazmatDocData(
    manifestAttachment: manifestPdf,
    msdsAttachment: msdsPdf,
  );

  static const EdenHazmatDocData noMsds = EdenHazmatDocData(
    manifestAttachment: manifestPdf,
    driverCertLabel: 'DOT HM-126F • Driver J. Smith',
  );

  static const EdenHazmatDocData noManifestUrl = EdenHazmatDocData(
    manifestAttachment: manifestNoUrl,
    driverCertLabel: 'DOT HM-126F • Driver J. Smith',
  );

  static const EdenHazmatDocData longCert = EdenHazmatDocData(
    manifestAttachment: manifestPdf,
    driverCertLabel:
        'United States Department of Transportation Hazardous Materials Registration Number HM-126F-2026-EXTREME-LONG-DRIVER-NAME-JOHNATHAN-Q-SMITH',
  );
}
