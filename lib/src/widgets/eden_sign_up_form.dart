import 'package:flutter/material.dart';
import '../tokens/spacing.dart';
import '../tokens/radii.dart';

/// A sign-up form with name, email, password, confirm password, and terms checkbox.
///
/// Mirrors the eden_sign_up_form Rails component pattern.
class EdenSignUpForm extends StatefulWidget {
  const EdenSignUpForm({
    super.key,
    required this.onSubmit,
    this.loading = false,
    this.errorMessage,
    this.nameLabel = 'Full Name',
    this.emailLabel = 'Email',
    this.passwordLabel = 'Password',
    this.confirmPasswordLabel = 'Confirm Password',
    this.submitLabel = 'Create Account',
    this.termsLabel = 'I agree to the Terms of Service and Privacy Policy',
    this.onTermsTap,
    this.minPasswordLength = 8,
  });

  /// Called when the form is submitted with valid data.
  final void Function(String name, String email, String password) onSubmit;

  final bool loading;
  final String? errorMessage;
  final String nameLabel;
  final String emailLabel;
  final String passwordLabel;
  final String confirmPasswordLabel;
  final String submitLabel;
  final String termsLabel;
  final VoidCallback? onTermsTap;
  final int minPasswordLength;

  @override
  State<EdenSignUpForm> createState() => _EdenSignUpFormState();
}

class _EdenSignUpFormState extends State<EdenSignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _agreedToTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      if (!_agreedToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please agree to the terms')),
        );
        return;
      }
      widget.onSubmit(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
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
          Text(widget.nameLabel, style: theme.textTheme.labelMedium),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: EdenSpacing.space4),
          Text(widget.emailLabel, style: theme.textTheme.labelMedium),
          const SizedBox(height: 6),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
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
            controller: _confirmPasswordController,
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
          const SizedBox(height: EdenSpacing.space4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: _agreedToTerms,
                  onChanged: (v) =>
                      setState(() => _agreedToTerms = v ?? false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: widget.onTermsTap,
                  child: Text(
                    widget.termsLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: widget.onTermsTap != null
                          ? theme.colorScheme.primary
                          : null,
                    ),
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
