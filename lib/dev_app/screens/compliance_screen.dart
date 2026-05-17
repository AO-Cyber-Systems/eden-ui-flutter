import 'package:flutter/material.dart';

import '../../eden_ui.dart';
import '../widgets/section.dart';

/// Dev-catalog screen for Objective 011 (Compliance Overlay Primitives).
///
/// TRD 011-01 creates the file with the ClassificationBanner section.
/// Subsequent TRDs (011-02 .. 011-10) APPEND additional Section(...)
/// entries beneath the placeholder comments below.
///
/// Reference layout: see scheduler_screen.dart / data_display_screen.dart.
class ComplianceScreen extends StatelessWidget {
  const ComplianceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compliance Overlay Primitives')),
      body: ListView(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        children: const [
          Section(
            title: 'EdenClassificationBanner — Federal + civilian sensitivity banners',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Federal (ICD 710 palette)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 12),
                EdenClassificationBanner(level: EdenClassificationLevel.unclassified),
                SizedBox(height: 8),
                EdenClassificationBanner(level: EdenClassificationLevel.controlledUnclassified),
                SizedBox(height: 8),
                EdenClassificationBanner(level: EdenClassificationLevel.secret),
                SizedBox(height: 8),
                EdenClassificationBanner(level: EdenClassificationLevel.topSecret),
                SizedBox(height: 24),
                Text(
                  'Civilian re-use (custom level)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 12),
                EdenSensitivityBanner(
                  level: EdenClassificationLevel.custom,
                  labelText: 'CONFIDENTIAL',
                  backgroundColor: Color(0xFFF59E0B),
                  foregroundColor: Color(0xFFFFFFFF),
                ),
                SizedBox(height: 8),
                EdenSensitivityBanner(
                  level: EdenClassificationLevel.custom,
                  labelText: 'ATTORNEY-CLIENT PRIVILEGED',
                  backgroundColor: Color(0xFFA855F7),
                  foregroundColor: Color(0xFFFFFFFF),
                ),
                SizedBox(height: 8),
                EdenSensitivityBanner(
                  level: EdenClassificationLevel.custom,
                  labelText: 'INTERNAL USE ONLY',
                  backgroundColor: Color(0xFF1F2937),
                  foregroundColor: Color(0xFFFFFFFF),
                ),
                SizedBox(height: 24),
                Text(
                  'Watermark mode (overlay)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: EdenClassificationBanner(
                    level: EdenClassificationLevel.topSecret,
                    display: EdenClassificationDisplay.watermark,
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Sensitive payload content'),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Scaffold dual-marking (top + bottom)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: EdenClassificationBannerScaffold(
                    level: EdenClassificationLevel.secret,
                    showBottomBanner: true,
                    child: Center(child: Text('Page body')),
                  ),
                ),
              ],
            ),
          ),
          // TRD 011-02 will append: Section(title: 'EdenCacPivButton — smartcard auth', child: ...).
          // TRD 011-03 will append: Section(title: 'EdenSection508Audit — a11y QA overlay', child: ...).
          // TRD 011-04 will append: Section(title: 'EdenAuditLogViewer — immutable activity stream', child: ...).
          // TRD 011-05 will append: Section(title: 'EdenFoiaRequestCard — records-request workflow', child: ...).
          // TRD 011-06 will append: Section(title: 'EdenCaseFileShell — multi-tab dossier', child: ...).
          // TRD 011-07 will append: Section(title: 'EdenPermissionMatrix federal-roles enhancement', child: ...).
          // TRD 011-08 will append: Section(title: 'EdenSecretField CUI clipboard enhancement', child: ...).
          // TRD 011-09 will append: Section(title: 'EdenFileUpload virus-scan / spillage enhancement', child: ...).
          // TRD 011-10 will append: Section(title: 'EdenMfaHardwareToken — YubiKey / RSA / CAC', child: ...).
        ],
      ),
    );
  }
}
