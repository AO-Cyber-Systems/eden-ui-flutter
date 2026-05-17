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
        children: [
          const Section(
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
          const Section(
            title: 'EdenCacPivButton — CAC/PIV smartcard authentication',
            child: _CacPivDemo(),
          ),
          const Section(
            title: 'EdenSection508Audit — Dev-tools a11y / Section 508 overlay',
            child: _Section508AuditDemo(),
          ),
          Section(
            title: 'EdenAuditLogViewer — Immutable activity stream + hash chain',
            child: SizedBox(
              height: 400,
              child: EdenAuditLogViewer(
                entries: [
                  EdenAuditLogEntry(
                    id: 'evt-001',
                    timestamp: DateTime(2026, 5, 16, 9, 30, 12),
                    actor: 'alice@dod.gov',
                    action: 'authenticated',
                    target: 'session/web',
                    category: 'auth',
                    prevHash: '0000000000000000000000000000000000000000000000000000000000000000',
                    currHash: 'a1b2000000000000000000000000000000000000000000000000000000000000',
                  ),
                  EdenAuditLogEntry(
                    id: 'evt-002',
                    timestamp: DateTime(2026, 5, 16, 9, 31, 5),
                    actor: 'bob@dod.gov',
                    action: 'read',
                    target: 'case-file/2026-CASE-0042',
                    category: 'data-access',
                    details: {
                      'file_size_bytes': '128048',
                      'classification': 'CUI',
                    },
                    prevHash: 'a1b2000000000000000000000000000000000000000000000000000000000000',
                    currHash: 'b3c4000000000000000000000000000000000000000000000000000000000000',
                  ),
                  EdenAuditLogEntry(
                    id: 'evt-003',
                    timestamp: DateTime(2026, 5, 16, 9, 32, 1),
                    actor: 'alice@dod.gov',
                    action: 'delete',
                    target: 'case-file/2026-CASE-0042',
                    category: 'data-access',
                    failed: true,
                    details: {'reason': 'insufficient_privileges'},
                    prevHash: 'b3c4000000000000000000000000000000000000000000000000000000000000',
                    currHash: 'c5d6000000000000000000000000000000000000000000000000000000000000',
                  ),
                  EdenAuditLogEntry(
                    id: 'evt-004',
                    timestamp: DateTime(2026, 5, 16, 9, 33, 12),
                    actor: 'system',
                    action: 'rotated',
                    target: 'session-key',
                    category: 'system',
                  ),
                ],
                brokenChainIndices: const {2},
              ),
            ),
          ),
          Section(
            title:
                'EdenFoiaRequestCard — Records request workflow (FOIA / GDPR DSAR)',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EdenFoiaRequestCard(
                  request: EdenFoiaRequest(
                    id: 'FOIA-2026-0042',
                    requesterName: 'Jane Citizen',
                    submittedAt: DateTime(2026, 5, 1),
                    dueAt: DateTime.now().add(const Duration(days: 28)),
                    subject: 'Records concerning policy memo X-2025',
                    assignedTo: 'analyst.foia@agency.gov',
                    responseDocCount: 12,
                  ),
                ),
                const SizedBox(height: 8),
                EdenFoiaRequestCard(
                  request: EdenFoiaRequest(
                    id: 'FOIA-2026-0043',
                    requesterName: 'John Public',
                    submittedAt: DateTime(2026, 5, 1),
                    dueAt: DateTime.now().add(const Duration(days: 10)),
                    subject: 'Emails between agency leadership Q1 2026',
                    assignedTo: 'analyst.foia@agency.gov',
                    redactionPassStatus: EdenFoiaRedactionStatus.inProgress,
                  ),
                ),
                const SizedBox(height: 8),
                EdenFoiaRequestCard(
                  request: EdenFoiaRequest(
                    id: 'FOIA-2026-0044',
                    requesterName: 'Press Corp',
                    submittedAt: DateTime(2026, 5, 1),
                    dueAt: DateTime.now().add(const Duration(days: 5)),
                    subject: 'Budget allocation Q1',
                    exemptionCodes: const ['b1', 'b5', 'b7'],
                    redactionPassStatus: EdenFoiaRedactionStatus.complete,
                  ),
                ),
                const SizedBox(height: 8),
                EdenFoiaRequestCard(
                  request: EdenFoiaRequest(
                    id: 'FOIA-2026-0010',
                    requesterName: 'Watchdog NGO',
                    submittedAt: DateTime(2026, 3, 1),
                    dueAt: DateTime.now().subtract(const Duration(days: 3)),
                    subject: 'Personnel records for Director Smith',
                    exemptionCodes: const ['b6'],
                    redactionPassStatus: EdenFoiaRedactionStatus.blocked,
                  ),
                ),
                const SizedBox(height: 8),
                EdenFoiaRequestCard(
                  request: EdenFoiaRequest(
                    id: 'FOIA-2026-0099',
                    requesterName: 'Inter-agency request',
                    submittedAt: DateTime(2026, 5, 1),
                    dueAt: DateTime.now().add(const Duration(days: 20)),
                    subject: 'Classified materials review',
                    classification: EdenClassificationLevel.secret,
                    exemptionCodes: const ['b1'],
                  ),
                ),
              ],
            ),
          ),
          Section(
            title:
                'EdenCaseFileShell — Multi-tab regulated dossier (CAPSTONE: composes 011-01 + 011-04)',
            child: SizedBox(
              height: 600,
              child: EdenCaseFileShell(
                data: EdenCaseFileData(
                  caseId: 'CASE-2026-0042',
                  caseTitle: 'Smith Family — Social services intake',
                  status: 'Open',
                  openedAt: DateTime(2026, 5, 10),
                  classification: EdenClassificationLevel.controlledUnclassified,
                  assignedTo: 'caseworker.jones@dhhs.gov',
                  headerMetadata: const {
                    'County': 'Cobb',
                    'Program': 'Child welfare',
                    'Priority': 'Standard',
                  },
                  activityEntries: [
                    EdenCaseFileActivity(
                      id: 'a1',
                      actor: 'caseworker.jones@dhhs.gov',
                      timestamp: DateTime(2026, 5, 10, 9, 14),
                      title: 'Case opened',
                      body: 'Initial intake interview scheduled.',
                    ),
                    EdenCaseFileActivity(
                      id: 'a2',
                      actor: 'supervisor@dhhs.gov',
                      timestamp: DateTime(2026, 5, 11, 12, 0),
                      title: 'Supervisor review completed',
                    ),
                  ],
                  documents: [
                    EdenCaseFileDocument(
                      id: 'd1',
                      name: 'intake-form.pdf',
                      sizeBytes: 1024 * 80,
                      uploadedAt: DateTime(2026, 5, 10, 9, 14),
                      uploadedBy: 'caseworker.jones@dhhs.gov',
                    ),
                    EdenCaseFileDocument(
                      id: 'd2',
                      name: 'medical-history.pdf',
                      sizeBytes: 1024 * 240,
                      uploadedAt: DateTime(2026, 5, 11, 11, 30),
                      uploadedBy: 'caseworker.jones@dhhs.gov',
                    ),
                  ],
                  contacts: const [
                    EdenCaseFileContact(
                      id: 'c1',
                      name: 'Alex Subject',
                      role: 'Subject',
                      contactInfo: {
                        'phone': '555-0101',
                        'email': 'alex@example.com',
                      },
                    ),
                    EdenCaseFileContact(
                      id: 'c2',
                      name: 'Dana Counsel',
                      role: 'Counsel',
                      contactInfo: {'phone': '555-0202'},
                    ),
                  ],
                  notes: [
                    EdenCaseFileNote(
                      id: 'n1',
                      author: 'caseworker.jones@dhhs.gov',
                      timestamp: DateTime(2026, 5, 10, 10, 0),
                      content:
                          'Initial intake interview completed. No follow-up issues raised.',
                    ),
                    EdenCaseFileNote(
                      id: 'n2',
                      author: 'counsel.smith@law.dhhs.gov',
                      timestamp: DateTime(2026, 5, 12, 14, 30),
                      content:
                          'Attorney-client confidential strategy note — do not share.',
                      isPrivileged: true,
                    ),
                  ],
                  auditEntries: [
                    EdenAuditLogEntry(
                      id: 'evt-001',
                      timestamp: DateTime(2026, 5, 10, 9, 0),
                      actor: 'caseworker.jones@dhhs.gov',
                      action: 'created',
                      target: 'case-file/CASE-2026-0042',
                      category: 'lifecycle',
                      prevHash:
                          '0000000000000000000000000000000000000000000000000000000000000000',
                      currHash:
                          'a1b2000000000000000000000000000000000000000000000000000000000000',
                    ),
                    EdenAuditLogEntry(
                      id: 'evt-002',
                      timestamp: DateTime(2026, 5, 11, 12, 0),
                      actor: 'supervisor@dhhs.gov',
                      action: 'reviewed',
                      target: 'case-file/CASE-2026-0042',
                      category: 'review',
                      prevHash:
                          'a1b2000000000000000000000000000000000000000000000000000000000000',
                      currHash:
                          'b3c4000000000000000000000000000000000000000000000000000000000000',
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Section(
            title:
                'EdenPermissionMatrix — Federal roles + break-glass override',
            child: _PermissionMatrixDemo(),
          ),
          const Section(
            title: 'EdenSecretField — CUI clipboard enhancement (classified mode)',
            child: _SecretFieldDemo(),
          ),
          const Section(
            title:
                'EdenFileUpload — virus scan / CUI marking / spillage quarantine',
            child: EdenFileUpload(
              label: 'Upload classified document',
              files: [
                EdenUploadFile(
                  name: 'normal.pdf',
                  sizeBytes: 1024 * 30,
                  status: EdenUploadStatus.complete,
                ),
                EdenUploadFile(
                  name: 'scanning.pdf',
                  sizeBytes: 1024 * 50,
                  status: EdenUploadStatus.virusScanning,
                  scanProgress: 0.6,
                ),
                EdenUploadFile(
                  name: 'malware.exe',
                  sizeBytes: 1024 * 200,
                  status: EdenUploadStatus.virusScanFailed,
                ),
                EdenUploadFile(
                  name: 'pii.csv',
                  sizeBytes: 1024 * 10,
                  status: EdenUploadStatus.cuiMarked,
                  cuiMarking: 'CUI//SP-PII',
                ),
                EdenUploadFile(
                  name: 'spillage.zip',
                  sizeBytes: 1024 * 80,
                  status: EdenUploadStatus.quarantined,
                  quarantineReason: 'Trojan signature detected',
                ),
              ],
            ),
          ),
          const Section(
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

/// Interactive demo of [EdenSection508Audit] — populates the controller
/// with 3 example issues spanning all three severities + categories.
class _Section508AuditDemo extends StatefulWidget {
  const _Section508AuditDemo();

  @override
  State<_Section508AuditDemo> createState() => _Section508AuditDemoState();
}

class _Section508AuditDemoState extends State<_Section508AuditDemo> {
  final _controller = EdenSection508AuditController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runDemoScan() async {
    _controller.startScan();
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    _controller.completeScan(const [
      EdenSection508Issue(
        severity: EdenSection508Severity.error,
        category: EdenSection508Category.missingSemanticLabel,
        description: 'IconButton at home_screen.dart:75 has no Semantics label',
        fixHint: 'Wrap with Semantics(label: "Open settings")',
        widgetTypeName: 'IconButton',
      ),
      EdenSection508Issue(
        severity: EdenSection508Severity.warning,
        category: EdenSection508Category.insufficientContrast,
        description: 'Subtitle text on light gray ratio 3.8:1',
        fixHint: 'Switch to Theme.of(context).colorScheme.onSurfaceVariant',
        widgetTypeName: 'Text',
      ),
      EdenSection508Issue(
        severity: EdenSection508Severity.info,
        category: EdenSection508Category.missingFocusOrder,
        description: 'Form lacks FocusTraversalGroup',
        fixHint: 'Wrap form Column in FocusTraversalGroup',
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Demo populates the audit controller with 3 example issues.',
          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton(
              onPressed: _runDemoScan,
              child: const Text('Run demo scan'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: _controller.reset,
              child: const Text('Reset'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'The audit panel renders as a floating button (bottom-right) '
          'inside the surface below. Tap it to view detected issues.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        SizedBox(
          height: 400,
          child: Stack(
            children: [
              Container(
                color: Colors.grey.shade100,
                child: const Center(child: Text('(host app surface)')),
              ),
              EdenSection508Audit(controller: _controller),
            ],
          ),
        ),
      ],
    );
  }
}

/// Interactive demo of [EdenPermissionMatrix] with [EdenFederalRoles]
/// preset + break-glass override. Tapping a denied cell's lock icon
/// opens the justification dialog; on confirm, a SnackBar surfaces the
/// captured override.
class _PermissionMatrixDemo extends StatefulWidget {
  const _PermissionMatrixDemo();

  @override
  State<_PermissionMatrixDemo> createState() => _PermissionMatrixDemoState();
}

class _PermissionMatrixDemoState extends State<_PermissionMatrixDemo> {
  static const _permissions = [
    EdenPermission(
      id: 'view_audit_log',
      label: 'View audit log',
      category: 'Audit',
    ),
    EdenPermission(
      id: 'export_audit_log',
      label: 'Export audit log',
      category: 'Audit',
    ),
    EdenPermission(
      id: 'modify_security_policy',
      label: 'Modify security policy',
      category: 'Security',
    ),
    EdenPermission(
      id: 'approve_break_glass',
      label: 'Approve break-glass override',
      category: 'Security',
    ),
    EdenPermission(
      id: 'create_user',
      label: 'Create user',
      category: 'User management',
    ),
    EdenPermission(
      id: 'reset_password',
      label: 'Reset password',
      category: 'User management',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Federal roles preset: Privileged User / ISSO / ISSM. '
          'Tap any denied cell’s lock-open icon to open the '
          'break-glass justification dialog (≥ 20 chars).',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 400,
          child: EdenPermissionMatrix(
            permissions: _permissions,
            roles: EdenFederalRoles.allFederal,
            breakGlassMode: true,
            onBreakGlass: (roleId, permId, just) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Break-glass: $roleId/$permId — "$just"',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
