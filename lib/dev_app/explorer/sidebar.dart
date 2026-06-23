// lib/dev_app/explorer/sidebar.dart
//
// ExplorerSidebar — a fixed-width, search-filterable navigator over
// StoryRegistry.instance.all(), grouped by component. Selecting a story lifts
// its id to StoryShell via onSelect. Holds only local search-query state.

import 'package:flutter/material.dart';

import '../registry/eden_story.dart';
import '../registry/story_registry.dart';

/// Left-rail navigator listing every registered story, grouped by component,
/// with a live text filter over component/name/id.
class ExplorerSidebar extends StatefulWidget {
  const ExplorerSidebar({
    super.key,
    required this.selectedStoryId,
    required this.onSelect,
    this.width = 260,
  });

  final String? selectedStoryId;
  final ValueChanged<String> onSelect;
  final double width;

  @override
  State<ExplorerSidebar> createState() => _ExplorerSidebarState();
}

class _ExplorerSidebarState extends State<ExplorerSidebar> {
  String _query = '';

  List<EdenStory> get _filtered {
    final all = StoryRegistry.instance.all();
    if (_query.isEmpty) return all;
    final q = _query.toLowerCase();
    return all
        .where((s) =>
            s.component.toLowerCase().contains(q) ||
            s.name.toLowerCase().contains(q) ||
            s.id.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'Search stories',
                prefixIcon: Icon(Icons.search, size: 18),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(children: _buildGrouped(_filtered)),
          ),
        ],
      ),
    );
  }

  /// Stories arrive pre-sorted by (component, name) from [StoryRegistry.all],
  /// so a single pass emits a component header whenever the component changes.
  List<Widget> _buildGrouped(List<EdenStory> stories) {
    final widgets = <Widget>[];
    String? current;
    for (final s in stories) {
      if (s.component != current) {
        current = s.component;
        widgets.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Text(
              s.component.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      }
      widgets.add(
        ListTile(
          dense: true,
          selected: s.id == widget.selectedStoryId,
          leading: s.icon == null ? null : Icon(s.icon, size: 18),
          title: Text(s.name),
          onTap: () {
            widget.onSelect(s.id);
            // Deep-link: update the URL hash to /#/story/<id> (shareable).
            // Replace (not push) so repeated selections don't grow the stack;
            // guard against re-navigating to the already-active route.
            final current = ModalRoute.of(context)?.settings.name;
            if (current != s.routeName) {
              Navigator.of(context).pushReplacementNamed(s.routeName);
            }
          },
        ),
      );
    }
    return widgets;
  }
}
