import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../tokens/radii.dart';
import '../../eden_diagram/eden_diagram_exports.dart';
import '../process_models.dart';
import 'eden_process_node_renderer.dart';

/// Process-flow Phase node — parity row N-3.
///
/// Renders a 200-280pt wide structural card with:
/// - Header: chevron (toggle expand) + Layers icon + inline-editable display
///   name + milestone Flag indicator (when `phase.isMilestone == true`) +
///   hover-show edit + delete buttons.
/// - Body collapsed: group count + task count badges (or 'No tasks' italic
///   when both empty).
/// - Body expanded: per-group rows with `groupName  (N tasks)` summary
///   (read-only; full editing lives in the editor dialogs — TRD 006-10).
///
/// **Drop target ring:** when `context.dropTarget == true`, the border switches
/// to `theme.colorScheme.primary` at 2pt (parity row D-2 rendered side).
///
/// **Selection ring:** when `context.selected == true`, border widens to 2pt
/// using the phase color palette.
///
/// **Inline rename:** tapping the display-name `Text` swaps it for a
/// `TextField`. Enter saves; Esc cancels; blur saves when the trimmed value
/// is non-empty AND different from the current name (otherwise silent
/// cancel). Hands the new name back via `config.onUpdatePhase(phaseId,
/// {'displayName': trimmed})`.
///
/// Phase data is resolved via `config.phasesById[phaseId]`. A red
/// `Missing phase {id}` fallback renders when the lookup fails (defensive
/// against canvas-rebuild race conditions; not expected in normal flow).
class EdenProcessPhaseNode extends StatefulWidget {
  const EdenProcessPhaseNode({
    super.key,
    required this.context,
    required this.config,
  });

  final EdenDiagramNodeContext context;
  final EdenProcessNodeRendererConfig config;

  @override
  State<EdenProcessPhaseNode> createState() => _EdenProcessPhaseNodeState();
}

class _EdenProcessPhaseNodeState extends State<EdenProcessPhaseNode> {
  bool _hovered = false;
  bool _editing = false;
  late TextEditingController _nameCtrl;
  final FocusNode _nameFocus = FocusNode();

