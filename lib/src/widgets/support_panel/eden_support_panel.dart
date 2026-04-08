import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/durations.dart';
import '../../tokens/spacing.dart';
import '../eden_tabs.dart';
import 'eden_help_tab.dart';
import 'eden_support_fab.dart';
import 'eden_ticket_tab.dart';
import 'eden_tours_tab.dart';
import 'eden_support_panel_config.dart';

/// A collapsible right-side support panel rendered inline alongside [child].
///
/// The panel opens and closes with an [AnimatedContainer] so the content area
/// smoothly shrinks and expands without any overlay. A floating [EdenSupportFab]
/// appears in the bottom-right corner when the panel is closed.
///
/// **Slot mode:** When [child] is null, the panel renders only the animated
/// panel container and FAB (no Row wrapper). This is the recommended usage
/// when embedding the panel as a slot in [EdenDesktopLayout]:
///
/// ```dart
/// EdenDesktopLayout(
///   supportPanel: EdenSupportPanel(config: cfg),
///   body: myBody,
///   ...
/// )
/// ```
///
/// Tab visibility is driven by [EdenSupportPanelConfig]:
/// - Help tab: shown when help article callbacks are provided.
/// - Support tab: shown when ticket callbacks are provided.
/// - Tours tab: shown when the tours list is non-empty.
class EdenSupportPanel extends StatefulWidget {
  const EdenSupportPanel({
    super.key,
    this.child,
    required this.config,
  });

  /// Optional content area. When null, the panel renders in slot mode
  /// (panel + FAB only, no Row wrapper around a child widget).
  final Widget? child;
  final EdenSupportPanelConfig config;

  @override
  State<EdenSupportPanel> createState() => _EdenSupportPanelState();
}

class _EdenSupportPanelState extends State<EdenSupportPanel> {
  bool _panelOpen = false;
  late int _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.config.initialTab;
  }

  void _togglePanel() => setState(() => _panelOpen = !_panelOpen);

  void _closePanel() => setState(() => _panelOpen = false);

  /// Builds the list of visible tab items and the corresponding content
  /// widgets, so that [_selectedTab] always maps to a rendered widget even
  /// when some tabs are hidden.
  ({List<EdenTabItem> tabs, List<Widget> views}) _buildTabs() {
    final tabs = <EdenTabItem>[];
    final views = <Widget>[];

    if (widget.config.showHelpTab) {
      tabs.add(const EdenTabItem(label: 'Help', icon: Icons.menu_book_outlined));
      views.add(EdenHelpTab(config: widget.config));
    }
    if (widget.config.showSupportTab) {
      tabs.add(const EdenTabItem(label: 'Support', icon: Icons.confirmation_number_outlined));
      views.add(EdenTicketTab(config: widget.config));
    }
    if (widget.config.showToursTab) {
      tabs.add(const EdenTabItem(label: 'Tours', icon: Icons.map_outlined));
      views.add(EdenToursTab(
        config: widget.config,
        onClosePanel: _closePanel,
      ));
    }

    return (tabs: tabs, views: views);
  }

  Widget _buildPanel(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    List<EdenTabItem> tabs,
    List<Widget> views,
    int safeTab,
  ) {
    return AnimatedContainer(
      duration: EdenDurations.normal,
      curve: EdenDurations.easeOutExpo,
      width: _panelOpen ? widget.config.panelWidth : 0,
      decoration: BoxDecoration(
        color: isDark ? EdenColors.neutral[900] : theme.colorScheme.surface,
        border: Border(
          left: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      // ClipRect prevents child content from overflowing during the
      // width-collapsing animation.
      child: ClipRect(
        child: SizedBox(
          width: widget.config.panelWidth,
          child: tabs.isEmpty
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ----------------------------------------
                    // Panel header
                    // ----------------------------------------
                    Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(
                        horizontal: EdenSpacing.space4,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Support',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Semantics(
                            button: true,
                            label: 'Close support panel',
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _closePanel,
                              child: Padding(
                                padding: const EdgeInsets.all(EdenSpacing.space2),
                                child: Icon(
                                  Icons.close,
                                  size: 20,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ----------------------------------------
                    // Tab bar
                    // ----------------------------------------
                    EdenTabs(
                      tabs: tabs,
                      selectedIndex: safeTab,
                      onChanged: (i) => setState(() => _selectedTab = i),
                    ),
                    // ----------------------------------------
                    // Tab content
                    // ----------------------------------------
                    Expanded(
                      child: Material(
                        type: MaterialType.transparency,
                        child: IndexedStack(
                          index: safeTab,
                          children: views,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final (:tabs, :views) = _buildTabs();

    // Clamp selectedTab so it is always within the visible tab range.
    final safeTab = tabs.isEmpty ? 0 : _selectedTab.clamp(0, tabs.length - 1);

    final panel = _buildPanel(context, theme, isDark, tabs, views, safeTab);

    // ----------------------------------------------------------------
    // Slot mode: no child — render panel + FAB in a Stack directly.
    // The parent layout (e.g. EdenDesktopLayout) manages the Row.
    // ----------------------------------------------------------------
    if (widget.child == null) {
      return Stack(
        children: [
          panel,
          if (!_panelOpen) EdenSupportFab(onPressed: _togglePanel),
        ],
      );
    }

    // ----------------------------------------------------------------
    // Standalone mode: wrap child + panel in a Row inside a Stack.
    // ----------------------------------------------------------------
    return Stack(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: widget.child!),
            panel,
          ],
        ),
        // FAB — only visible when panel is closed
        if (!_panelOpen) EdenSupportFab(onPressed: _togglePanel),
      ],
    );
  }
}
