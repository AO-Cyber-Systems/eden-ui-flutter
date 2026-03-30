import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/radii.dart';

/// Severity level for log entries.
enum EdenLogLevel {
  debug,
  info,
  warning,
  error;

  String get label {
    switch (this) {
      case EdenLogLevel.debug:
        return 'Debug';
      case EdenLogLevel.info:
        return 'Info';
      case EdenLogLevel.warning:
        return 'Warning';
      case EdenLogLevel.error:
        return 'Error';
    }
  }

  int get priority {
    switch (this) {
      case EdenLogLevel.debug:
        return 0;
      case EdenLogLevel.info:
        return 1;
      case EdenLogLevel.warning:
        return 2;
      case EdenLogLevel.error:
        return 3;
    }
  }
}

/// A single log entry for display in [EdenLogViewer].
class EdenLogEntry {
  const EdenLogEntry({
    required this.message,
    required this.timestamp,
    required this.level,
    this.source,
  });

  final String message;
  final DateTime timestamp;
  final EdenLogLevel level;
  final String? source;
}

/// A real-time log stream display widget with filtering, search, and
/// auto-scroll support.
class EdenLogViewer extends StatefulWidget {
  const EdenLogViewer({
    super.key,
    required this.entries,
    this.minimumLevel,
    this.autoScroll = true,
    this.showTimestamps = true,
    this.showSource = true,
    this.searchQuery,
    this.onLevelFilterChanged,
    this.onSearchChanged,
  });

  /// The log entries to display.
  final List<EdenLogEntry> entries;

  /// Filter out entries below this level. When null, all entries are shown.
  final EdenLogLevel? minimumLevel;

  /// Whether to automatically scroll to the bottom when new entries arrive.
  final bool autoScroll;

  /// Whether to display timestamps on each log entry row.
  final bool showTimestamps;

  /// Whether to display the source label on each log entry row.
  final bool showSource;

  /// A search string used to filter entries by message content.
  final String? searchQuery;

  /// Called when the user changes the level filter via the dropdown.
  final ValueChanged<EdenLogLevel?>? onLevelFilterChanged;

  /// Called when the user changes the search query via the text field.
  final ValueChanged<String>? onSearchChanged;

  @override
  State<EdenLogViewer> createState() => _EdenLogViewerState();
}

