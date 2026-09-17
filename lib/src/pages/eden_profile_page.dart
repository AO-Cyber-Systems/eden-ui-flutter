import 'package:flutter/material.dart';
import '../tokens/spacing.dart';
import '../widgets/eden_autofill_scope.dart';
import '../widgets/eden_avatar.dart';
import '../widgets/eden_badge.dart';
import '../widgets/eden_button.dart';
import '../widgets/eden_field_purpose.dart';
import '../widgets/eden_input.dart';
import '../widgets/eden_settings_section.dart';
import '../widgets/eden_selectable_region.dart';

/// A user profile page with personal info editing, password change, and account
/// danger zone sections.
///
/// ## Autofill
///
/// Before this page carried [EdenFieldPurpose]s, NONE of its six fields had a
/// single autofill hint. That mattered most for the three password inputs: the
/// web DOM `type` is derived from the HINT string, never from `obscureText`
/// (`text_editing.dart:514-531`), so an obscured field with no hint rendered as
/// `type="text"` -- the secret sitting in the DOM as plain text, and the field
/// invisible to a password manager. Each now resolves a password-family hint.
///
/// Only the CHANGE-PASSWORD section is wrapped in an [EdenAutofillScope], and
/// the commit happens after [onChangePassword] resolves without throwing. The
/// personal-information fields are deliberately left outside it:
/// `TextInput.finishAutofillContext` ends the whole autofill context rather
/// than one group, so putting them in would let a name or phone edit raise a
/// credential save prompt. Their hints still work -- filling is per element and
/// needs no group.
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
  // Reached by key, not by `EdenAutofillScope.of(context)`: the scope is built
  // as a DESCENDANT of this State, and `of` walks ANCESTORS, so it would never
  // find it from a handler running on this State's context.
  final GlobalKey<EdenAutofillScopeState> _autofillScopeKey =
      GlobalKey<EdenAutofillScopeState>();

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
      final phone = _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim();
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
      // The SAVE half of autofill, and the ONLY thing that makes the new
      // password storable: on web `saveForms()` clicks the hidden form's
      // submit button (`text_editing.dart:2245`) and that click is what
      // raises "Update password?".
      //
      // ORDER IS LOAD-BEARING -- this must run BEFORE the clears below. The
      // browser reads the live DOM input values at the moment of that click,
      // so clearing the controllers first would offer to save three EMPTY
      // fields. It also runs only after the await returned normally: a throw
      // means the backend rejected the change, and saving then would store a
      // password the account does not have.
      _autofillScopeKey.currentState?.commit();
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

    return EdenSelectableRegion(child: SingleChildScrollView(
      padding: const EdgeInsets.all(EdenSpacing.space6),
      child: Center(
        child: ConstrainedBox(
          // width: 600 — profile content clamp
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
    ));
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
          style:
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
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
          // Had NO autofill hints and no keyboardType, so `TextField` resolved
          // `TextInputType.text` in its own initializer list
          // (`text_field.dart:355`). `AutofillHints.name` "requires
          // TextInputType.name" (`editable_text.dart:1855-1858`); the purpose
          // now sets both halves together.
          EdenInput(
            controller: _nameController,
            label: 'Display name',
            hint: 'Your display name',
            purpose: EdenFieldPurpose.personName,
            prefixIcon: Icons.person_outline,
          ),
          const SizedBox(height: EdenSpacing.space4),
          EdenInput(
            controller: _emailController,
            label: 'Email',
            hint: 'your@email.com',
            purpose: EdenFieldPurpose.email,
            prefixIcon: Icons.email_outlined,
          ),
          const SizedBox(height: EdenSpacing.space4),
          EdenInput(
            controller: _phoneController,
            label: 'Phone',
            hint: 'Optional',
            purpose: EdenFieldPurpose.telephoneNumber,
            prefixIcon: Icons.phone_outlined,
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
      // The ONLY autofill scope on this page. See the class dartdoc for why the
      // personal-information fields are deliberately outside it.
      child: EdenAutofillScope(
        key: _autofillScopeKey,
        child: Column(
          children: [
            // All three were obscured with NO autofill hint, which on web is
            // DOM `type="text"` (`text_editing.dart:514-531`) -- the secret in
            // plaintext in the DOM and unreachable by a password manager. The
            // `hint:` values are new too: `hintText` becomes the DOM
            // `placeholder` (`text_editing.dart:471`), which password-manager
            // heuristics read.
            //
            // `currentPassword` also resolves `textInputAction: done`, which is
            // tuned for a sign-in form where the password is last. Here it sits
            // first of three, so Enter closes the keyboard instead of
            // advancing. Accepted rather than overridden: the alternative is
            // `EdenFieldPurpose.none`, which would give this field back its
            // missing hint problem -- by far the more serious defect. Nothing
            // on this page relies on the Enter key (no field sets
            // `onSubmitted`).
            EdenInput(
              controller: _currentPasswordController,
              label: 'Current password',
              hint: 'Enter your current password',
              purpose: EdenFieldPurpose.currentPassword,
              prefixIcon: Icons.lock_outline,
            ),
            const SizedBox(height: EdenSpacing.space4),
            // DUPLICATE DOM ID, ON PURPOSE -- do not "fix" this pair.
            //
            // The web engine sets BOTH `element.name` and `element.id` to the
            // hint string (`text_editing.dart:514-531`), so this field and the
            // confirmation below it -- both resolving
            // `AutofillHints.newPassword` -- emit the SAME DOM id inside this
            // autofill group.
            //
            // That is accepted, not overlooked. Two
            // `autocomplete="new-password"` inputs is the standard HTML
            // change-password shape; browsers and 1Password handle it, and
            // duplicate ids are tolerated by HTML parsing. Both alternatives
            // are worse: dropping the hint on the confirm field makes it DOM
            // `type="text"`, and inventing a distinct hint string emits an
            // invalid `autocomplete` token. Full rationale, and the reason the
            // two stay SEPARATE enum members, is on
            // [EdenFieldPurpose.newPasswordConfirm].
            EdenInput(
              controller: _newPasswordController,
              label: 'New password',
              hint: 'Choose a new password',
              purpose: EdenFieldPurpose.newPassword,
              prefixIcon: Icons.lock_outline,
            ),
            const SizedBox(height: EdenSpacing.space4),
            // Second half of the deliberate duplicate-id pair documented above.
            // Distinct MEMBER, same resolved hint -- see
            // [EdenFieldPurpose.newPasswordConfirm].
            EdenInput(
              controller: _confirmPasswordController,
              label: 'Confirm new password',
              hint: 'Re-enter your new password',
              purpose: EdenFieldPurpose.newPasswordConfirm,
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
