import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

/// A branch or tag entry.
class EdenBranch {
  const EdenBranch({
    required this.name,
    this.isDefault = false,
    this.isProtected = false,
    this.lastCommitDate,
  });

  final String name;
  final bool isDefault;
  final bool isProtected;
  final String? lastCommitDate;
}

/// Which section is active in the popover.
enum _SelectorTab { branches, tags }

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

/// A dropdown/popover branch and tag selector with search, section tabs,
/// and an optional "Create branch" action.
class EdenBranchSelector extends StatefulWidget {
  const EdenBranchSelector({
    super.key,
    required this.currentBranch,
    this.branches = const [],
    this.tags = const [],
    this.onBranchSelected,
    this.onTagSelected,
    this.onCreateBranch,
    this.showCreateBranch = false,
  });

  /// The name of the currently checked-out branch.
  final String currentBranch;

  /// Available branches.
  final List<EdenBranch> branches;

  /// Available tags.
  final List<EdenBranch> tags;

  /// Called when the user selects a branch.
  final ValueChanged<EdenBranch>? onBranchSelected;

  /// Called when the user selects a tag.
  final ValueChanged<EdenBranch>? onTagSelected;

  /// Called when the user creates a new branch via the action button.
  final ValueChanged<String>? onCreateBranch;

  /// Whether to show the "Create branch" input at the bottom.
  final bool showCreateBranch;

  @override
  State<EdenBranchSelector> createState() => _EdenBranchSelectorState();
}

