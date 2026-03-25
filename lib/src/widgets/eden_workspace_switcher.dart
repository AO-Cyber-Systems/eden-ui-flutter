import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// A workspace entry.
class EdenWorkspace {
  const EdenWorkspace({
    required this.id,
    required this.name,
    this.icon,
    this.avatarUrl,
    this.subtitle,
    this.isSelected = false,
  });

  final String id;
  final String name;
  final IconData? icon;
  final String? avatarUrl;
  final String? subtitle;
  final bool isSelected;
}

/// A section grouping workspaces.
class EdenWorkspaceSection {
  const EdenWorkspaceSection({
    required this.title,
    required this.items,
  });

  final String title;
  final List<EdenWorkspace> items;
}

/// Workspace layout mode.
enum EdenWorkspaceSwitcherLayout { compact, expanded }

/// Context/workspace popup selector.
class EdenWorkspaceSwitcher extends StatelessWidget {
  const EdenWorkspaceSwitcher({
    super.key,
    required this.current,
    required this.sections,
    required this.onSelect,
    this.layout = EdenWorkspaceSwitcherLayout.compact,
  });

  final EdenWorkspace current;
  final List<EdenWorkspaceSection> sections;
  final ValueChanged<EdenWorkspace> onSelect;
  final EdenWorkspaceSwitcherLayout layout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopupMenuButton<EdenWorkspace>(
      onSelected: onSelect,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: EdenRadii.borderRadiusLg),
      color: isDark ? EdenColors.neutral[800] : Colors.white,
      constraints: BoxConstraints(
        minWidth: layout == EdenWorkspaceSwitcherLayout.expanded ? 280 : 240,
        maxWidth: 320,
      ),
      itemBuilder: (context) {
        final items = <PopupMenuEntry<EdenWorkspace>>[];
        for (int s = 0; s < sections.length; s++) {
          final section = sections[s];
          if (s > 0) {
            items.add(const PopupMenuDivider(height: 1));
          }
          // Section header
          items.add(_SectionHeader(title: section.title, isDark: isDark));
          // Workspace items
          for (final workspace in section.items) {
            items.add(_WorkspaceItem(
              workspace: workspace,
              isDark: isDark,
              isExpanded: layout == EdenWorkspaceSwitcherLayout.expanded,
            ));
          }
        }
        return items;
      },
      child: _TriggerButton(
        current: current,
        isDark: isDark,
        isExpanded: layout == EdenWorkspaceSwitcherLayout.expanded,
        theme: theme,
      ),
    );
  }
}

class _TriggerButton extends StatelessWidget {
  const _TriggerButton({
    required this.current,
    required this.isDark,
    required this.isExpanded,
    required this.theme,
  });

  final EdenWorkspace current;
  final bool isDark;
  final bool isExpanded;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isExpanded ? EdenSpacing.space4 : EdenSpacing.space3,
        vertical: isExpanded ? EdenSpacing.space3 : EdenSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: isDark ? EdenColors.neutral[800] : EdenColors.neutral[50],
        borderRadius: EdenRadii.borderRadiusLg,
        border: Border.all(
          color: isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _WorkspaceAvatar(
            workspace: current,
            isDark: isDark,
            size: isExpanded ? 28 : 22,
          ),
          const SizedBox(width: EdenSpacing.space2),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  current.name,
                  style: TextStyle(
                    fontSize: isExpanded ? 14 : 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? EdenColors.neutral[100]
                        : EdenColors.neutral[900],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (isExpanded && current.subtitle != null)
                  Text(
                    current.subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? EdenColors.neutral[400]
                          : EdenColors.neutral[500],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: EdenSpacing.space1),
          Icon(
            Icons.unfold_more,
            size: 16,
            color: isDark ? EdenColors.neutral[400] : EdenColors.neutral[500],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends PopupMenuEntry<EdenWorkspace> {
  const _SectionHeader({required this.title, required this.isDark});

  final String title;
  final bool isDark;

  @override
  double get height => 32;

  @override
  bool represents(EdenWorkspace? value) => false;

  @override
  State<_SectionHeader> createState() => _SectionHeaderState();
}

class _SectionHeaderState extends State<_SectionHeader> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        EdenSpacing.space4,
        EdenSpacing.space2,
        EdenSpacing.space4,
        EdenSpacing.space1,
      ),
      child: Text(
        widget.title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: widget.isDark
              ? EdenColors.neutral[500]
              : EdenColors.neutral[400],
        ),
      ),
    );
  }
}

class _WorkspaceItem extends PopupMenuItem<EdenWorkspace> {
  _WorkspaceItem({
    required EdenWorkspace workspace,
    required bool isDark,
    required bool isExpanded,
  }) : super(
          value: workspace,
          height: isExpanded ? 52 : 40,
          child: _WorkspaceItemContent(
            workspace: workspace,
            isDark: isDark,
            isExpanded: isExpanded,
          ),
        );
}

class _WorkspaceItemContent extends StatelessWidget {
  const _WorkspaceItemContent({
    required this.workspace,
    required this.isDark,
    required this.isExpanded,
  });

  final EdenWorkspace workspace;
  final bool isDark;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _WorkspaceAvatar(
          workspace: workspace,
          isDark: isDark,
          size: isExpanded ? 28 : 22,
        ),
        const SizedBox(width: EdenSpacing.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                workspace.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? EdenColors.neutral[100]
                      : EdenColors.neutral[900],
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (isExpanded && workspace.subtitle != null)
                Text(
                  workspace.subtitle!,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? EdenColors.neutral[400]
                        : EdenColors.neutral[500],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        if (workspace.isSelected)
          Icon(
            Icons.check,
            size: 16,
            color: isDark ? EdenColors.neutral[300] : EdenColors.neutral[600],
          ),
      ],
    );
  }
}

class _WorkspaceAvatar extends StatelessWidget {
  const _WorkspaceAvatar({
    required this.workspace,
    required this.isDark,
    required this.size,
  });

  final EdenWorkspace workspace;
  final bool isDark;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (workspace.icon != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isDark ? EdenColors.neutral[700] : EdenColors.neutral[200],
          borderRadius: BorderRadius.circular(EdenRadii.sm),
        ),
        child: Icon(
          workspace.icon,
          size: size * 0.6,
          color: isDark ? EdenColors.neutral[300] : EdenColors.neutral[600],
        ),
      );
    }

    // Fallback: initial letter avatar
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(EdenRadii.sm),
      ),
      alignment: Alignment.center,
      child: Text(
        workspace.name.isNotEmpty ? workspace.name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: size * 0.45,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
