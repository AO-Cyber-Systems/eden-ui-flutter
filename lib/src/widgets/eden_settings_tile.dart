import 'package:flutter/material.dart';
import 'eden_card.dart';

/// A standardized settings menu tile with icon, title, subtitle, and action.
///
/// Used in profile/settings screens for consistent layout. Supports:
/// - Navigation tiles (trailing chevron)
/// - Toggle tiles (trailing Switch)
/// - Value tiles (trailing text)
class EdenSettingsTile extends StatelessWidget {
  const EdenSettingsTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.onTap,
    this.destructive = false,
  });

  /// Navigation tile with chevron.
  const EdenSettingsTile.navigation({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.onTap,
  })  : trailing = null,
        destructive = false;

  /// Toggle tile with Switch.
  factory EdenSettingsTile.toggle({
    Key? key,
    required String title,
    String? subtitle,
    IconData? icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return EdenSettingsTile(
      key: key,
      title: title,
      subtitle: subtitle,
      icon: icon,
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }

  /// Value display tile (e.g., "Unit System" -> "Imperial").
  factory EdenSettingsTile.value({
    Key? key,
    required String title,
    String? subtitle,
    IconData? icon,
    required String value,
    VoidCallback? onTap,
  }) {
    return EdenSettingsTile(
      key: key,
      title: title,
      subtitle: subtitle,
      icon: icon,
      trailing: Builder(builder: (context) => Text(
        value,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      )),
      onTap: onTap,
    );
  }

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleColor = destructive ? theme.colorScheme.error : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: EdenCard(
        child: ListTile(
          leading: icon != null
              ? Icon(icon,
                  color: destructive
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary)
              : null,
          title: Text(title, style: TextStyle(color: titleColor)),
          subtitle: subtitle != null
              ? Text(subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ))
              : null,
          trailing: trailing ??
              (onTap != null
                  ? Icon(Icons.chevron_right,
                      color: theme.colorScheme.onSurfaceVariant)
                  : null),
          onTap: onTap,
        ),
      ),
    );
  }
}
