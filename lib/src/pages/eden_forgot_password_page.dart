import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../widgets/eden_button.dart';
import '../widgets/eden_field_purpose.dart';
import '../widgets/eden_input.dart';
import '../widgets/eden_alert.dart';
import '../widgets/eden_selectable_region.dart';

/// A forgot-password page that collects an email address and sends a reset link.
///
/// After a successful submission, the form is replaced with a success message
/// prompting the user to check their email.
///
/// ## Autofill
///
/// The single field carries [EdenFieldPurpose.email], which resolves its hints
/// and keyboard together (`editable_text.dart:1855-1858`).
///
/// Unlike the sign-in, sign-up and reset pages, this page deliberately installs
/// NO `EdenAutofillScope`. A scope exists to make a credential SAVABLE, and
/// there is no credential here -- only an address the user is asking a link to
/// be sent to. Filling works from the hint alone, with no group
/// (`text_editing.dart:514-531` applies per element), so a group would add a
/// hidden web `<form>` and a save path for something that must never be saved
/// as a credential. The absence is a decision, not an oversight.
class EdenForgotPasswordPage extends StatefulWidget {
  const EdenForgotPasswordPage({
    super.key,
    required this.onSendResetLink,
    this.onBackToLoginTap,
    this.logo,
    this.title = 'Reset your password',
    this.subtitle = "Enter your email and we'll send you a reset link",
  });

  /// Called when the user submits their email for a password reset.
  final Future<void> Function(String email) onSendResetLink;

  /// Navigate back to the login page.
  final VoidCallback? onBackToLoginTap;

  /// Optional logo widget rendered at the top.
  final Widget? logo;

  /// Page title.
  final String title;

  /// Page subtitle.
  final String subtitle;

  @override
  State<EdenForgotPasswordPage> createState() =>
      _EdenForgotPasswordPageState();
}

class _EdenForgotPasswordPageState extends State<EdenForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _success = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendResetLink() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() => _error = 'Please enter your email address.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await widget.onSendResetLink(email);
      if (mounted) {
        setState(() => _success = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: EdenSelectableRegion(child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: EdenSpacing.space5,
            vertical: EdenSpacing.space8,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: _success
                ? _buildSuccessState(theme, isDark)
                : _buildForm(theme, isDark),
          ),
        ),
      )),
    );
  }

  Widget _buildSuccessState(ThemeData theme, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Logo
        if (widget.logo != null) ...[
          Center(child: widget.logo!),
          const SizedBox(height: EdenSpacing.space6),
        ],

        // Success icon
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: EdenColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_read_outlined,
              size: 32,
              color: EdenColors.success,
            ),
          ),
        ),
        const SizedBox(height: EdenSpacing.space6),

        // Success message
        Text(
          'Check your email',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: EdenSpacing.space2),
        Text(
          'We sent a password reset link to ${_emailController.text.trim()}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark ? EdenColors.neutral[400] : EdenColors.neutral[500],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: EdenSpacing.space6),

        // Back to login
        if (widget.onBackToLoginTap != null)
          EdenButton(
            label: 'Back to sign in',
            onPressed: widget.onBackToLoginTap,
            variant: EdenButtonVariant.secondary,
            fullWidth: true,
            size: EdenButtonSize.lg,
          ),
      ],
    );
  }

  Widget _buildForm(ThemeData theme, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Logo
        if (widget.logo != null) ...[
          Center(child: widget.logo!),
          const SizedBox(height: EdenSpacing.space6),
        ],

        // Title & subtitle
        Text(
          widget.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: EdenSpacing.space2),
        Text(
          widget.subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark ? EdenColors.neutral[400] : EdenColors.neutral[500],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: EdenSpacing.space6),

        // Error alert
        if (_error != null) ...[
          EdenAlert(
            message: _error!,
            variant: EdenAlertVariant.danger,
          ),
          const SizedBox(height: EdenSpacing.space4),
        ],

        // Email input.
        //
        // `email` also resolves `textInputAction: next`, where this field
        // previously passed none at all. On this one-field form Enter therefore
        // additionally advances focus -- but it still SUBMITS: `onSubmitted`
        // fires for every action in `EditableText._finalizeEditing`, not only
        // for `done`. Covered by a test rather than assumed.
        EdenInput(
          controller: _emailController,
          label: 'Email',
          hint: 'you@example.com',
          purpose: EdenFieldPurpose.email,
          prefixIcon: Icons.mail_outline,
          enabled: !_loading,
          onSubmitted: (_) => _handleSendResetLink(),
        ),
        const SizedBox(height: EdenSpacing.space5),

        // Submit button
        EdenButton(
          label: 'Send reset link',
          onPressed: _handleSendResetLink,
          loading: _loading,
          fullWidth: true,
          size: EdenButtonSize.lg,
        ),

        // Back to login link
        if (widget.onBackToLoginTap != null) ...[
          const SizedBox(height: EdenSpacing.space5),
          Center(
            child: TextButton.icon(
              onPressed: _loading ? null : widget.onBackToLoginTap,
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back to sign in'),
              style: TextButton.styleFrom(
                foregroundColor: isDark
                    ? EdenColors.neutral[400]
                    : EdenColors.neutral[600],
                textStyle: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
