import 'package:flutter/material.dart';
import '../tokens/spacing.dart';
import '../tokens/radii.dart';

/// A forgot password form with email input and submit button.
///
/// Mirrors the eden forgot password flow pattern.
class EdenForgotPasswordForm extends StatefulWidget {
  const EdenForgotPasswordForm({
    super.key,
    required this.onSubmit,
    this.loading = false,
    this.errorMessage,
    this.successMessage,
    this.emailLabel = 'Email Address',
    this.submitLabel = 'Send Reset Link',
    this.description =
        'Enter your email address and we\'ll send you a link to reset your password.',
    this.onBackToSignIn,
    this.backToSignInLabel = 'Back to sign in',
  });

  /// Called when the form is submitted with a valid email.
  final void Function(String email) onSubmit;

  final bool loading;
  final String? errorMessage;
  final String? successMessage;
  final String emailLabel;
  final String submitLabel;
  final String description;
  final VoidCallback? onBackToSignIn;
  final String backToSignInLabel;

  @override
  State<EdenForgotPasswordForm> createState() =>
      _EdenForgotPasswordFormState();
}

class _EdenForgotPasswordFormState extends State<EdenForgotPasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onSubmit(_emailController.text.trim());
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
          if (widget.successMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(EdenSpacing.space3),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: EdenRadii.borderRadiusMd,
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 18,
                      color: theme.colorScheme.onPrimaryContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.successMessage!,
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
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
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleSubmit(),
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
          if (widget.onBackToSignIn != null) ...[
            const SizedBox(height: EdenSpacing.space4),
            Center(
              child: GestureDetector(
                onTap: widget.onBackToSignIn,
                child: Text(
                  widget.backToSignInLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