class _EdenBranchSelectorState extends State<EdenBranchSelector> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  void _toggle() {
    if (_isOpen) {
      _close();
    } else {
      _open();
    }
  }

  void _open() {
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (ctx) => _EdenBranchPopover(
        link: _layerLink,
        triggerWidth: size.width < 320 ? 320 : size.width,
        branches: widget.branches,
        tags: widget.tags,
        currentBranch: widget.currentBranch,
        showCreateBranch: widget.showCreateBranch,
        onBranchSelected: (b) {
          widget.onBranchSelected?.call(b);
          _close();
        },
        onTagSelected: (t) {
          widget.onTagSelected?.call(t);
          _close();
        },
        onCreateBranch: widget.onCreateBranch != null
            ? (name) {
                widget.onCreateBranch!(name);
                _close();
              }
            : null,
        onDismiss: _close,
      ),
    );
    overlay.insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _close() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _isOpen = false);
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return CompositedTransformTarget(
      link: _layerLink,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggle,
          borderRadius: EdenRadii.borderRadiusMd,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: EdenSpacing.space3,
              vertical: EdenSpacing.space2,
            ),
            decoration: BoxDecoration(
              color: isDark ? EdenColors.neutral[800] : Colors.white,
              borderRadius: EdenRadii.borderRadiusMd,
              border: Border.all(
                color: _isOpen
                    ? theme.colorScheme.primary
                    : (isDark
                        ? EdenColors.neutral[700]!
                        : EdenColors.neutral[200]!),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_tree_outlined,
                  size: 16,
                  color: isDark
                      ? EdenColors.neutral[400]
                      : EdenColors.neutral[500],
                ),
                const SizedBox(width: EdenSpacing.space2),
                Flexible(
                  child: Text(
                    widget.currentBranch,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: EdenSpacing.space2),
                Icon(
                  _isOpen ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: isDark
                      ? EdenColors.neutral[400]
                      : EdenColors.neutral[500],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Popover (private)
// ---------------------------------------------------------------------------

class _EdenBranchPopover extends StatefulWidget {
  const _EdenBranchPopover({
    required this.link,
    required this.triggerWidth,
    required this.branches,
    required this.tags,
    required this.currentBranch,
    required this.showCreateBranch,
    required this.onBranchSelected,
    required this.onTagSelected,
    this.onCreateBranch,
    required this.onDismiss,
  });

  final LayerLink link;
  final double triggerWidth;
  final List<EdenBranch> branches;
  final List<EdenBranch> tags;
  final String currentBranch;
  final bool showCreateBranch;
  final ValueChanged<EdenBranch> onBranchSelected;
  final ValueChanged<EdenBranch> onTagSelected;
  final ValueChanged<String>? onCreateBranch;
  final VoidCallback onDismiss;

  @override
  State<_EdenBranchPopover> createState() => _EdenBranchPopoverState();
}

class _EdenBranchPopoverState extends State<_EdenBranchPopover> {
  _SelectorTab _tab = _SelectorTab.branches;
  String _query = '';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _createController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _createController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<EdenBranch> get _filteredBranches {
    final q = _query.toLowerCase();
    return widget.branches
        .where((b) => b.name.toLowerCase().contains(q))
        .toList();
  }

  List<EdenBranch> get _filteredTags {
    final q = _query.toLowerCase();
    return widget.tags
        .where((t) => t.name.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        // Dismiss scrim.
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onDismiss,
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),
        ),
        // Popover.
        CompositedTransformFollower(
          link: widget.link,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(0, EdenSpacing.space1),
          child: Material(
            elevation: 8,
            shadowColor: Colors.black26,
            borderRadius: EdenRadii.borderRadiusLg,
            color: isDark ? EdenColors.neutral[850] : Colors.white,
            child: Container(
              width: widget.triggerWidth,
              constraints: const BoxConstraints(maxHeight: 380),
              decoration: BoxDecoration(
                borderRadius: EdenRadii.borderRadiusLg,
                border: Border.all(
                  color: isDark
                      ? EdenColors.neutral[700]!
                      : EdenColors.neutral[200]!,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSearch(isDark, theme),
                  _buildTabs(isDark, theme),
                  const Divider(height: 1),
                  Flexible(child: _buildList(isDark, theme)),
                  if (widget.showCreateBranch && widget.onCreateBranch != null)
                    _buildCreateBranch(isDark, theme),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Search
  // -------------------------------------------------------------------------

  Widget _buildSearch(bool isDark, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        EdenSpacing.space3,
        EdenSpacing.space3,
        EdenSpacing.space3,
        EdenSpacing.space2,
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocus,
        onChanged: (v) => setState(() => _query = v),
        style: TextStyle(
          fontSize: 13,
          color: theme.colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: 'Filter branches/tags...',
          hintStyle: TextStyle(
            fontSize: 13,
            color: isDark ? EdenColors.neutral[500] : EdenColors.neutral[400],
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 18,
            color: isDark ? EdenColors.neutral[500] : EdenColors.neutral[400],
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 36, minHeight: 0),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: EdenSpacing.space2,
            vertical: EdenSpacing.space2,
          ),
          border: OutlineInputBorder(
            borderRadius: EdenRadii.borderRadiusSm,
            borderSide: BorderSide(
              color: isDark
                  ? EdenColors.neutral[700]!
                  : EdenColors.neutral[200]!,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: EdenRadii.borderRadiusSm,
            borderSide: BorderSide(
              color: isDark
                  ? EdenColors.neutral[700]!
                  : EdenColors.neutral[200]!,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: EdenRadii.borderRadiusSm,
            borderSide: BorderSide(color: theme.colorScheme.primary),
          ),
          filled: true,
          fillColor: isDark ? EdenColors.neutral[800] : EdenColors.neutral[50],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Tabs
  // -------------------------------------------------------------------------

  Widget _buildTabs(bool isDark, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: EdenSpacing.space3),
      child: Row(
        children: [
          _tabButton('Branches', _SelectorTab.branches, isDark, theme),
          const SizedBox(width: EdenSpacing.space2),
          _tabButton('Tags', _SelectorTab.tags, isDark, theme),
        ],
      ),
    );
  }

  Widget _tabButton(
    String label,
    _SelectorTab tab,
    bool isDark,
    ThemeData theme,
  ) {
    final isActive = _tab == tab;
    return GestureDetector(
      onTap: () => setState(() => _tab = tab),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: EdenSpacing.space3,
          vertical: EdenSpacing.space1 + 2,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark
                  ? theme.colorScheme.primary.withValues(alpha: 0.15)
                  : theme.colorScheme.primary.withValues(alpha: 0.1))
              : Colors.transparent,
          borderRadius: EdenRadii.borderRadiusSm,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive
                ? theme.colorScheme.primary
                : (isDark
                    ? EdenColors.neutral[400]
                    : EdenColors.neutral[500]),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // List
  // -------------------------------------------------------------------------

  Widget _buildList(bool isDark, ThemeData theme) {
    final items = _tab == _SelectorTab.branches
        ? _filteredBranches
        : _filteredTags;
    final isBranchTab = _tab == _SelectorTab.branches;

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(EdenSpacing.space6),
        child: Center(
          child: Text(
            _query.isNotEmpty
                ? 'No matches found'
                : (isBranchTab ? 'No branches' : 'No tags'),
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? EdenColors.neutral[500]
                  : EdenColors.neutral[400],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: EdenSpacing.space1),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isCurrent = item.name == widget.currentBranch && isBranchTab;
        return _buildItem(item, isCurrent, isBranchTab, isDark, theme);
      },
    );
  }

  Widget _buildItem(
    EdenBranch item,
    bool isCurrent,
    bool isBranch,
    bool isDark,
    ThemeData theme,
  ) {
    return InkWell(
      onTap: () {
        if (isBranch) {
          widget.onBranchSelected(item);
        } else {
          widget.onTagSelected(item);
        }
      },
      hoverColor: isDark
          ? EdenColors.neutral[700]!.withValues(alpha: 0.5)
          : EdenColors.neutral[50]!,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: EdenSpacing.space3,
          vertical: EdenSpacing.space2,
        ),
        child: Row(
          children: [
            // Check mark for current branch.
            SizedBox(
              width: 20,
              child: isCurrent
                  ? Icon(
                      Icons.check,
                      size: 16,
                      color: theme.colorScheme.primary,
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(width: EdenSpacing.space2),
            // Branch/tag icon.
            Icon(
              isBranch
                  ? Icons.account_tree_outlined
                  : Icons.local_offer_outlined,
              size: 15,
              color:
                  isDark ? EdenColors.neutral[400] : EdenColors.neutral[500],
            ),
            const SizedBox(width: EdenSpacing.space2),
            // Name.
            Expanded(
              child: Text(
                item.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Badges: default, protected.
            if (item.isDefault) ...[
              const SizedBox(width: EdenSpacing.space2),
              const Icon(
                Icons.star_rounded,
                size: 16,
                color: Color(0xFFF59E0B),
              ),
            ],
            if (item.isProtected) ...[
              const SizedBox(width: EdenSpacing.space1),
              Icon(
                Icons.lock_outline,
                size: 14,
                color: isDark
                    ? EdenColors.neutral[500]
                    : EdenColors.neutral[400],
              ),
            ],
            // Last commit date.
            if (item.lastCommitDate != null) ...[
              const SizedBox(width: EdenSpacing.space2),
              Text(
                item.lastCommitDate!,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? EdenColors.neutral[500]
                      : EdenColors.neutral[400],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Create branch
  // -------------------------------------------------------------------------

  Widget _buildCreateBranch(bool isDark, ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(EdenSpacing.space3),
          child: Row(
            children: [
              Icon(
                Icons.add,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: EdenSpacing.space2),
              Expanded(
                child: TextField(
                  controller: _createController,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Create branch...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? EdenColors.neutral[500]
                          : EdenColors.neutral[400],
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: EdenSpacing.space2,
                      vertical: EdenSpacing.space2,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: EdenRadii.borderRadiusSm,
                      borderSide: BorderSide(
                        color: isDark
                            ? EdenColors.neutral[700]!
                            : EdenColors.neutral[200]!,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: EdenRadii.borderRadiusSm,
                      borderSide: BorderSide(
                        color: isDark
                            ? EdenColors.neutral[700]!
                            : EdenColors.neutral[200]!,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: EdenRadii.borderRadiusSm,
                      borderSide:
                          BorderSide(color: theme.colorScheme.primary),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? EdenColors.neutral[800]
                        : EdenColors.neutral[50],
                  ),
                  onSubmitted: (name) {
                    final trimmed = name.trim();
                    if (trimmed.isNotEmpty) {
                      widget.onCreateBranch?.call(trimmed);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
