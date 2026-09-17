import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../widgets/eden_autofill_scope.dart';
import '../widgets/eden_button.dart';
import '../widgets/eden_field_purpose.dart';
import '../widgets/eden_input.dart';
import '../widgets/eden_oauth_buttons.dart';
import '../widgets/eden_divider.dart';
import '../widgets/eden_alert.dart';
import '../widgets/eden_selectable_region.dart';

/// A complete sign-up page with name, email, password, confirm password,
/// optional terms acceptance, and OAuth providers.
///
/// ## Autofill
///
/// Each field carries an [EdenFieldPurpose], which resolves its autofill hints
/// and keyboard type as one consistent set (`editable_text.dart:1855-1858`).
///
/// The page owns the SAVE half too: it wraps the fields in an
/// [EdenAutofillScope] and commits ONLY after [onSignUp] resolves without
/// throwing, because a throw is what this page treats as a failed sign-up.
/// Committing on the failure path would ask the OS and 1Password to store a
/// credential the server just rejected.
class EdenSignUpPage extends StatefulWidget {
  const EdenSignUpPage({
    super.key,
    required this.onSignUp,
    this.onLoginTap,
    this.oauthProviders,
    this.onOAuthTap,
    this.loadingOAuthProvider,
    this.onTermsTap,
    this.onPrivacyTap,
    this.logo,
    this.title = 'Create an account',
    this.subtitle = 'Get started',
    this.termsRequired = false,
  });

  /// Called when the user submits the sign-up form.
  final Future<void> Function(String name, String email, String password)
      onSignUp;

  /// Navigate to the login page.
  final VoidCallback? onLoginTap;

  /// OAuth providers to display.
  final List<EdenOAuthProvider>? oauthProviders;

  /// Called when an OAuth provider button is tapped.
  final ValueChanged<EdenOAuthProvider>? onOAuthTap;

  /// The OAuth provider currently in a loading state.
  final EdenOAuthProvider? loadingOAuthProvider;

  /// Called when the user taps "Terms of Service".
  final VoidCallback? onTermsTap;

  /// Called when the user taps "Privacy Policy".
  final VoidCallback? onPrivacyTap;

  /// Optional logo widget rendered at the top.
  final Widget? logo;

  /// Page title.
  final String title;

  /// Page subtitle.
  final String subtitle;

  /// When true, the user must accept terms before signing up.
  final bool termsRequired;

  @override
  State<EdenSignUpPage> createState() => _EdenSignUpPageState();
}

