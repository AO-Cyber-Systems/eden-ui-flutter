import 'package:flutter/material.dart';
import '../tokens/spacing.dart';
import '../widgets/eden_avatar.dart';
import '../widgets/eden_badge.dart';
import '../widgets/eden_button.dart';
import '../widgets/eden_input.dart';
import '../widgets/eden_settings_section.dart';

/// A user profile page with personal info editing, password change, and account
/// danger zone sections.
class EdenProfilePage extends StatefulWidget {
  const EdenProfilePage({
    super.key,
    required this.name,
    required this.email,
    this.phone,
    this.role,
    this.avatarUrl,
    this.avatarInitials,
    this.onUpdateProfile,
    this.onChangePassword,
    this.onDeleteAccount,
    this.onSignOut,
    this.onAvatarTap,
  });

  final String name;
  final String email;
  final String? phone;
  final String? role;
  final String? avatarUrl;
  final String? avatarInitials;
  final Future<void> Function(String name, String email, String? phone)?
      onUpdateProfile;
  final Future<void> Function(String currentPassword, String newPassword)?
      onChangePassword;
  final VoidCallback? onDeleteAccount;
  final VoidCallback? onSignOut;
  final VoidCallback? onAvatarTap;

  @override
  State<EdenProfilePage> createState() => _EdenProfilePageState();
}

class _EdenProfilePageState extends State<EdenProfilePage> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _currentPasswordController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;

  bool _profileSaving = false;
  bool _passwordSaving = false;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _emailController = TextEditingController(text: widget.email);
    _phoneController = TextEditingController(text: widget.phone ?? '');
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void didUpdateWidget(covariant EdenProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name) _nameController.text = widget.name;
    if (oldWidget.email != widget.email) _emailController.text = widget.email;
    if (oldWidget.phone != widget.phone) {
      _phoneController.text = widget.phone ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdateProfile() async {
    if (widget.onUpdateProfile == null) return;
    setState(() => _profileSaving = true);
    try {
      final phone =
          _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim();
      await widget.onUpdateProfile!(
        _nameController.text.trim(),
        _emailController.text.trim(),
        phone,
      );
    } finally {
      if (mounted) setState(() => _profileSaving = false);
    }
  }

  Future<void> _handleChangePassword() async {
    if (widget.onChangePassword == null) return;

    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword != confirmPassword) {
      setState(() => _passwordError = 'Passwords do not match');
      return;
    }
    if (newPassword.isEmpty) {
      setState(() => _passwordError = 'New password is required');
      return;
    }

    setState(() {
      _passwordError = null;
      _passwordSaving = true;
    });

    try {
      await widget.onChangePassword!(
        _currentPasswordController.text,
        newPassword,
      );
      if (mounted) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }
    } finally {
      if (mounted) setState(() => _passwordSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(EdenSpacing.space6),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- Avatar + identity header ---
              _buildHeader(theme),
              const SizedBox(height: EdenSpacing.space8),

              // --- Personal information ---
              _buildPersonalInfoSection(),
              const SizedBox(height: EdenSpacing.space6),

              // --- Change password ---
              _buildChangePasswordSection(),
              const SizedBox(height: EdenSpacing.space6),

              // --- Danger zone ---
              _buildDangerZoneSection(),
              const SizedBox(height: EdenSpacing.space8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Semantics(
          button: true,
          label: 'Change profile photo',
          child: GestureDetector(
            onTap: widget.onAvatarTap,
            child: Stack(
            children: [
              EdenAvatar(
                size: EdenAvatarSize.xl,
                image: widget.avatarUrl != null
                    ? NetworkImage(widget.avatarUrl!)
                    : null,
                initials: widget.avatarInitials,
              ),
              if (widget.onAvatarTap != null)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 14,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        ),
        const SizedBox(height: EdenSpacing.space3),
        Text(
          widget.name,
          style: theme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: EdenSpacing.space1),
        Text(
          widget.email,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (widget.role != null) ...[
          const SizedBox(height: EdenSpacing.space2),
          EdenBadge(
            label: widget.role!,
            variant: EdenBadgeVariant.primary,
            size: EdenBadgeSize.sm,
          ),
        ],
      ],
    );
  }

  Widget _buildPersonalInfoSection() {
    return EdenSettingsSection(
      title: 'Personal Information',
      description: 'Update your personal details.',
      child: Column(
        children: [
          EdenInput(
            controller: _nameController,
            label: 'Display name',
            hint: 'Your display name',
            prefixIcon: Icons.person_outline,
          ),
          const SizedBox(height: EdenSpacing.space4),
          EdenInput(
            controller: _emailController,
            label: 'Email',
            hint: 'your@email.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: EdenSpacing.space4),
          EdenInput(
            controller: _phoneController,
            label: 'Phone',
            hint: 'Optional',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: EdenSpacing.space4),
          Align(
            alignment: Alignment.centerRight,
            child: EdenButton(
              label: 'Save Changes',
              onPressed: _profileSaving ? null : _handleUpdateProfile,
              loading: _profileSaving,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangePasswordSection() {
    return EdenSettingsSection(
      title: 'Change Password',
      description: 'Ensure your account stays secure.',
      child: Column(
        children: [
          EdenInput(
            controller: _currentPasswordController,
            label: 'Current password',
            obscureText: true,
            prefixIcon: Icons.lock_outline,
          ),
          const SizedBox(height: EdenSpacing.space4),
          EdenInput(
            controller: _newPasswordController,
            label: 'New password',
            obscureText: true,
            prefixIcon: Icons.lock_outline,
          ),
          const SizedBox(height: EdenSpacing.space4),
          EdenInput(
            controller: _confirmPasswordController,
            label: 'Confirm new password',
            obscureText: true,
            prefixIcon: Icons.lock_outline,
            errorText: _passwordError,
          ),
          const SizedBox(height: EdenSpacing.space4),
          Align(
            alignment: Alignment.centerRight,
            child: EdenButton(
              label: 'Update Password',
              onPressed: _passwordSaving ? null : _handleChangePassword,
              loading: _passwordSaving,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZoneSection() {
    return EdenSettingsSection(
      title: 'Danger Zone',
      description: 'Irreversible and destructive actions.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EdenButton(
            label: 'Delete Account',
            variant: EdenButtonVariant.danger,
            outline: true,
            icon: Icons.delete_outline_rounded,
            onPressed: widget.onDeleteAccount,
          ),
          const SizedBox(height: EdenSpacing.space3),
          EdenButton(
            label: 'Sign Out',
            variant: EdenButtonVariant.ghost,
            icon: Icons.logout_rounded,
            onPressed: widget.onSignOut,
          ),
        ],
      ),
    );
  }
}
