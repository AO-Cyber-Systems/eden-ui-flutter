import 'package:flutter/material.dart';
import '../tokens/spacing.dart';
import '../tokens/radii.dart';

/// A sign-in form with email, password, remember me, and forgot password link.
///
/// Mirrors the eden_sign_in_form Rails component pattern.
class EdenSignInForm extends StatefulWidget {
  const EdenSignInForm({
    super.key,
    required this.onSubmit,
    this.onForgotPassword,
    this.loading = false,
    this.errorMessage,
    this.emailLabel = 'Email',
    this.passwordLabel = 'Password',
    this.submitLabel = 'Sign In',
    this.forgotPasswordLabel = 'Forgot password?',
    this.rememberMeLabel = 'Remember me',
  });

  /// Called when the form is submitted with valid data.
  final void Function(String email, String password, bool rememberMe) onSubmit;

  /// Called when the forgot password link is tapped.
  final VoidCallback? onForgotPassword;

  /// Whether the form is in a loading state.
  final bool loading;

  /// An error message to display at the top of the form.
  final String? errorMessage;

  final String emailLabel;
  final String passwordLabel;
  final String submitLabel;
  final String forgotPasswordLabel;
  final String rememberMeLabel;

  @override
  State<EdenSignInForm> createState() => _EdenSignInFormState();
}

class _EdenSignInFormState extends State<EdenSignInForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onSubmit(
        _emailController.text.trim(),
        _passwordController.text,
        _rememberMe,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(EdenSpacing.space3),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: EdenRadii.borderRadiusMd,
              ),
              child: Text(
                widget.errorMessage!,
                style: TextStyle(
                  color: theme.colorScheme.onErrorContainer,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: EdenSpacing.space4),
          ],
          Text(widget.emailLabel, style: theme.textTheme.labelMedium),
          const SizedBox(height: 6),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email is required';
              }
              if (!value.contains('@')) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: EdenSpacing.space4),
          Text(widget.passwordLabel, style: theme.textTheme.labelMedium),
          const SizedBox(height: 6),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleSubmit(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              return null;
            },
            decoration: InputDecoration(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          const SizedBox(height: EdenSpacing.space3),
          Row(
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: _rememberMe,
                  onChanged: (v) => setState(() => _rememberMe = v ?? false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.rememberMeLabel,
                  style: theme.textTheme.bodySmall,
                ),
              ),
              if (widget.onForgotPassword != null)
                GestureDetector(
                  onTap: widget.onForgotPassword,
                  child: Text(
                    widget.forgotPasswordLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: EdenSpacing.space6),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: widget.loading ? null : _handleSubmit,
              child: widget.loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(widget.submitLabel),
            ),
          ),
        ],
      ),
    );
  }
}
