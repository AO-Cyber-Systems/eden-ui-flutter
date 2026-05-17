import 'package:flutter/material.dart';

import '../tokens/colors.dart';

/// Severity level for a [EdenSection508Issue].
enum EdenSection508Severity { error, warning, info }

/// Category bucket for a [EdenSection508Issue].
enum EdenSection508Category {
  missingSemanticLabel,
  insufficientContrast,
  missingFocusOrder,
  missingTapTarget,
  missingAltText,
  other,
}

/// A single detected accessibility / Section 508 issue.
///
/// Consumer-supplied (manually authored or tool-detected). The library
/// does NOT detect issues — see [EdenSection508AuditController].
@immutable
class EdenSection508Issue {
  const EdenSection508Issue({
    required this.severity,
    required this.category,
    required this.description,
    this.fixHint,
    this.widgetTypeName,
  });

  final EdenSection508Severity severity;
  final EdenSection508Category category;
  final String description;
  final String? fixHint;
  final String? widgetTypeName;
}

/// State machine for [EdenSection508AuditController].
enum EdenSection508AuditState { idle, scanning, results }

/// Controller for [EdenSection508Audit] — drives state + issue list.
///
/// Library scope: STATE ONLY. Issue detection is out-of-scope; consumer
/// populates via [completeScan].
class EdenSection508AuditController extends ChangeNotifier {
  EdenSection508AuditState _state = EdenSection508AuditState.idle;
  List<EdenSection508Issue> _issues = const [];

  EdenSection508AuditState get state => _state;
  List<EdenSection508Issue> get issues => List.unmodifiable(_issues);

  /// Transition to [EdenSection508AuditState.scanning].
  void startScan() {
    _state = EdenSection508AuditState.scanning;
    notifyListeners();
  }

  /// Transition to [EdenSection508AuditState.results] with the given
  /// issue list. Consumer-supplied — library does not scan.
  void completeScan(List<EdenSection508Issue> issues) {
    _state = EdenSection508AuditState.results;
    _issues = List.of(issues);
    notifyListeners();
  }

  /// Reset back to [EdenSection508AuditState.idle] with empty issues.
  void reset() {
    _state = EdenSection508AuditState.idle;
    _issues = const [];
    notifyListeners();
  }
}

/// Section 508 / WCAG accessibility audit overlay — a dev-tools-style
/// primitive for surfacing detected issues in a floating panel.
///
/// Renders a floating bug-report button (bottom-right) that toggles an
/// audit panel showing severity counts, category filter chips, and an
/// expandable issue list with fix hints.
///
/// **Library scope: UI surface only.** Issue detection (walking the
/// widget tree, computing color contrast, checking tap-target sizes) is
/// out of scope. Consumer apps populate the [EdenSection508AuditController]
/// with hand-built or tool-detected issues.
///
/// Civilian re-use: generic a11y QA overlay for any consumer app, not
/// federal-specific.
class EdenSection508Audit extends StatefulWidget {
  const EdenSection508Audit({super.key, required this.controller});

  final EdenSection508AuditController controller;

  @override
  State<EdenSection508Audit> createState() => _EdenSection508AuditState();
}

class _EdenSection508AuditState extends State<EdenSection508Audit> {
  bool _panelOpen = false;
  final Set<EdenSection508Category> _hiddenCategories = {};
  int? _expandedIssueIndex;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
  }

  @override
  void didUpdateWidget(covariant EdenSection508Audit old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onChange);
      widget.controller.addListener(_onChange);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  void _toggle() => setState(() => _panelOpen = !_panelOpen);

  Color _severityColor(EdenSection508Severity s) {
    switch (s) {
      case EdenSection508Severity.error:
        return EdenColors.error;
      case EdenSection508Severity.warning:
        return EdenColors.warning;
      case EdenSection508Severity.info:
        return EdenColors.info;
    }
  }

  IconData _severityIcon(EdenSection508Severity s) {
    switch (s) {
      case EdenSection508Severity.error:
        return Icons.error_outline;
      case EdenSection508Severity.warning:
        return Icons.warning_amber_outlined;
      case EdenSection508Severity.info:
        return Icons.info_outline;
    }
  }

  Iterable<EdenSection508Issue> get _visibleIssues =>
      widget.controller.issues
          .where((i) => !_hiddenCategories.contains(i.category));

  ({int errors, int warnings, int info}) get _counts {
    var e = 0;
    var w = 0;
    var i = 0;
    for (final issue in _visibleIssues) {
      switch (issue.severity) {
        case EdenSection508Severity.error:
          e++;
        case EdenSection508Severity.warning:
          w++;
        case EdenSection508Severity.info:
          i++;
      }
    }
    return (errors: e, warnings: w, info: i);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            heroTag: 'edenSection508AuditFab',
            mini: true,
            onPressed: _toggle,
            tooltip: 'Section 508 audit',
            child: const Icon(Icons.bug_report_outlined),
          ),
        ),
        if (_panelOpen)
          Positioned(
            right: 16,
            bottom: 72,
            left: 16,
            top: 16,
            child: _buildPanel(context),
          ),
      ],
    );
  }

  Widget _buildPanel(BuildContext context) {
    final state = widget.controller.state;
    final counts = _counts;
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360, maxHeight: 480),
        child: Semantics(
          label: 'Section 508 audit panel',
          container: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.black87,
                child: Row(
                  children: [
                    const Flexible(
                      child: Text(
                        'Section 508 Audit',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (state == EdenSection508AuditState.results)
                      Flexible(
                        child: Text(
                          '${counts.errors} errors, ${counts.warnings} warnings, ${counts.info} info',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.white, size: 18),
                      onPressed: _toggle,
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),
              Flexible(child: _buildBody(state)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(EdenSection508AuditState state) {
    switch (state) {
      case EdenSection508AuditState.idle:
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('Tap Scan to begin audit'),
          ),
        );
      case EdenSection508AuditState.scanning:
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Scanning…'),
              ],
            ),
          ),
        );
      case EdenSection508AuditState.results:
        final allCategories = widget.controller.issues
            .map((i) => i.category)
            .toSet()
            .toList();
        final visible = _visibleIssues.toList();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (allCategories.length > 1)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    for (final cat in allCategories)
                      FilterChip(
                        label: Text(
                          cat.name,
                          style: const TextStyle(fontSize: 11),
                        ),
                        selected: !_hiddenCategories.contains(cat),
                        onSelected: (sel) {
                          setState(() {
                            if (sel) {
                              _hiddenCategories.remove(cat);
                            } else {
                              _hiddenCategories.add(cat);
                            }
                            // Reset expansion since indexes shift.
                            _expandedIssueIndex = null;
                          });
                        },
                      ),
                  ],
                ),
              ),
            if (visible.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No issues detected — clean audit.'),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: visible.length,
                  itemBuilder: (context, idx) {
                    final issue = visible[idx];
                    final expanded = _expandedIssueIndex == idx;
                    return Semantics(
                      label:
                          '${issue.severity.name} ${issue.category.name}: ${issue.description}',
                      child: ListTile(
                        leading: Icon(
                          _severityIcon(issue.severity),
                          color: _severityColor(issue.severity),
                        ),
                        title: Text(
                          issue.description,
                          style: const TextStyle(fontSize: 13),
                        ),
                        subtitle: expanded && issue.fixHint != null
                            ? Text(
                                'Fix: ${issue.fixHint}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              )
                            : null,
                        onTap: () => setState(() =>
                            _expandedIssueIndex = expanded ? null : idx),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
    }
  }
}
