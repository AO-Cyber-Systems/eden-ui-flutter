// EdenPersonaSelector — compact dropdown for picking active AI persona.
//
// Library version is Riverpod-free per OBJECTIVE.md Constraint 4. The donor
// `PersonaSelector` was a `ConsumerWidget` reading/writing
// `activePersonaProvider`; the library version exposes `activePersona` and
// `onChanged` props so consumers wire Riverpod (or any other state) externally.

import 'package:flutter/material.dart';

import 'eden_ai_models.dart';

/// Compact dropdown pill for switching the active AI persona in a chat header.
///
/// Renders the active persona as a colored pill (icon + label + dropdown
/// arrow). Tap the pill to open a `PopupMenu` listing all four
/// [EdenAiPersona] values; the active row has a trailing check icon and bold
/// label. Selecting a row fires [onChanged].
///
/// **Riverpod-free design:** the donor reads/writes `activePersonaProvider`
/// inside `ConsumerWidget`. The library version is a [StatelessWidget] with
/// `activePersona` + `onChanged` props — consumers own state externally.
///
/// Cross-vertical examples:
/// - Trades chat header (current donor use case).
/// - Salon admin chat (booking-context persona switch).
/// - Medical: clinician vs admin chat persona.
/// - Legal: paralegal vs partner persona.
///
/// Donor: `trades-flutter/lib/shared/widgets/persona_selector.dart`.
class EdenPersonaSelector extends StatelessWidget {
  const EdenPersonaSelector({
    super.key,
    required this.activePersona,
    required this.onChanged,
    this.tooltip = 'Switch persona',
  });

  /// Currently active persona (drives pill display + check icon in dropdown).
  final EdenAiPersona activePersona;

  /// Called when the user selects a different persona from the dropdown.
  final ValueChanged<EdenAiPersona> onChanged;

  /// Tooltip on the [PopupMenuButton] (defaults to `'Switch persona'`).
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopupMenuButton<EdenAiPersona>(
      tooltip: tooltip,
      offset: const Offset(0, 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: theme.colorScheme.surface,
      onSelected: onChanged,
      itemBuilder: (context) {
        return EdenAiPersona.values.map((persona) {
          final isActive = persona == activePersona;
          return PopupMenuItem<EdenAiPersona>(
            value: persona,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(persona.icon, size: 16, color: persona.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    persona.displayLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (isActive)
                  Icon(Icons.check, size: 14, color: persona.color),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: activePersona.color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(activePersona.icon, size: 12, color: activePersona.color),
            const SizedBox(width: 4),
            Text(
              activePersona.displayLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: activePersona.color,
              ),
            ),
            Icon(Icons.arrow_drop_down,
                size: 14, color: activePersona.color),
          ],
        ),
      ),
    );
  }
}
