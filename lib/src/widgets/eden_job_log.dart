import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// The execution status of a job log step.
enum EdenJobLogStepStatus {
  /// Step completed successfully.
  passed,

  /// Step completed with a failure.
  failed,

  /// Step is currently running.
  running,
}

/// A single step within a job log, containing output lines.
class EdenJobLogStep {
  /// Creates a job log step.
  const EdenJobLogStep({
    required this.name,
    required this.status,
    this.duration,
    this.lines = const [],
  });

  /// Display name of the step.
  final String name;

  /// Current execution status.
  final EdenJobLogStepStatus status;

  /// Duration of the step execution.
  final Duration? duration;

  /// Output lines for this step.
  final List<String> lines;
}

/// A collapsible job log viewer with step sections, ANSI color support,
/// line numbers, search, and auto-scroll.
///
/// Parses basic ANSI escape sequences to render colored log output with
/// corresponding [TextSpan] styles.
///
/// ```dart
/// EdenJobLog(
///   steps: [
///     EdenJobLogStep(
///       name: 'Checkout',
///       status: EdenJobLogStepStatus.passed,
///       duration: Duration(seconds: 2),
///       lines: ['Cloning repository...', 'Done.'],
///     ),
///   ],
///   onStepTap: (step) => print(step.name),
/// )
/// ```
class EdenJobLog extends StatefulWidget {
  /// Creates a job log widget.
  const EdenJobLog({
    super.key,
    required this.steps,
    this.autoScroll = true,
    this.onStepTap,
  });

  /// The log steps to display.
  final List<EdenJobLogStep> steps;

  /// Whether to auto-scroll to the bottom of the log.
  final bool autoScroll;

  /// Called when a step header is tapped.
  final ValueChanged<EdenJobLogStep>? onStepTap;

  @override
  State<EdenJobLog> createState() => _EdenJobLogState();
}