class _EdenLogViewerState extends State<EdenLogViewer> {
  final ScrollController _scrollController = ScrollController();
  late TextEditingController _searchController;
  int _previousEntryCount = 0;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery ?? '');
    _previousEntryCount = widget.entries.length;
  }

  @override
  void didUpdateWidget(covariant EdenLogViewer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.searchQuery != oldWidget.searchQuery &&
        widget.searchQuery != _searchController.text) {
      _searchController.text = widget.searchQuery ?? '';
    }

    if (widget.autoScroll && widget.entries.length > _previousEntryCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToEnd();
      });
    }
    _previousEntryCount = widget.entries.length;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleSearchChanged(String value) {
    widget.onSearchChanged?.call(value);
  }

  void _handleLevelFilterChanged(EdenLogLevel? level) {
    widget.onLevelFilterChanged?.call(level);
  }

  void _handleAutoScrollToggle() {
    // When the user taps auto-scroll on, immediately scroll to end.
    if (!widget.autoScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToEnd();
      });
    }
    // Delegate the toggle to the parent via the level filter callback pattern.
    // Auto-scroll state is managed externally via the autoScroll param.
  }

  List<EdenLogEntry> _buildFilteredEntries() {
    Iterable<EdenLogEntry> filtered = widget.entries;

    if (widget.minimumLevel != null) {
      final minPriority = widget.minimumLevel!.priority;
      filtered = filtered.where((e) => e.level.priority >= minPriority);
    }

    final query = widget.searchQuery?.toLowerCase();
    if (query != null && query.isNotEmpty) {
      filtered = filtered.where(
        (e) => e.message.toLowerCase().contains(query),
      );
    }

    return filtered.toList();
  }

  Map<EdenLogLevel, int> _buildLevelCounts() {
    final counts = <EdenLogLevel, int>{};
    for (final level in EdenLogLevel.values) {
      counts[level] = 0;
    }
    for (final entry in widget.entries) {
      counts[entry.level] = (counts[entry.level] ?? 0) + 1;
    }
    return counts;
  }

  Color _buildLevelColor(EdenLogLevel level) {
    switch (level) {
      case EdenLogLevel.debug:
        return EdenColors.neutral[400]!;
      case EdenLogLevel.info:
        return EdenColors.info;
      case EdenLogLevel.warning:
        return EdenColors.warning;
      case EdenLogLevel.error:
        return EdenColors.error;
    }
  }

  Widget _buildToolbar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final levelCounts = _buildLevelCounts();

    return Padding(
      padding: const EdgeInsets.all(EdenSpacing.space3),
      child: Row(
        children: [
          // Search text field.
          Expanded(
            child: SizedBox(
              height: 36,
              child: TextField(
                controller: _searchController,
                onChanged: _handleSearchChanged,
                style: theme.textTheme.bodySmall,
                decoration: InputDecoration(
                  hintText: 'Search logs...',
                  hintStyle: theme.textTheme.bodySmall?.copyWith(
                    color: EdenColors.neutral[400],
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 18,
                    color: EdenColors.neutral[400],
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: EdenSpacing.space3,
                    vertical: EdenSpacing.space1,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: EdenRadii.borderRadiusSm,
                    borderSide: BorderSide(
                      color: isDark
                          ? EdenColors.neutral[700]!
                          : EdenColors.neutral[300]!,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: EdenRadii.borderRadiusSm,
                    borderSide: BorderSide(
                      color: isDark
                          ? EdenColors.neutral[700]!
                          : EdenColors.neutral[300]!,
                    ),
                  ),
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: EdenSpacing.space3),

          // Level filter dropdown with count badges.
          DropdownButtonHideUnderline(
            child: DropdownButton<EdenLogLevel?>(
              value: widget.minimumLevel,
              hint: Text(
                'All levels',
                style: theme.textTheme.bodySmall,
              ),
              onChanged: _handleLevelFilterChanged,
              items: [
                DropdownMenuItem<EdenLogLevel?>(
                  value: null,
                  child: Text(
                    'All levels',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                ...EdenLogLevel.values.map(
                  (level) => DropdownMenuItem<EdenLogLevel?>(
                    value: level,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _buildLevelColor(level),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: EdenSpacing.space2),
                        Text(
                          level.label,
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(width: EdenSpacing.space1),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: EdenSpacing.space1,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? EdenColors.neutral[700]!
                                : EdenColors.neutral[200]!,
                            borderRadius: EdenRadii.borderRadiusSm,
                          ),
                          child: Text(
                            '${levelCounts[level] ?? 0}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: EdenColors.neutral[500],
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: EdenSpacing.space2),

          // Auto-scroll toggle.
          IconButton(
            onPressed: _handleAutoScrollToggle,
            icon: Icon(
              widget.autoScroll
                  ? Icons.vertical_align_bottom
                  : Icons.vertical_align_bottom_outlined,
              size: 20,
              color: widget.autoScroll
                  ? EdenColors.info
                  : EdenColors.neutral[400],
            ),
            tooltip: widget.autoScroll
                ? 'Auto-scroll enabled'
                : 'Auto-scroll disabled',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildLogEntryRow(BuildContext context, EdenLogEntry entry) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final monoStyle = theme.textTheme.bodySmall?.copyWith(
      fontFamily: 'monospace',
      fontFamilyFallback: const ['Courier New', 'Courier'],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space3,
        vertical: EdenSpacing.space1,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timestamp.
          if (widget.showTimestamps)
            Padding(
              padding: const EdgeInsets.only(right: EdenSpacing.space2),
              child: Text(
                _formatTimestamp(entry.timestamp),
                style: monoStyle?.copyWith(
                  color: EdenColors.neutral[500],
                  fontSize: 11,
                ),
              ),
            ),

          // Level dot.
          Padding(
            padding: const EdgeInsets.only(
              top: 4,
              right: EdenSpacing.space2,
            ),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _buildLevelColor(entry.level),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Source label.
          if (widget.showSource && entry.source != null)
            Padding(
              padding: const EdgeInsets.only(right: EdenSpacing.space2),
              child: Text(
                entry.source!,
                style: monoStyle?.copyWith(
                  color: isDark
                      ? EdenColors.neutral[400]!
                      : EdenColors.neutral[500]!,
                  fontSize: 11,
                ),
              ),
            ),

          // Message.
          Expanded(
            child: Text(
              entry.message,
              style: monoStyle?.copyWith(
                color: isDark
                    ? EdenColors.neutral[200]!
                    : EdenColors.neutral[800]!,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    final ms = timestamp.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filteredEntries = _buildFilteredEntries();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? EdenColors.neutral[800] : theme.colorScheme.surface,
        border: Border.all(
          color: isDark ? EdenColors.neutral[700]! : EdenColors.neutral[300]!,
        ),
        borderRadius: EdenRadii.borderRadiusLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildToolbar(context),
          Divider(
            height: 1,
            thickness: 1,
            color:
                isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!,
          ),
          Expanded(
            child: filteredEntries.isEmpty
                ? Center(
                    child: Text(
                      'No log entries',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: EdenColors.neutral[400],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding:
                        const EdgeInsets.symmetric(vertical: EdenSpacing.space2),
                    itemCount: filteredEntries.length,
                    itemBuilder: (context, index) {
                      return _buildLogEntryRow(context, filteredEntries[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
