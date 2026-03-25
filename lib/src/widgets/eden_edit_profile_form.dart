import 'package:flutter/material.dart';
import '../tokens/spacing.dart';
import '../tokens/radii.dart';

/// An edit profile form with name, email, phone fields and avatar placeholder.
///
/// Mirrors the eden edit profile form pattern.
class EdenEditProfileForm extends StatefulWidget {
  const EdenEditProfileForm({
    super.key,
    required this.onSubmit,
    this.loading = false,
    this.errorMessage,
    this.initialName,
    this.initialEmail,
    this.initialPhone,
    this.avatarWidget,
    this.onAvatarTap,
    this.nameLabel = 'Full Name',
    this.emailLabel = 'Email',
    this.phoneLabel = 'Phone Number',
    this.submitLabel = 'Save Changes',
  });

  /// Called when the form is submitted with valid data.
  final void Function(String name, String email, String phone) onSubmit;

  final bool loading;
  final String? errorMessage;
  final String? initialName;
  final String? initialEmail;
  final String? initialPhone;

  /// Widget to display as the avatar. If null, a default placeholder is shown.
  final Widget? avatarWidget;

  /// Called when the avatar area is tapped.
  final VoidCallback? onAvatarTap;

  final String nameLabel;
  final String emailLabel;
  final String phoneLabel;
  final String submitLabel;

  @override
  State<EdenEditProfileForm> createState() => _EdenEditProfileFormState();
}

class _EdenEditProfileFormState extends State<EdenEditProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
    _phoneController = TextEditingController(text: widget.initialPhone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onSubmit(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _phoneController.text.trim(),
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
          // Avatar area
          Center(
            child: GestureDetector(
              onTap: widget.onAvatarTap,
              child: widget.avatarWidget ??
                  CircleAvatar(
                    radius: 40,
                    backgroundColor:
                        theme.colorScheme.primary.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: theme.colorScheme.primary,
                    ),
                  ),
            ),
          ),
          if (widget.onAvatarTap != null) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Tap to change photo',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
          const SizedBox(height: EdenSpacing.space5),
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
          Text(widget.phoneLabel, style: theme.textTheme.labelMedium),
          const SizedBox(height: 6),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.telephoneNumber],
            onFieldSubmitted: (_) => _handleSubmit(),
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
