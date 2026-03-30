import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

/// The type of a file-tree node.
enum EdenFileTreeNodeType { file, folder }

/// Change-status for version-control annotations.
enum EdenFileChangeStatus { none, added, modified, deleted, renamed }

/// A single node in the file tree.
class EdenFileTreeNode {
  const EdenFileTreeNode({
    required this.id,
    required this.name,
    required this.type,
    this.children = const [],
    this.isExpanded = false,
    this.changeStatus = EdenFileChangeStatus.none,
  });

  final String id;
  final String name;
  final EdenFileTreeNodeType type;
  final List<EdenFileTreeNode> children;
  final bool isExpanded;
  final EdenFileChangeStatus changeStatus;

  /// Returns a shallow copy with the given field overrides.
  EdenFileTreeNode copyWith({
    String? id,
    String? name,
    EdenFileTreeNodeType? type,
    List<EdenFileTreeNode>? children,
    bool? isExpanded,
    EdenFileChangeStatus? changeStatus,
  }) {
    return EdenFileTreeNode(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      children: children ?? this.children,
      isExpanded: isExpanded ?? this.isExpanded,
      changeStatus: changeStatus ?? this.changeStatus,
    );
  }
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

/// A hierarchical file/folder tree browser with expand/collapse, file-type
/// icons, change-status indicators, and optional lazy-loading.
class EdenFileTree extends StatefulWidget {
  const EdenFileTree({
    super.key,
    required this.nodes,
    this.selectedNodeId,
    this.onNodeTap,
    this.onNodeExpand,
    this.onLoadChildren,
  });

  /// Root-level tree nodes.
  final List<EdenFileTreeNode> nodes;

  /// ID of the currently selected node (highlight).
  final String? selectedNodeId;

  /// Called when a node is tapped (file or folder).
  final ValueChanged<EdenFileTreeNode>? onNodeTap;

  /// Called when a folder is expanded or collapsed.
  final ValueChanged<EdenFileTreeNode>? onNodeExpand;

  /// Optional lazy-loading callback. Return the children for [node].
  /// When provided, folders with no children will call this on first expand.
  final Future<List<EdenFileTreeNode>> Function(EdenFileTreeNode node)?
      onLoadChildren;

  @override
  State<EdenFileTree> createState() => _EdenFileTreeState();
}

class _EdenFileTreeState extends State<EdenFileTree> {
  /// Tracks which folder IDs are expanded locally.
  final Set<String> _expanded = {};

  /// Tracks which folder IDs are currently loading children.
  final Set<String> _loading = {};

  /// Lazily loaded children keyed by parent node ID.
  final Map<String, List<EdenFileTreeNode>> _lazyChildren = {};

  @override
  void initState() {
    super.initState();
    // Seed expanded set from initial node state.
    _seedExpanded(widget.nodes);
  }

  void _seedExpanded(List<EdenFileTreeNode> nodes) {
    for (final node in nodes) {
      if (node.isExpanded) _expanded.add(node.id);
      if (node.children.isNotEmpty) _seedExpanded(node.children);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final node in widget.nodes) _buildNode(context, node, 0),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Node rendering
  // -------------------------------------------------------------------------

  Widget _buildNode(BuildContext context, EdenFileTreeNode node, int depth) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = node.id == widget.selectedNodeId;
    final isExpanded = _expanded.contains(node.id);
    final isFolder = node.type == EdenFileTreeNodeType.folder;
    final isLoading = _loading.contains(node.id);

    final children = _lazyChildren[node.id] ?? node.children;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EdenFileTreeRow(
          node: node,
          depth: depth,
          isSelected: isSelected,
          isExpanded: isExpanded,
          isLoading: isLoading,
          isDark: isDark,
          theme: theme,
          onTap: () => _handleTap(node),
        ),
        if (isFolder && isExpanded)
          for (final child in children)
            _buildNode(context, child, depth + 1),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Interaction
  // -------------------------------------------------------------------------

  Future<void> _handleTap(EdenFileTreeNode node) async {
    widget.onNodeTap?.call(node);

    if (node.type == EdenFileTreeNodeType.folder) {
      final wasExpanded = _expanded.contains(node.id);

      if (!wasExpanded && widget.onLoadChildren != null && node.children.isEmpty && !_lazyChildren.containsKey(node.id)) {
        // Lazy-load children.
        setState(() => _loading.add(node.id));
        try {
          final loaded = await widget.onLoadChildren!(node);
          if (mounted) {
            setState(() {
              _lazyChildren[node.id] = loaded;
              _loading.remove(node.id);
              _expanded.add(node.id);
            });
          }
        } catch (_) {
          if (mounted) setState(() => _loading.remove(node.id));
        }
      } else {
        setState(() {
          if (wasExpanded) {
            _expanded.remove(node.id);
          } else {
            _expanded.add(node.id);
          }
        });
      }

      widget.onNodeExpand?.call(node);
    }
  }
}

// ---------------------------------------------------------------------------
// Row widget (private)
// ---------------------------------------------------------------------------

class _EdenFileTreeRow extends StatefulWidget {
  const _EdenFileTreeRow({
    required this.node,
    required this.depth,
    required this.isSelected,
    required this.isExpanded,
    required this.isLoading,
    required this.isDark,
    required this.theme,
    required this.onTap,
  });

