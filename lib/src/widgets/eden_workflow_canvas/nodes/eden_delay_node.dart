// EdenDelayNode — workflow wait/delay card (donor DelayNode.tsx parity).
//
// Purple-themed card (160-200pt). Timer icon + "DELAY" uppercase + formatted
// wait-label (Nm/Nh/Nd). Tap to open popover with Delay Type select +
// conditional Minutes input.
//
// Parity rows N-5 / X-4.

import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';

import '../../eden_diagram/diagram_data.dart';

class EdenDelayNodeConfig {
  const EdenDelayNodeConfig({this.onUpdate, this.onDelete});

  /// Fires on Save with: `delayType` (String), `delayMinutes` (int),
  /// `delayConfig` (Map; preserves any non-minutes keys), `label`
  /// (formatted "Wait Nm/h/d" string).
  final ValueChanged<Map<String, dynamic>>? onUpdate;
  final VoidCallback? onDelete;
}

class EdenDelayNode extends StatefulWidget {
  const EdenDelayNode({
    super.key,
    required this.context,
    this.config = const EdenDelayNodeConfig(),
  });

  final EdenDiagramNodeContext context;
  final EdenDelayNodeConfig config;

  @override
  State<EdenDelayNode> createState() => _EdenDelayNodeState();
}

class _EdenDelayNodeState extends State<EdenDelayNode> {
  bool _hovered = false;

  bool get _isTouchPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  String get _delayType =>
      widget.context.node.data['delayType'] as String? ?? 'fixed';

  int get _delayMinutes =>
      (widget.context.node.data['delayMinutes'] as num?)?.toInt() ?? 30;

  Map<String, dynamic> get _delayConfig =>
      (widget.context.node.data['delayConfig'] as Map?)
          ?.cast<String, dynamic>() ??
      const <String, dynamic>{};

  String _delayLabel(String delayType, int minutes) {
    switch (delayType) {
      case 'fixed':
        if (minutes >= 1440) return 'Wait ${(minutes / 1440).round()}d';
        if (minutes >= 60) return 'Wait ${(minutes / 60).round()}h';
        return 'Wait ${minutes}m';
      case 'until_time':
        return 'Until time';
      case 'until_business_hours':
        return 'Until business hours';
      default:
        return 'Wait';
    }
  }

  Future<void> _openEditor() async {
    var newType = _delayType;
    var newMinutes = _delayMinutes;
    final minutesCtrl =
        TextEditingController(text: newMinutes.toString());
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (stateCtx, setStateLocal) => AlertDialog(
          title: const Text('Edit Delay'),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delay Type',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  initialValue: newType,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: 'fixed',
                      child: Text('Fixed Wait'),
                    ),
                    DropdownMenuItem(
                      value: 'until_time',
                      child: Text('Until Time'),
                    ),
                    DropdownMenuItem(
                      value: 'until_business_hours',
                      child: Text('Until Business Hours'),
                    ),
                  ],
                  onChanged: (v) => setStateLocal(() => newType = v ?? newType),
                ),
                if (newType == 'fixed') ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Minutes',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: minutesCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      final parsed = int.tryParse(v);
                      if (parsed != null) newMinutes = parsed;
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (saved == true) {
      final mins = int.tryParse(minutesCtrl.text) ?? newMinutes;
      widget.config.onUpdate?.call({
        'delayType': newType,
        'delayMinutes': mins,
        'delayConfig': {..._delayConfig, 'minutes': mins},
        'label': _delayLabel(newType, mins),
      });
    }
    Future.delayed(const Duration(milliseconds: 400), () {
      minutesCtrl.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final delayType = _delayType;
    final minutes = _delayMinutes;
    final isSelected = widget.context.selected;
    final isDropTarget = widget.context.dropTarget;
    final showDelete = _hovered || _isTouchPlatform;
    final label = _delayLabel(delayType, minutes);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _openEditor,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                constraints: const BoxConstraints(minWidth: 160, maxWidth: 200),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  border: Border.all(
                    color: isDropTarget
                        ? theme.colorScheme.tertiary
                        : isSelected
                            ? theme.colorScheme.primary
                            : Colors.purple.shade400,
                    width: (isSelected || isDropTarget) ? 2.5 : 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 6,
                      color: Color(0x14000000),
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: Colors.purple.shade700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DELAY',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.purple.shade700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (showDelete && widget.config.onDelete != null)
            Positioned(
              top: -8,
              right: -8,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: widget.config.onDelete,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border:
                          Border.all(color: Colors.red.shade400, width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      size: 14,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
