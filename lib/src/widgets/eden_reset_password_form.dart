import 'package:flutter/material.dart';
import '../tokens/spacing.dart';
import '../tokens/radii.dart';

/// A reset password form with new password + confirm password fields.
///
/// Mirrors the eden reset password flow pattern.
class EdenResetPasswordForm extends StatefulWidget {
  const EdenResetPasswordForm({
    super.key,
    required this.onSubmit,
    this.loading = false,
    this.errorMessage,
    this.passwordLabel = 'New Password',
    this.confirmPasswordLabel = 'Confirm Password',
    this.submitLabel = 'Reset Password',
    this.description = 'Enter your new password below.',
    this.minPasswordLength = 8,
  });

  /// Called when the form is submitted with a valid password.
  final void Function(String password) onSubmit;

  final bool loading;
  final String? errorMessage;
  final String passwordLabel;
  final String confirmPasswordLabel;
  final String submitLabel;
  final String description;
  final int minPasswordLength;

  @override
  State<EdenResetPasswordForm> createState() => _EdenResetPasswordFormState();
}

class _EdenResetPasswordFormState extends State<EdenResetPasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onSubmit(_passwordController.text);
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
          Text(
            widget.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: EdenSpacing.space5),
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
          Text(widget.passwordLabel, style: theme.textTheme.labelMedium),
          const SizedBox(height: 6),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              if (value.length < widget.minPasswordLength) {
                return 'Password must be at least ${widget.minPasswordLength} characters';
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
          const SizedBox(height: EdenSpacing.space4),
          Text(widget.confirmPasswordLabel, style: theme.textTheme.labelMedium),
          const SizedBox(height: 6),
          TextFormField(
            controller: _confirmController,
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleSubmit(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
            decoration: InputDecoration(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
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