  int get _phaseId => widget.context.node.data['phaseId'] as int;
  EdenProcessPhase? get _phase => widget.config.phasesById[_phaseId];
  bool get _expanded => widget.config.expandedPhaseIds.contains(_phaseId);

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: _phase?.displayName ?? '');
    _nameFocus.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _nameFocus.removeListener(_onFocusChange);
    _nameCtrl.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_nameFocus.hasFocus && _editing) {
      _commit(save: true);
    }
  }

  void _enterEdit() {
    setState(() {
      _nameCtrl.text = _phase?.displayName ?? '';
      _editing = true;
    });
    Future.microtask(() {
      if (mounted) _nameFocus.requestFocus();
    });
  }

  void _commit({required bool save}) {
    if (save) {
      final trimmed = _nameCtrl.text.trim();
      if (trimmed.isNotEmpty && trimmed != _phase?.displayName) {
        widget.config.onUpdatePhase?.call(_phaseId, {'displayName': trimmed});
      }
    }
    if (mounted) setState(() => _editing = false);
  }

  static const Map<String, ({Color border, Color fillLight, Color fillDark})>
      _phasePalettes = {
    'blue': (
      border: Color(0xFF3B82F6),
      fillLight: Color(0xFFEFF6FF),
      fillDark: Color(0xFF1E3A8A),
    ),
    '#3B82F6': (
      border: Color(0xFF3B82F6),
      fillLight: Color(0xFFEFF6FF),
      fillDark: Color(0xFF1E3A8A),
    ),
    'green': (
      border: Color(0xFF10B981),
      fillLight: Color(0xFFECFDF5),
      fillDark: Color(0xFF064E3B),
    ),
    '#10B981': (
      border: Color(0xFF10B981),
      fillLight: Color(0xFFECFDF5),
      fillDark: Color(0xFF064E3B),
    ),
    'amber': (
      border: Color(0xFFF59E0B),
      fillLight: Color(0xFFFFFBEB),
      fillDark: Color(0xFF78350F),
    ),
    '#F59E0B': (
      border: Color(0xFFF59E0B),
      fillLight: Color(0xFFFFFBEB),
      fillDark: Color(0xFF78350F),
    ),
    'red': (
      border: Color(0xFFEF4444),
      fillLight: Color(0xFFFEF2F2),
      fillDark: Color(0xFF7F1D1D),
    ),
    '#EF4444': (
      border: Color(0xFFEF4444),
      fillLight: Color(0xFFFEF2F2),
      fillDark: Color(0xFF7F1D1D),
    ),
    'purple': (
      border: Color(0xFF8B5CF6),
      fillLight: Color(0xFFF5F3FF),
      fillDark: Color(0xFF4C1D95),
    ),
    '#8B5CF6': (
      border: Color(0xFF8B5CF6),
      fillLight: Color(0xFFF5F3FF),
      fillDark: Color(0xFF4C1D95),
    ),
    'pink': (
      border: Color(0xFFEC4899),
      fillLight: Color(0xFFFDF2F8),
      fillDark: Color(0xFF831843),
    ),
    '#EC4899': (
      border: Color(0xFFEC4899),
      fillLight: Color(0xFFFDF2F8),
      fillDark: Color(0xFF831843),
    ),
    'cyan': (
      border: Color(0xFF06B6D4),
      fillLight: Color(0xFFECFEFF),
      fillDark: Color(0xFF164E63),
    ),
    '#06B6D4': (
      border: Color(0xFF06B6D4),
      fillLight: Color(0xFFECFEFF),
      fillDark: Color(0xFF164E63),
    ),
    'gray': (
      border: Color(0xFF6B7280),
      fillLight: Color(0xFFF9FAFB),
      fillDark: Color(0xFF1F2937),
    ),
    '#6B7280': (
      border: Color(0xFF6B7280),
      fillLight: Color(0xFFF9FAFB),
      fillDark: Color(0xFF1F2937),
    ),
  };

  ({Color border, Color fill}) _resolveColors(BuildContext context) {
    final colorHint = _phase?.color;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = (colorHint != null ? _phasePalettes[colorHint] : null) ??
        _phasePalettes['blue']!;
    return (
      border: palette.border,
      fill: isDark ? palette.fillDark : palette.fillLight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final phase = _phase;
    if (phase == null) return _MissingPhaseFallback(phaseId: _phaseId);

    final theme = Theme.of(context);
    final colors = _resolveColors(context);
    final groupCount = phase.groups.length;
    final taskCount =
        phase.groups.fold<int>(0, (acc, g) => acc + g.tasks.length);
    final isDropTarget = widget.context.dropTarget;
    final isSelected = widget.context.selected;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        constraints: const BoxConstraints(minWidth: 200, maxWidth: 280),
        decoration: BoxDecoration(
          color: colors.fill,
          borderRadius: EdenRadii.borderRadiusLg,
          border: Border.all(
            color: isDropTarget ? theme.colorScheme.primary : colors.border,
            width: isDropTarget || isSelected ? 2 : 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context, phase, theme),
            _buildBody(context, phase, theme, groupCount, taskCount),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    EdenProcessPhase phase,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () =>
                widget.config.onTogglePhaseExpanded?.call(_phaseId),
            child: Icon(
              _expanded ? Icons.expand_more : Icons.chevron_right,
              size: 18,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.layers,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _editing
                ? _buildEditField(theme)
                : GestureDetector(
                    onTap: _enterEdit,
                    child: Text(
                      phase.displayName,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
          ),
          if (phase.isMilestone)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(
                Icons.flag,
                size: 14,
                color: Colors.amber.shade700,
              ),
            ),
          AnimatedOpacity(
            opacity: _hovered ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 120),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  tooltip: 'Edit phase',
                  visualDensity: VisualDensity.compact,
                  onPressed: () =>
                      widget.config.onOpenPhaseEditor?.call(_phaseId),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 14),
                  color: theme.colorScheme.error,
                  tooltip: 'Delete',
                  visualDensity: VisualDensity.compact,
                  onPressed: () =>
                      widget.config.onDeletePhase?.call(_phaseId),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditField(ThemeData theme) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            _commit(save: true);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            _commit(save: false);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: TextField(
        controller: _nameCtrl,
        focusNode: _nameFocus,
        style: theme.textTheme.bodyMedium
            ?.copyWith(fontWeight: FontWeight.w600),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    EdenProcessPhase phase,
    ThemeData theme,
    int groupCount,
    int taskCount,
  ) {
    if (!_expanded) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            if (groupCount > 0)
              _Badge(
                label: '$groupCount ${groupCount == 1 ? 'group' : 'groups'}',
              ),
            if (taskCount > 0)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: _Badge(
                  label: '$taskCount ${taskCount == 1 ? 'task' : 'tasks'}',
                ),
              ),
            if (groupCount == 0 && taskCount == 0)
              Text(
                'No tasks',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (phase.groups.isEmpty)
            Text(
              'No task groups yet',
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            ...phase.groups.map((g) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: theme.textTheme.bodySmall,
                      children: [
                        TextSpan(
                          text: g.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(
                          text: '  (${g.tasks.length} tasks)',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: EdenRadii.borderRadiusSm,
      ),
      child: Text(label, style: theme.textTheme.labelSmall),
    );
  }
}

class _MissingPhaseFallback extends StatelessWidget {
  const _MissingPhaseFallback({required this.phaseId});

  final int phaseId;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red),
          color: Colors.red.shade50,
        ),
        padding: const EdgeInsets.all(4),
        child: Text(
          'Missing phase $phaseId',
          style: const TextStyle(fontSize: 10, color: Colors.red),
        ),
      );
}
