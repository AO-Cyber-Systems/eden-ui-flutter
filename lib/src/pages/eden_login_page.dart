import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../widgets/eden_button.dart';
import '../widgets/eden_input.dart';
import '../widgets/eden_oauth_buttons.dart';
import '../widgets/eden_divider.dart';
import '../widgets/eden_alert.dart';

/// Configuration for dev login bypass.
class EdenDevLoginConfig {
  const EdenDevLoginConfig({
    this.email = 'dev@eden.local',
    this.password = 'dev',
    this.label = 'Dev Login',
    this.enabled,
  });

  final String email;
  final String password;
  final String label;

  /// If null, defaults to [kDebugMode].
  final bool? enabled;

  bool get isEnabled => enabled ?? kDebugMode;
}

/// A complete login page with email/password, OAuth, and dev bypass.
///
/// Renders a centered card with configurable logo, title, subtitle, email and
/// password inputs, OAuth buttons, and navigation links. In debug mode (or when
/// explicitly enabled via [devLoginConfig]), a development banner is shown at
/// the top of the page for one-tap dev login.
class EdenLoginPage extends StatefulWidget {
  const EdenLoginPage({
    super.key,
    required this.onLogin,
    this.onSignUpTap,
    this.onForgotPasswordTap,
    this.oauthProviders,
    this.onOAuthTap,
    this.devLoginConfig,
    this.logo,
    this.title = 'Welcome back',
    this.subtitle = 'Sign in to your account',
    this.loadingOAuthProvider,
  });

  /// Called when the user taps the sign-in button or submits the form.
  final Future<void> Function(String email, String password) onLogin;

  /// Navigate to sign-up page.
  final VoidCallback? onSignUpTap;

  /// Navigate to forgot-password page.
  final VoidCallback? onForgotPasswordTap;

  /// OAuth providers to display. When null or empty, the OAuth section is hidden.
  final List<EdenOAuthProvider>? oauthProviders;

  /// Called when an OAuth provider button is tapped.
  final ValueChanged<EdenOAuthProvider>? onOAuthTap;

  /// Dev-login bypass configuration. Shows a banner when [EdenDevLoginConfig.isEnabled].
  final EdenDevLoginConfig? devLoginConfig;

  /// Optional logo widget rendered at the top of the card.
  final Widget? logo;

  /// Page title displayed below the logo.
  final String title;

  /// Page subtitle displayed below the title.
  final String subtitle;

  /// The OAuth provider currently in a loading state.
  final EdenOAuthProvider? loadingOAuthProvider;

  @override
  State<EdenLoginPage> createState() => _EdenLoginPageState();
}

class _EdenLoginPageState extends State<EdenLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter your email and password.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await widget.onLogin(email, password);
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

  Future<void> _handleDevLogin() async {
    final config = widget.devLoginConfig;
    if (config == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await widget.onLogin(config.email, config.password);
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

  bool get _showDevBanner =>
      widget.devLoginConfig != null && widget.devLoginConfig!.isEnabled;

  bool get _hasOAuth =>
      widget.oauthProviders != null && widget.oauthProviders!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          if (_showDevBanner) _buildDevBanner(theme, isDark),
          Expanded(
            child: Center(
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
          ),
        ],
      ),
    );
  }

  Widget _buildDevBanner(ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space4,
        vertical: EdenSpacing.space2,
      ),
      color: EdenColors.warning.withValues(alpha: isDark ? 0.2 : 0.15),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Icon(
              Icons.construction,
              size: 18,
              color: isDark ? EdenColors.warning : EdenColors.warning,
            ),
            const SizedBox(width: EdenSpacing.space2),
            Text(
              'Development Mode',
              style: theme.textTheme.labelMedium?.copyWith(
                color: isDark
                    ? EdenColors.neutral[100]
                    : EdenColors.neutral[900],
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: _loading ? null : _handleDevLogin,
              style: TextButton.styleFrom(
                foregroundColor: isDark
                    ? EdenColors.warning
                    : EdenColors.neutral[900],
                padding: const EdgeInsets.symmetric(
                  horizontal: EdenSpacing.space3,
                  vertical: EdenSpacing.space1,
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text(widget.devLoginConfig!.label),
            ),
          ],
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
                hint: 'Enter your password',
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                prefixIcon: Icons.lock_outline,
                enabled: !_loading,
                onSubmitted: (_) => _handleLogin(),
              ),
            ],
          ),
        ),

        // Forgot password
        if (widget.onForgotPasswordTap != null) ...[
          const SizedBox(height: EdenSpacing.space2),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _loading ? null : widget.onForgotPasswordTap,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: EdenSpacing.space2,
                  vertical: EdenSpacing.space1,
                ),
                textStyle: const TextStyle(fontSize: 13),
                foregroundColor: theme.colorScheme.primary,
              ),
              child: const Text('Forgot password?'),
            ),
          ),
        ],
        const SizedBox(height: EdenSpacing.space4),

        // Sign in button
        EdenButton(
          label: 'Sign in',
          onPressed: _handleLogin,
          loading: _loading,
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

        // Sign up link
        if (widget.onSignUpTap != null) ...[
          const SizedBox(height: EdenSpacing.space6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Don't have an account? ",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? EdenColors.neutral[400]
                      : EdenColors.neutral[500],
                ),
              ),
              Semantics(
                button: true,
                label: 'Sign up',
                child: GestureDetector(
                  onTap: _loading ? null : widget.onSignUpTap,
                  child: Text(
                    'Sign up',
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
