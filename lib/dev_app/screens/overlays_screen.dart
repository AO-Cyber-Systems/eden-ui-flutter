import 'package:flutter/material.dart';
import '../../eden_ui.dart';
import '../widgets/section.dart';

class OverlaysScreen extends StatefulWidget {
  const OverlaysScreen({super.key});

  @override
  State<OverlaysScreen> createState() => _OverlaysScreenState();
}

class _OverlaysScreenState extends State<OverlaysScreen> {
  bool _bannerVisible = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Overlays')),
      body: ListView(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        children: [
          // Banners
          Section(
            title: 'Banners',
            child: Column(
              children: [
                if (_bannerVisible)
                  EdenBanner(
                    message: 'Your trial expires in 7 days. Upgrade now!',
                    variant: EdenBannerVariant.warning,
                    actionLabel: 'Upgrade',
                    onAction: () {},
                    onDismiss: () => setState(() => _bannerVisible = false),
                  ),
                if (!_bannerVisible)
                  EdenButton(
                    label: 'Show Banner Again',
                    variant: EdenButtonVariant.secondary,
                    size: EdenButtonSize.sm,
                    onPressed: () => setState(() => _bannerVisible = true),
                  ),
                const SizedBox(height: 8),
                EdenBanner(
                  message: 'System update completed successfully.',
                  variant: EdenBannerVariant.success,
                  dismissible: false,
                ),
                const SizedBox(height: 8),
                EdenBanner(
                  message: 'Service degradation detected.',
                  variant: EdenBannerVariant.danger,
                  dismissible: false,
                ),
                const SizedBox(height: 8),
                EdenBanner(
                  message: 'New features are now available.',
                  variant: EdenBannerVariant.info,
                  dismissible: false,
                ),
              ],
            ),
          ),

          // Modal
          Section(
            title: 'Modal Dialog',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                EdenButton(
                  label: 'Open Modal',
                  onPressed: () {
                    EdenModal.show(
                      context,
                      title: 'Confirm Action',
                      child: Text(
                        'Are you sure you want to proceed? This action cannot be undone.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      actions: [
                        EdenButton(
                          label: 'Cancel',
                          variant: EdenButtonVariant.secondary,
                          size: EdenButtonSize.sm,
                          onPressed: () => Navigator.pop(context),
                        ),
                        EdenButton(
                          label: 'Confirm',
                          variant: EdenButtonVariant.danger,
                          size: EdenButtonSize.sm,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    );
                  },
                ),
                EdenButton(
                  label: 'Large Modal',
                  variant: EdenButtonVariant.secondary,
                  onPressed: () {
                    EdenModal.show(
                      context,
                      title: 'Edit Profile',
                      size: EdenModalSize.lg,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const EdenInput(label: 'Full Name', hint: 'Enter your name'),
                          const SizedBox(height: 12),
                          const EdenInput(label: 'Email', hint: 'you@example.com'),
                          const SizedBox(height: 12),
                          const EdenInput(label: 'Bio', hint: 'Tell us about yourself', maxLines: 3),
                        ],
                      ),
                      actions: [
                        EdenButton(
                          label: 'Cancel',
                          variant: EdenButtonVariant.secondary,
                          size: EdenButtonSize.sm,
                          onPressed: () => Navigator.pop(context),
                        ),
                        EdenButton(
                          label: 'Save Changes',
                          size: EdenButtonSize.sm,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // Drawer
          Section(
            title: 'Drawer Panel',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                EdenButton(
                  label: 'Open Drawer',
                  onPressed: () {
                    EdenDrawerPanel.show(
                      context,
                      title: 'Filters',
                      child: Padding(
                        padding: const EdgeInsets.all(EdenSpacing.space4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const EdenInput(label: 'Search', hint: 'Filter by name...'),
                            const SizedBox(height: 16),
                            EdenSelect<String>(
                              label: 'Status',
                              options: const [
                                EdenSelectOption(value: 'active', label: 'Active'),
                                EdenSelectOption(value: 'pending', label: 'Pending'),
                                EdenSelectOption(value: 'archived', label: 'Archived'),
                              ],
                              hint: 'Select status',
                            ),
                            const SizedBox(height: 16),
                            EdenButton(
                              label: 'Apply Filters',
                              fullWidth: true,
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                EdenButton(
                  label: 'Left Drawer',
                  variant: EdenButtonVariant.secondary,
                  onPressed: () {
                    EdenDrawerPanel.show(
                      context,
                      title: 'Navigation',
                      position: EdenDrawerPosition.left,
                      child: EdenListGroup(
                        items: [
                          EdenListGroupItem(title: 'Dashboard', leading: const Icon(Icons.dashboard, size: 18), active: true, onTap: () {}),
                          EdenListGroupItem(title: 'Conversations', leading: const Icon(Icons.chat, size: 18), onTap: () {}),
                          EdenListGroupItem(title: 'Settings', leading: const Icon(Icons.settings, size: 18), onTap: () {}),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Toast
          Section(
            title: 'Toast Notifications',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: EdenToastVariant.values.map((v) => EdenButton(
                label: v.name[0].toUpperCase() + v.name.substring(1),
                variant: EdenButtonVariant.secondary,
                size: EdenButtonSize.sm,
                onPressed: () {
                  EdenToast.show(
                    context,
                    message: '${v.name[0].toUpperCase()}${v.name.substring(1)} toast message.',
                    variant: v,
                  );
                },
              )).toList(),
            ),
          ),

          // Dropdown
          Section(
            title: 'Dropdown Menu',
            child: EdenDropdown(
              items: [
                EdenDropdownItem(label: 'Edit', icon: Icons.edit, onTap: () {}),
                EdenDropdownItem(label: 'Duplicate', icon: Icons.copy, onTap: () {}),
                EdenDropdownItem(label: 'Share', icon: Icons.share, onTap: () {}),
                const EdenDropdownDivider(),
                EdenDropdownItem(label: 'Delete', icon: Icons.delete, destructive: true, onTap: () {}),
              ],
              child: EdenButton(
                label: 'Actions',
                variant: EdenButtonVariant.secondary,
                trailingIcon: Icons.expand_more,
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
    );
  }
}