class _EdenJobLogState extends State<EdenJobLog> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final Map<int, bool> _expandedSteps = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Expand all steps by default.
    for (int i = 0; i < widget.steps.length; i++) {
      _expandedSteps[i] = true;
    }
  }

  @override
  void didUpdateWidget(EdenJobLog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.steps.length != oldWidget.steps.length) {
      for (int i = oldWidget.steps.length; i < widget.steps.length; i++) {
        _expandedSteps[i] = true;
      }
      if (widget.autoScroll) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSearchBar(theme, isDark),
        const SizedBox(height: EdenSpacing.space2),
        Flexible(
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1E) : EdenColors.neutral[50],
              border: Border.all(
                color: isDark
                    ? EdenColors.neutral[700]!
                    : EdenColors.neutral[200]!,
              ),
              borderRadius: EdenRadii.borderRadiusLg,
            ),
            child: ClipRRect(
              borderRadius: EdenRadii.borderRadiusLg,
              child: ListView.builder(
                controller: _scrollController,
                shrinkWrap: true,
                itemCount: widget.steps.length,
                itemBuilder: (context, index) {
                  return _buildStepSection(index, theme, isDark);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(ThemeData theme, bool isDark) {
    return SizedBox(
      height: 36,
      child: TextField(
        controller: _searchController,
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
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 16,
                    color: EdenColors.neutral[400],
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: EdenSpacing.space3,
            vertical: EdenSpacing.space1,
          ),
          border: OutlineInputBorder(
            borderRadius: EdenRadii.borderRadiusMd,
            borderSide: BorderSide(
              color: isDark
                  ? EdenColors.neutral[700]!
                  : EdenColors.neutral[200]!,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: EdenRadii.borderRadiusMd,
            borderSide: BorderSide(
              color: isDark
                  ? EdenColors.neutral[700]!
                  : EdenColors.neutral[200]!,
            ),
          ),
          filled: true,
          fillColor: isDark ? EdenColors.neutral[900] : Colors.white,
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value.toLowerCase());
        },
      ),
    );
  }

  Widget _buildStepSection(int index, ThemeData theme, bool isDark) {
    final step = widget.steps[index];
    final isExpanded = _expandedSteps[index] ?? true;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStepHeader(index, step, theme, isDark),
        if (isExpanded) _buildStepLines(step, theme, isDark),
      ],
    );
  }

  Widget _buildStepHeader(
    int index,
    EdenJobLogStep step,
    ThemeData theme,
    bool isDark,
  ) {
    final statusColor = _stepStatusColor(step.status);
    final isExpanded = _expandedSteps[index] ?? true;

    return GestureDetector(
      onTap: () {
        setState(() => _expandedSteps[index] = !isExpanded);
        widget.onStepTap?.call(step);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: EdenSpacing.space3,
          vertical: EdenSpacing.space2,
        ),
        color: isDark ? EdenColors.neutral[800] : EdenColors.neutral[100],
        child: Row(
          children: [
            Icon(
              isExpanded ? Icons.expand_more : Icons.chevron_right,
              size: 18,
              color: EdenColors.neutral[500],
            ),
            const SizedBox(width: EdenSpacing.space2),
            _buildStepStatusIcon(step.status, statusColor),
            const SizedBox(width: EdenSpacing.space2),
            Expanded(
              child: Text(
                step.name,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                  color: isDark
                      ? EdenColors.neutral[200]
                      : EdenColors.neutral[800],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (step.duration != null)
              Text(
                _formatDuration(step.duration!),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontFamily: 'monospace',
                  color: EdenColors.neutral[500],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepStatusIcon(EdenJobLogStepStatus status, Color color) {
    if (status == EdenJobLogStepStatus.running) {
      return SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(strokeWidth: 2, color: color),
      );
    }
    return Icon(
      status == EdenJobLogStepStatus.passed
          ? Icons.check_circle
          : Icons.cancel,
      size: 14,
      color: color,
    );
  }

  Widget _buildStepLines(EdenJobLogStep step, ThemeData theme, bool isDark) {
    final lines = step.lines;
    if (lines.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(EdenSpacing.space3),
        child: Text(
          'No output',
          style: theme.textTheme.bodySmall?.copyWith(
            fontStyle: FontStyle.italic,
            color: EdenColors.neutral[500],
          ),
        ),
      );
    }

    // Cumulative line offset for numbering across steps.
    int lineOffset = 0;
    for (final s in widget.steps) {
      if (identical(s, step)) break;
      lineOffset += s.lines.length;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space3,
        vertical: EdenSpacing.space2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < lines.length; i++)
            _buildLogLine(lineOffset + i + 1, lines[i], theme, isDark),
        ],
      ),
    );
  }

  Widget _buildLogLine(
    int lineNumber,
    String rawLine,
    ThemeData theme,
    bool isDark,
  ) {
    final isMatch = _searchQuery.isNotEmpty &&
        rawLine.toLowerCase().contains(_searchQuery);

    return Container(
      color: isMatch
          ? EdenColors.warning.withValues(alpha: isDark ? 0.15 : 0.1)
          : null,
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Text(
              lineNumber.toString(),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: EdenColors.neutral[500],
              ),
            ),
          ),
          const SizedBox(width: EdenSpacing.space3),
          Expanded(
            child: Text.rich(
              _parseAnsi(rawLine, isDark),
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: isDark
                    ? EdenColors.neutral[300]
                    : EdenColors.neutral[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Parses basic ANSI escape sequences and returns a [TextSpan] tree.
  TextSpan _parseAnsi(String raw, bool isDark) {
    final spans = <TextSpan>[];
    final ansiPattern = RegExp(r'\x1B\[([0-9;]*)m');
    int lastEnd = 0;
    Color? currentColor;
    bool isBold = false;

    for (final match in ansiPattern.allMatches(raw)) {
      // Add text before this escape code.
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: raw.substring(lastEnd, match.start),
          style: TextStyle(
            color: currentColor,
            fontWeight: isBold ? FontWeight.bold : null,
          ),
        ));
      }

      final codes = match.group(1)?.split(';') ?? [];
      for (final code in codes) {
        switch (code) {
          case '0':
            currentColor = null;
            isBold = false;
          case '1':
            isBold = true;
          case '31':
            currentColor = isDark
                ? EdenColors.red[400]
                : EdenColors.red[600];
          case '32':
            currentColor = isDark
                ? EdenColors.emerald[400]
                : EdenColors.emerald[600];
          case '33':
            currentColor = EdenColors.warning;
          case '34':
            currentColor = isDark
                ? EdenColors.blue[400]
                : EdenColors.blue[600];
        }
      }

      lastEnd = match.end;
    }

    // Add remaining text.
    if (lastEnd < raw.length) {
      spans.add(TextSpan(
        text: raw.substring(lastEnd),
        style: TextStyle(
          color: currentColor,
          fontWeight: isBold ? FontWeight.bold : null,
        ),
      ));
    }

    if (spans.isEmpty) {
      return TextSpan(text: raw);
    }

    return TextSpan(children: spans);
  }

  Color _stepStatusColor(EdenJobLogStepStatus status) {
    switch (status) {
      case EdenJobLogStepStatus.passed:
        return EdenColors.success;
      case EdenJobLogStepStatus.failed:
        return EdenColors.error;
      case EdenJobLogStepStatus.running:
        return EdenColors.info;
    }
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    if (d.inMinutes > 0) {
      return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
    }
    return '${d.inSeconds}s';
  }
}