  final EdenFileTreeNode node;
  final int depth;
  final bool isSelected;
  final bool isExpanded;
  final bool isLoading;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  State<_EdenFileTreeRow> createState() => _EdenFileTreeRowState();
}

class _EdenFileTreeRowState extends State<_EdenFileTreeRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _chevronController;
  late Animation<double> _chevronTurns;

  @override
  void initState() {
    super.initState();
    _chevronController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
      value: widget.isExpanded ? 1.0 : 0.0,
    );
    _chevronTurns = Tween<double>(begin: 0.0, end: 0.25).animate(
      CurvedAnimation(parent: _chevronController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant _EdenFileTreeRow old) {
    super.didUpdateWidget(old);
    if (widget.isExpanded != old.isExpanded) {
      if (widget.isExpanded) {
        _chevronController.forward();
      } else {
        _chevronController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _chevronController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFolder = widget.node.type == EdenFileTreeNodeType.folder;
    final indent = EdenSpacing.space4 + (widget.depth * EdenSpacing.space5);

    final bgColor = widget.isSelected
        ? (widget.isDark
            ? EdenColors.neutral[700]!.withValues(alpha: 0.6)
            : EdenColors.neutral[100]!)
        : Colors.transparent;

    return Material(
      color: bgColor,
      child: InkWell(
        onTap: widget.onTap,
        hoverColor: widget.isDark
            ? EdenColors.neutral[800]!.withValues(alpha: 0.5)
            : EdenColors.neutral[50]!,
        child: Padding(
          padding: EdgeInsets.only(
            left: indent,
            right: EdenSpacing.space3,
            top: EdenSpacing.space1,
            bottom: EdenSpacing.space1,
          ),
          child: Row(
            children: [
              // Chevron (folders only).
              SizedBox(
                width: 20,
                height: 20,
                child: isFolder
                    ? widget.isLoading
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: widget.isDark
                                  ? EdenColors.neutral[400]
                                  : EdenColors.neutral[500],
                            ),
                          )
                        : RotationTransition(
                            turns: _chevronTurns,
                            child: Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: widget.isDark
                                  ? EdenColors.neutral[400]
                                  : EdenColors.neutral[500],
                            ),
                          )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(width: EdenSpacing.space1),
              // File-type icon.
              Icon(
                _iconForNode(widget.node),
                size: 18,
                color: _iconColorForNode(widget.node, widget.isDark),
              ),
              const SizedBox(width: EdenSpacing.space2),
              // Name.
              Expanded(
                child: Text(
                  widget.node.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isFolder ? FontWeight.w500 : FontWeight.w400,
                    color: widget.theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Change status dot.
              if (widget.node.changeStatus != EdenFileChangeStatus.none) ...[
                const SizedBox(width: EdenSpacing.space2),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _changeStatusColor(widget.node.changeStatus),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Helpers
  // -----------------------------------------------------------------------

  static Color _changeStatusColor(EdenFileChangeStatus status) {
    switch (status) {
      case EdenFileChangeStatus.added:
        return EdenColors.success;
      case EdenFileChangeStatus.modified:
        return EdenColors.warning;
      case EdenFileChangeStatus.deleted:
        return EdenColors.error;
      case EdenFileChangeStatus.renamed:
        return EdenColors.info;
      case EdenFileChangeStatus.none:
        return Colors.transparent;
    }
  }

  static IconData _iconForNode(EdenFileTreeNode node) {
    if (node.type == EdenFileTreeNodeType.folder) {
      return Icons.folder_rounded;
    }
    final ext = _extension(node.name);
    switch (ext) {
      case 'dart':
        return Icons.flutter_dash;
      case 'js':
      case 'jsx':
      case 'ts':
      case 'tsx':
        return Icons.javascript;
      case 'py':
        return Icons.code;
      case 'go':
        return Icons.code;
      case 'rb':
        return Icons.diamond_outlined;
      case 'json':
        return Icons.data_object;
      case 'yaml':
      case 'yml':
        return Icons.settings;
      case 'md':
      case 'mdx':
        return Icons.article_outlined;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'svg':
      case 'webp':
        return Icons.image_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  static Color _iconColorForNode(EdenFileTreeNode node, bool isDark) {
    if (node.type == EdenFileTreeNodeType.folder) {
      return const Color(0xFFF59E0B); // amber
    }
    final ext = _extension(node.name);
    switch (ext) {
      case 'dart':
        return const Color(0xFF06B6D4); // cyan
      case 'js':
      case 'jsx':
        return const Color(0xFFF59E0B); // amber
      case 'ts':
      case 'tsx':
        return const Color(0xFF3B82F6); // blue
      case 'py':
        return const Color(0xFF10B981); // emerald
      case 'go':
        return const Color(0xFF06B6D4); // cyan
      case 'rb':
        return const Color(0xFFEF4444); // red
      case 'json':
        return const Color(0xFFF59E0B); // amber
      case 'yaml':
      case 'yml':
        return const Color(0xFFA855F7); // purple
      case 'md':
      case 'mdx':
        return isDark ? EdenColors.neutral[300]! : EdenColors.neutral[600]!;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'svg':
      case 'webp':
        return const Color(0xFFA855F7); // purple
      default:
        return isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;
    }
  }

  static String _extension(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return '';
    return name.substring(dot + 1).toLowerCase();
  }
}
