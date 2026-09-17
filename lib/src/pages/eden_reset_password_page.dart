import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../widgets/eden_autofill_scope.dart';
import '../widgets/eden_button.dart';
import '../widgets/eden_field_purpose.dart';
import '../widgets/eden_input.dart';
import '../widgets/eden_alert.dart';
import '../widgets/eden_selectable_region.dart';

/// A reset-password page for setting a new password.
///
/// After successful reset, the form is replaced with a success message and a
/// button to navigate back to the login page.
///
/// ## Autofill
///
/// Both fields carry a password-family [EdenFieldPurpose], so web renders them
/// as DOM `type="password"` (`text_editing.dart:514-531`) and a password
/// manager can offer to generate and then store the new secret.
///
/// The page owns the SAVE half: it wraps the fields in an [EdenAutofillScope]
/// and commits ONLY once [onResetPassword] has resolved without throwing --
/// the same moment it flips to its success state. A commit on the failure path
/// would store a password the backend rejected.
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
  // Reached by key, not by `EdenAutofillScope.of(context)`: the scope is built
  // as a DESCENDANT of this State, and `of` walks ANCESTORS, so it would never
  // find it from a handler running on this State's context.
  final GlobalKey<EdenAutofillScopeState> _autofillScopeKey =
      GlobalKey<EdenAutofillScopeState>();

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
      // The SAVE half of autofill. Hints alone only make these fields
      // FILLABLE; the new password is never offered for SAVING without
      // `TextInput.finishAutofillContext` -- on web `saveForms()` clicks the
      // hidden form's submit button (`text_editing.dart:2245`).
      //
      // Committed here, on the one path this page calls success, and NOT in
      // the catch below: storing a password the backend rejected is exactly
      // the failure mode this ordering exists to avoid.
      //
      // Before the `mounted` guard on purpose -- `commit()` is a platform
      // call that does not touch this element, and the scope's State is
      // still alive at this point even if the page is about to go away.
      _autofillScopeKey.currentState?.commit();
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
        EdenAutofillScope(
          key: _autofillScopeKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // DUPLICATE DOM ID, ON PURPOSE -- do not "fix" this pair.
              //
              // The web engine sets BOTH `element.name` and `element.id` to the
              // hint string (`text_editing.dart:514-531`), so this field and the
              // confirmation below it -- both resolving
              // `AutofillHints.newPassword` -- emit the SAME DOM id inside one
              // autofill group.
              //
              // That is accepted, not overlooked. Two `autocomplete="new-password"`
              // inputs is the standard HTML password-reset shape; browsers and
              // 1Password handle it, and duplicate ids are tolerated by HTML
              // parsing. Both alternatives are worse: dropping the hint on the
              // confirm field makes it DOM `type="text"` (the password in
              // plaintext in the DOM, and invisible to 1Password), and inventing
              // a distinct hint string emits an invalid `autocomplete` token. The
              // rationale in full, plus the reason the two stay SEPARATE enum
              // members, is on [EdenFieldPurpose.newPasswordConfirm].
              EdenInput(
                controller: _passwordController,
                label: 'New password',
                hint: 'Enter your new password',
                purpose: EdenFieldPurpose.newPassword,
                prefixIcon: Icons.lock_outline,
                enabled: !_loading,
              ),
              const SizedBox(height: EdenSpacing.space4),
              // Second half of the deliberate duplicate-id pair documented
              // above. Distinct MEMBER, same resolved hint -- see
              // [EdenFieldPurpose.newPasswordConfirm].
              EdenInput(
                controller: _confirmPasswordController,
                label: 'Confirm password',
                hint: 'Re-enter your new password',
                purpose: EdenFieldPurpose.newPasswordConfirm,
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
