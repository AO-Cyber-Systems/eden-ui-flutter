import 'package:flutter/material.dart';

import 'eden_otp_input.dart';

/// Hardware MFA token types supported by [EdenMfaHardwareToken].
enum EdenMfaTokenType {
  /// FIDO2 / WebAuthn — physical tap, no code entry.
  yubikey,

  /// RSA SecurID rotating 6-digit code.
  rsaSecurId,

  /// CAC backup 8-digit code.
  cacBackup,
}

/// Hardware MFA token entry affordance — YubiKey (FIDO2/WebAuthn tap),
/// RSA SecurID (rotating 6-digit), or CAC backup code (8-digit).
///
/// Composes [EdenOtpInput] for code entry. Provides a consistent UI
/// shape across three federal token-type patterns.
///
/// **Library scope: interface-only.** No WebAuthn/FIDO2 platform-channel
/// code. Consumer wires the YubiKey/WebAuthn flow via [onTouchRequested]
/// and verifies submitted codes externally via [onCodeSubmitted].
///
/// Civilian re-use: the widget also serves commercial-vertical hardware
/// MFA — YubiKey is common in finance/tech for high-security accounts;
/// RSA SecurID is common in healthcare/legal/banking.
class EdenMfaHardwareToken extends StatefulWidget {
  const EdenMfaHardwareToken({
    super.key,
    required this.type,
    this.errorMessage,
    this.onTouchRequested,
    this.onCodeSubmitted,
  });

  final EdenMfaTokenType type;

  /// Optional consumer-controlled error message. When non-null, renders
  /// an inline error row beneath the body.
  final String? errorMessage;

  /// Fires when the user taps Start in [EdenMfaTokenType.yubikey] mode.
  /// Consumer wires WebAuthn/FIDO2 flow here.
  final VoidCallback? onTouchRequested;

  /// Fires when the user submits the OTP code in
  /// [EdenMfaTokenType.rsaSecurId] or [EdenMfaTokenType.cacBackup] mode.
  /// Consumer verifies the code externally.
  final ValueChanged<String>? onCodeSubmitted;

  @override
  State<EdenMfaHardwareToken> createState() => _EdenMfaHardwareTokenState();
}

class _EdenMfaHardwareTokenState extends State<EdenMfaHardwareToken> {
  String _code = '';

  int get _expectedLength {
    switch (widget.type) {
      case EdenMfaTokenType.rsaSecurId:
        return 6;
      case EdenMfaTokenType.cacBackup:
        return 8;
      case EdenMfaTokenType.yubikey:
        return 0;
    }
  }

  bool get _canSubmit => _code.length == _expectedLength && _expectedLength > 0;

  String get _semanticLabel {
    switch (widget.type) {
      case EdenMfaTokenType.yubikey:
        return 'YubiKey tap required';
      case EdenMfaTokenType.rsaSecurId:
        return 'RSA SecurID 6-digit code entry';
      case EdenMfaTokenType.cacBackup:
        return 'CAC backup 8-digit code entry';
    }
  }

  Widget _buildBody() {
    switch (widget.type) {
      case EdenMfaTokenType.yubikey:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              children: [
                Icon(Icons.usb, size: 24),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Tap your YubiKey',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Awaiting tap…',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: widget.onTouchRequested,
              child: const Text('Start'),
            ),
          ],
        );
      case EdenMfaTokenType.rsaSecurId:
      case EdenMfaTokenType.cacBackup:
        final hint = widget.type == EdenMfaTokenType.rsaSecurId
            ? 'Enter the 6-digit code from your token'
            : 'Enter your 8-digit backup code';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(hint),
            const SizedBox(height: 12),
            // Horizontal scroll so that 8-digit cacBackup OTP doesn't
            // overflow narrow viewports (8 × 44pt + 7 × 8pt = 408pt).
            // Bounded height (52pt — EdenOtpInput.boxHeight default) so
            // the scroll view doesn't expand vertically.
            SizedBox(
              height: 52,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: EdenOtpInput(
                  length: _expectedLength,
                  onChanged: (v) => setState(() => _code = v),
                  onSubmit: (v) => setState(() => _code = v),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _canSubmit
                  ? () => widget.onCodeSubmitted?.call(_code)
                  : null,
              child: const Text('Submit'),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _semanticLabel,
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBody(),
          if (widget.errorMessage != null) ...[
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      widget.errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
