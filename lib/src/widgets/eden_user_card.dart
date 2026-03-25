import 'package:flutter/material.dart';

/// User profile card with avatar, name, role, and optional actions.
///
/// ```dart
/// EdenUserCard(
///   name: 'John Smith',
///   role: 'Lead Technician',
///   initials: 'JS',
///   email: 'john@example.com',
///   onTap: () => navigateToProfile(userId),
/// )
/// ```
class EdenUserCard extends StatelessWidget {
  const EdenUserCard({
    super.key,
    required this.name,
    this.role,
    this.initials,
    this.avatarUrl,
    this.email,
    this.phone,
    this.status,
    this.onTap,
    this.trailing,
  });

  final String name;
  final String? role;
  final String? initials;
  final String? avatarUrl;
  final String? email;
  final String? phone;
  final String? status;
  final VoidCallback? onTap;
  final Widget? trailing;

  String get _initials {
    if (initials != null) return initials!;
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return name.isNotEmpty ? name[0] : '?';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                child: avatarUrl == null
                    ? Text(
                        _initials.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (status != null)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: status == 'active'
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                          ),
                      ],
                    ),
                    if (role != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        role!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (email != null || phone != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        [email, phone].whereType<String>().join(' · '),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
