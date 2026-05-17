import 'package:flutter/material.dart';

import '../../eden_ui.dart';
import '../widgets/section.dart';

/// Dev-catalog screen for Objective 011 (Compliance Overlay Primitives).
///
/// TRD 011-01 creates the file with the ClassificationBanner section.
/// TRD 011-02 appends the EdenCacPivButton interactive demo.
/// Subsequent TRDs (011-03 .. 011-10) APPEND additional Section(...)
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
          Section(
            title: 'EdenCacPivButton — CAC/PIV smartcard authentication',
            child: _CacPivDemo(),
          ),
          // TRD 011-03 will append: Section(title: 'EdenSection508Audit — a11y QA overlay', child: ...).
          // TRD 011-04 will append: Section(title: 'EdenAuditLogViewer — immutable activity stream', child: ...).
          // TRD 011-05 will append: Section(title: 'EdenFoiaRequestCard — records-request workflow', child: ...).
          // TRD 011-06 will append: Section(title: 'EdenCaseFileShell — multi-tab dossier', child: ...).
          // TRD 011-07 will append: Section(title: 'EdenPermissionMatrix federal-roles enhancement', child: ...).
          Section(
            title: 'EdenSecretField — CUI clipboard enhancement (classified mode)',
            child: _SecretFieldDemo(),
          ),
          // TRD 011-09 will append: Section(title: 'EdenFileUpload virus-scan / spillage enhancement', child: ...).
          Section(
            title: 'EdenMfaHardwareToken — Hardware MFA token entry (YubiKey / RSA / CAC backup)',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YubiKey (FIDO2 tap)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                EdenMfaHardwareToken(type: EdenMfaTokenType.yubikey),
                SizedBox(height: 24),
                Text(
                  'RSA SecurID (6-digit rotating code)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                EdenMfaHardwareToken(type: EdenMfaTokenType.rsaSecurId),
                SizedBox(height: 24),
                Text(
                  'CAC backup (8-digit code)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                EdenMfaHardwareToken(type: EdenMfaTokenType.cacBackup),
                SizedBox(height: 24),
                Text(
                  'Error display variant',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                EdenMfaHardwareToken(
                  type: EdenMfaTokenType.rsaSecurId,
                  errorMessage: 'Invalid code. Please try again.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Interactive demo of [EdenCacPivButton] cycling through all 5 states.
/// Accepts PIN "123456" as the success path; any other PIN triggers
/// the error state with a 'Try again' affordance.
class _CacPivDemo extends StatefulWidget {
  const _CacPivDemo();

  @override
  State<_CacPivDemo> createState() => _CacPivDemoState();
}

class _CacPivDemoState extends State<_CacPivDemo> {
  final _controller = EdenCacPivController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _simulateFlow() async {
    _controller.transitionTo(EdenCacPivState.reading);
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    _controller.transitionTo(EdenCacPivState.promptPin);
  }

  Future<void> _simulatePinVerify(String pin) async {
    _controller.transitionTo(EdenCacPivState.authenticating);
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    if (pin == '123456') {
      _controller.reset(); // success → idle for demo loop
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authenticated! (demo)')),
      );
    } else {
      _controller.transitionTo(
        EdenCacPivState.error,
        errorMessage: 'PIN verification failed. Demo accepts "123456".',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Interactive demo (PIN = "123456")',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        EdenCacPivButton(
          controller: _controller,
          onInsertRequested: _simulateFlow,
          onPinSubmitted: _simulatePinVerify,
        ),
      ],
    );
  }
}

/// Interactive demo of [EdenSecretField] showing standard vs classified
/// clipboard mode side-by-side. Classified mode suppresses the copy
/// affordance and warns on outside-paste (>4-char delta heuristic).
class _SecretFieldDemo extends StatefulWidget {
  const _SecretFieldDemo();

  @override
  State<_SecretFieldDemo> createState() => _SecretFieldDemoState();
}

class _SecretFieldDemoState extends State<_SecretFieldDemo> {
  String _standardValue = 'my-api-key-abc123';
  String _classifiedValue = 'CUI-PII-SSN-456-78-9012';
  String? _warning;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Standard mode (default — backwards compatible)',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        EdenSecretField(
          label: 'API key',
          value: _standardValue,
          onChanged: (v) => setState(() => _standardValue = v),
          onCopy: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Copied to clipboard (standard mode allows it)'),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        const Text(
          'Classified mode (CUI — copy disabled, paste warns)',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        EdenSecretField(
          label: 'CUI PII data',
          value: _classifiedValue,
          clipboardMode: EdenSecretClipboardMode.classified,
          onChanged: (v) => setState(() => _classifiedValue = v),
          onCopy: () {
            // Will not fire in classified mode — button suppressed.
          },
          onPasteFromOutsideWarning: () {
            setState(() => _warning =
                'WARNING: paste from outside detected — content may be from non-classified source');
          },
        ),
        if (_warning != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.orange.shade100,
            child: Text(
              _warning!,
              style: const TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ],
    );
  }
}