class _EdenSignUpPageState extends State<EdenSignUpPage> {
  // Reached by key, not by `EdenAutofillScope.of(context)`: the scope is built
  // as a DESCENDANT of this State, and `of` walks ANCESTORS, so it would never
  // find it from a handler running on this State's context.
  final GlobalKey<EdenAutofillScopeState> _autofillScopeKey =
      GlobalKey<EdenAutofillScopeState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _termsAccepted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }

    if (password != confirmPassword) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    if (widget.termsRequired && !_termsAccepted) {
      setState(
          () => _error = 'You must accept the terms and conditions to continue.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await widget.onSignUp(name, email, password);
      // The SAVE half of autofill. Correct hints only make a field FILLABLE; a
      // credential is never offered for SAVING on any platform without
      // `TextInput.finishAutofillContext` -- on web the engine's `saveForms()`
      // clicks the hidden form's submit button (`text_editing.dart:2245`), and
      // that synthetic click is what raises "Save password?".
      //
      // On the success path deliberately: committing after a REJECTED sign-up
      // makes 1Password offer to save a credential that does not exist.
      _autofillScopeKey.currentState?.commit();
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

  bool get _hasOAuth =>
      widget.oauthProviders != null && widget.oauthProviders!.isNotEmpty;

  bool get _signUpDisabled =>
      _loading || (widget.termsRequired && !_termsAccepted);

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
            child: _buildCard(theme, isDark),
          ),
        ),
      )),
    );
  }

  Widget _buildCard(ThemeData theme, bool isDark) {
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

        // Form
        EdenAutofillScope(
          key: _autofillScopeKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EdenInput(
                controller: _nameController,
                label: 'Display name',
                hint: 'Your name',
                // Was `autofillHints: [AutofillHints.name]` with NO
                // keyboardType, which `TextField` resolved to
                // `TextInputType.text` in its own initializer list
                // (`text_field.dart:355`) before `_inferKeyboardType` could
                // ever run. `AutofillHints.name` "requires TextInputType.name"
                // (`editable_text.dart:1855-1858`), so this field was
                // mis-keyboarded. The purpose fixes both halves at once.
                purpose: EdenFieldPurpose.personName,
                prefixIcon: Icons.person_outline,
                enabled: !_loading,
              ),
              const SizedBox(height: EdenSpacing.space4),
              EdenInput(
                controller: _emailController,
                label: 'Email',
                hint: 'you@example.com',
                purpose: EdenFieldPurpose.email,
                prefixIcon: Icons.mail_outline,
                enabled: !_loading,
              ),
              const SizedBox(height: EdenSpacing.space4),
              // DUPLICATE DOM ID, ON PURPOSE -- do not "fix" this pair.
              //
              // The web engine sets BOTH `element.name` and `element.id` to the
              // hint string (`text_editing.dart:514-531`), so this field and the
              // confirmation below it -- both resolving
              // `AutofillHints.newPassword` -- emit the SAME DOM id inside one
              // autofill group.
              //
              // That is accepted, not overlooked. Two `autocomplete="new-password"`
              // inputs is the standard HTML signup shape; browsers and 1Password
              // handle it, and duplicate ids are tolerated by HTML parsing. Both
              // alternatives are worse: dropping the hint on the confirm field
              // makes it DOM `type="text"` (the password in plaintext in the DOM,
              // and invisible to 1Password), and inventing a distinct hint string
              // emits an invalid `autocomplete` token. The rationale in full,
              // plus the reason the two stay SEPARATE enum members, is on
              // [EdenFieldPurpose.newPasswordConfirm].
              EdenInput(
                controller: _passwordController,
                label: 'Password',
                hint: 'Create a password',
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
                hint: 'Re-enter your password',
                purpose: EdenFieldPurpose.newPasswordConfirm,
                prefixIcon: Icons.lock_outline,
                enabled: !_loading,
                onSubmitted: (_) => _handleSignUp(),
              ),
            ],
          ),
        ),

        // Terms checkbox
        if (widget.termsRequired || widget.onTermsTap != null || widget.onPrivacyTap != null) ...[
          const SizedBox(height: EdenSpacing.space4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _termsAccepted,
                  onChanged: _loading
                      ? null
                      : (value) =>
                          setState(() => _termsAccepted = value ?? false),
                ),
              ),
              const SizedBox(width: EdenSpacing.space2),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Wrap(
                    children: [
                      Text(
                        'I agree to the ',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? EdenColors.neutral[400]
                              : EdenColors.neutral[600],
                        ),
                      ),
                      Semantics(
                        button: true,
                        label: 'Terms of Service',
                        child: GestureDetector(
                          onTap: widget.onTermsTap,
                          child: Text(
                            'Terms of Service',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        ' and ',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? EdenColors.neutral[400]
                              : EdenColors.neutral[600],
                        ),
                      ),
                      Semantics(
                        button: true,
                        label: 'Privacy Policy',
                        child: GestureDetector(
                          onTap: widget.onPrivacyTap,
                          child: Text(
                            'Privacy Policy',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: EdenSpacing.space5),

        // Sign up button
        EdenButton(
          label: 'Sign up',
          onPressed: _signUpDisabled ? null : _handleSignUp,
          loading: _loading,
          disabled: widget.termsRequired && !_termsAccepted,
          fullWidth: true,
          size: EdenButtonSize.lg,
        ),

        // OAuth section
        if (_hasOAuth) ...[
          const EdenDivider(label: 'OR'),
          EdenOAuthButtonRow(
            providers: widget.oauthProviders!,
            onProviderTap: (provider) => widget.onOAuthTap?.call(provider),
            loadingProvider: widget.loadingOAuthProvider,
          ),
        ],

        // Login link
        if (widget.onLoginTap != null) ...[
          const SizedBox(height: EdenSpacing.space6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? EdenColors.neutral[400]
                      : EdenColors.neutral[500],
                ),
              ),
              Semantics(
                button: true,
                label: 'Sign in',
                child: GestureDetector(
                  onTap: _loading ? null : widget.onLoginTap,
                  child: Text(
                    'Sign in',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
