import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../widgets/eden_button.dart';
import '../widgets/eden_input.dart';
import '../widgets/eden_oauth_buttons.dart';
import '../widgets/eden_divider.dart';
import '../widgets/eden_alert.dart';

/// A complete sign-up page with name, email, password, confirm password,
/// optional terms acceptance, and OAuth providers.
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
      body: Center(
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
      ),
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
        AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EdenInput(
                controller: _nameController,
                label: 'Display name',
                hint: 'Your name',
                autofillHints: const [AutofillHints.name],
                prefixIcon: Icons.person_outline,
                enabled: !_loading,
              ),
              const SizedBox(height: EdenSpacing.space4),
              EdenInput(
                controller: _emailController,
                label: 'Email',
                hint: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                prefixIcon: Icons.mail_outline,
                enabled: !_loading,
              ),
              const SizedBox(height: EdenSpacing.space4),
              EdenInput(
                controller: _passwordController,
                label: 'Password',
                hint: 'Create a password',
                obscureText: true,
                autofillHints: const [AutofillHints.newPassword],
                prefixIcon: Icons.lock_outline,
                enabled: !_loading,
              ),
              const SizedBox(height: EdenSpacing.space4),
              EdenInput(
                controller: _confirmPasswordController,
                label: 'Confirm password',
                hint: 'Re-enter your password',
                obscureText: true,
                autofillHints: const [AutofillHints.newPassword],
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
