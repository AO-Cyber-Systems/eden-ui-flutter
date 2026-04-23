import 'package:flutter/material.dart';
import '../../eden_ui.dart';
import '../widgets/section.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _marketing = false;
  bool _twoFactor = true;
  String? _language = 'en';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings Pattern')),
      body: ListView(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        children: [
          const EdenPageHeader(
            title: 'Settings',
            description: 'Manage your account preferences.',
          ),

          const EdenSettingsSection(
            title: 'Profile',
            description: 'Your personal information.',
            child: Column(
              children: [
                EdenInput(label: 'Display Name', hint: 'Enter your name'),
                SizedBox(height: 12),
                EdenInput(label: 'Email', hint: 'you@example.com', prefixIcon: Icons.email_outlined),
              ],
            ),
          ),
          const SizedBox(height: EdenSpacing.space4),

          EdenSettingsSection(
            title: 'Notifications',
            description: 'Choose what you get notified about.',
            child: Column(
              children: [
                EdenToggle(
                  value: _notifications,
                  onChanged: (v) => setState(() => _notifications = v),
                  label: 'Push notifications',
                ),
                const SizedBox(height: 8),
                EdenToggle(
                  value: _marketing,
                  onChanged: (v) => setState(() => _marketing = v),
                  label: 'Marketing emails',
                ),
              ],
            ),
          ),
          const SizedBox(height: EdenSpacing.space4),

          EdenSettingsSection(
            title: 'Security',
            description: 'Keep your account secure.',
            action: const EdenBadge(label: 'Recommended', variant: EdenBadgeVariant.success, size: EdenBadgeSize.sm),
            child: Column(
              children: [
                EdenToggle(
                  value: _twoFactor,
                  onChanged: (v) => setState(() => _twoFactor = v),
                  label: 'Two-factor authentication',
                ),
                const SizedBox(height: 12),
                EdenButton(
                  label: 'Change Password',
                  variant: EdenButtonVariant.secondary,
                  icon: Icons.lock_outline,
                  size: EdenButtonSize.sm,
                  onPressed: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: EdenSpacing.space4),

          EdenSettingsSection(
            title: 'Preferences',
            description: 'App behavior and display.',
            child: Column(
              children: [
                EdenSelect<String>(
                  label: 'Language',
                  value: _language,
                  options: const [
                    EdenSelectOption(value: 'en', label: 'English'),
                    EdenSelectOption(value: 'es', label: 'Spanish'),
                    EdenSelectOption(value: 'fr', label: 'French'),
                    EdenSelectOption(value: 'de', label: 'German'),
                  ],
                  onChanged: (v) => setState(() => _language = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: EdenSpacing.space4),

          // Page header with actions demo
          Section(
            title: 'Page Header',
            child: EdenPageHeader(
              title: 'Team Members',
              description: 'Manage your organization\'s team.',
              actions: [
                EdenButton(
                  label: 'Invite',
                  icon: Icons.person_add,
                  size: EdenButtonSize.sm,
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Section header demo
          Section(
            title: 'Section Header',
            child: EdenCard(
              child: Column(
                children: [
                  EdenSectionHeader(
                    title: 'Recent Activity',
                    subtitle: 'Last 7 days',
                    action: EdenButton(
                      label: 'View All',
                      variant: EdenButtonVariant.ghost,
                      size: EdenButtonSize.xs,
                      onPressed: () {},
                    ),
                  ),
                  const EdenDivider(),
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(EdenSpacing.space8),
                      child: Text('Activity content here'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
