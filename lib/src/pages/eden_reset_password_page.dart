import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../widgets/eden_button.dart';
import '../widgets/eden_input.dart';
import '../widgets/eden_alert.dart';

/// A reset-password page for setting a new password.
///
/// After successful reset, the form is replaced with a success message and a
/// button to navigate back to the login page.
class EdenResetPasswordPage extends StatefulWidget {
  const EdenResetPasswordPage({
    super.key,
    required this.onResetPassword,
    this.onBackToLoginTap,
    this.logo,
    this.title = 'Set new password',
    this.subtitle = 'Enter your new password below',
  });

  /// Called when the user submits a new password.
  final Future<void> Function(String password) onResetPassword;

  /// Navigate back to the login page.
  final VoidCallback? onBackToLoginTap;

  /// Optional logo widget rendered at the top.
  final Widget? logo;

  /// Page title.
  final String title;

  /// Page subtitle.
  final String subtitle;

  @override
  State<EdenResetPasswordPage> createState() => _EdenResetPasswordPageState();
}

class _EdenResetPasswordPageState extends State<EdenResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _success = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password.isEmpty) {
      setState(() => _error = 'Please enter a new password.');
      return;
    }

    if (password != confirmPassword) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await widget.onResetPassword(password);
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
      body: Center(
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
      ),
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
              Icons.check_circle_outline,
              size: 32,
              color: EdenColors.success,
            ),
          ),
        ),
        const SizedBox(height: EdenSpacing.space6),

        // Success message
        Text(
          'Password reset successful',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: EdenSpacing.space2),
        Text(
          'Your password has been updated. You can now sign in with your new password.',
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

        // Password inputs
        AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EdenInput(
                controller: _passwordController,
                label: 'New password',
                hint: 'Enter your new password',
                obscureText: true,
                autofillHints: const [AutofillHints.newPassword],
                prefixIcon: Icons.lock_outline,
                enabled: !_loading,
              ),
              const SizedBox(height: EdenSpacing.space4),
              EdenInput(
                controller: _confirmPasswordController,
                label: 'Confirm password',
                hint: 'Re-enter your new password',
                obscureText: true,
                autofillHints: const [AutofillHints.newPassword],
                prefixIcon: Icons.lock_outline,
                enabled: !_loading,
                onSubmitted: (_) => _handleResetPassword(),
              ),
            ],
          ),
        ),
        const SizedBox(height: EdenSpacing.space5),

        // Submit button
        EdenButton(
          label: 'Reset password',
          onPressed: _handleResetPassword,
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
