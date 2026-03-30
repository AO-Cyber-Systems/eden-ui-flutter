import 'package:flutter/material.dart';
import '../tokens/spacing.dart';
import '../widgets/eden_button.dart';
import '../widgets/eden_settings_section.dart';
import '../widgets/eden_theme_selector.dart';
import '../widgets/eden_toggle.dart';

/// A settings page with appearance, notification, and account sections.
///
/// Each section can be shown or hidden via `show*` flags. Additional custom
/// sections can be inserted via [additionalSections].
class EdenSettingsPage extends StatelessWidget {
  const EdenSettingsPage({
    super.key,
    this.themeMode = ThemeMode.system,
    this.onThemeModeChanged,
    this.pushNotificationsEnabled = false,
    this.emailNotificationsEnabled = false,
    this.onPushNotificationsChanged,
    this.onEmailNotificationsChanged,
    this.userName,
    this.userEmail,
    this.userRole,
    this.onSignOut,
    this.showAppearance = true,
    this.showNotifications = true,
    this.showAccount = true,
    this.additionalSections,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode>? onThemeModeChanged;
  final bool pushNotificationsEnabled;
  final bool emailNotificationsEnabled;
  final ValueChanged<bool>? onPushNotificationsChanged;
  final ValueChanged<bool>? onEmailNotificationsChanged;
  final String? userName;
  final String? userEmail;
  final String? userRole;
  final VoidCallback? onSignOut;
  final bool showAppearance;
  final bool showNotifications;
  final bool showAccount;
  final List<Widget>? additionalSections;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(EdenSpacing.space6),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: EdenSpacing.space6),

              if (showAppearance) ...[
                _buildAppearanceSection(),
                const SizedBox(height: EdenSpacing.space6),
              ],

              if (showNotifications) ...[
                _buildNotificationsSection(),
                const SizedBox(height: EdenSpacing.space6),
              ],

              if (additionalSections != null)
                for (final section in additionalSections!) ...[
                  section,
                  const SizedBox(height: EdenSpacing.space6),
                ],

              if (showAccount) ...[
                _buildAccountSection(theme),
                const SizedBox(height: EdenSpacing.space8),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppearanceSection() {
    return EdenSettingsSection(
      title: 'Appearance',
      description: 'Customize how the app looks.',
      child: Row(
        children: [
          Expanded(
            child: EdenThemeSelector(
              value: themeMode,
              onChanged: onThemeModeChanged ?? (_) {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return EdenSettingsSection(
      title: 'Notifications',
      description: 'Manage how you receive notifications.',
      child: Column(
        children: [
          _ToggleRow(
            label: 'Push notifications',
            description: 'Receive push notifications on your device.',
            value: pushNotificationsEnabled,
            onChanged: onPushNotificationsChanged,
          ),
          const SizedBox(height: EdenSpacing.space4),
          _ToggleRow(
            label: 'Email notifications',
            description: 'Receive important updates via email.',
            value: emailNotificationsEnabled,
            onChanged: onEmailNotificationsChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection(ThemeData theme) {
    return EdenSettingsSection(
      title: 'Account',
      description: 'Your account information.',
      child: Column(
        children: [
          if (userName != null)
            _InfoRow(
              icon: Icons.person_outline,
              label: 'Name',
              value: userName!,
              theme: theme,
            ),
          if (userEmail != null) ...[
            if (userName != null) const SizedBox(height: EdenSpacing.space3),
            _InfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: userEmail!,
              theme: theme,
            ),
          ],
          if (userRole != null) ...[
            const SizedBox(height: EdenSpacing.space3),
            _InfoRow(
              icon: Icons.shield_outlined,
              label: 'Role',
              value: userRole!,
              theme: theme,
            ),
          ],
          const SizedBox(height: EdenSpacing.space4),
          Align(
            alignment: Alignment.centerLeft,
            child: EdenButton(
              label: 'Sign Out',
              variant: EdenButtonVariant.danger,
              outline: true,
              icon: Icons.logout_rounded,
              onPressed: onSignOut,
            ),
          ),
        ],
      ),
    );
  }
}

/// A row with a toggle switch, label, and description.
class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.description,
    required this.value,
    this.onChanged,
  });

  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              )),
              const SizedBox(height: 2),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: EdenSpacing.space3),
        EdenToggle(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// A read-only info row showing an icon, label, and value.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: EdenSpacing.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(value, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
