import 'package:flutter/material.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// One entry inside an [EdenSplitButton]'s dropdown menu.
class EdenSplitMenuItem {
  const EdenSplitMenuItem({
    required this.label,
    required this.onSelected,
    this.icon,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onSelected;
  final IconData? icon;
  final bool enabled;
}

/// M3 Expressive split-button — primary action on the left + dropdown menu
/// trigger on the right, visually connected as one cluster.
///
/// Canonical use case: "Save" as primary action with "Save & New" /
/// "Save & Close" in the dropdown menu.
///
/// State-agnostic: caller supplies [onPrimary] and per-item [EdenSplitMenuItem.onSelected]
/// callbacks. Library never owns selection state.
///
/// Usage:
/// ```dart
/// EdenSplitButton(
///   primaryLabel: 'Save',
///   onPrimary: _save,
///   menuItems: [
///     EdenSplitMenuItem(label: 'Save & New', onSelected: _saveAndNew),
///     EdenSplitMenuItem(label: 'Save & Close', onSelected: _saveAndClose),
///   ],
/// )
/// ```
class EdenSplitButton extends StatelessWidget {
  const EdenSplitButton({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    required this.menuItems,
    this.primaryIcon,
  });

  final String primaryLabel;
  final VoidCallback? onPrimary;
  final List<EdenSplitMenuItem> menuItems;
  final IconData? primaryIcon;

  bool get _primaryEnabled => onPrimary != null;
  bool get _dropdownEnabled => menuItems.any((m) => m.enabled);

  Future<void> _openMenu(BuildContext context) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    final btn = context.findRenderObject() as RenderBox?;
    if (overlay == null || btn == null) return;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        btn.localToGlobal(btn.size.bottomLeft(Offset.zero), ancestor: overlay),
        btn.localToGlobal(btn.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );
    final selected = await showMenu<int>(
      context: context,
      position: position,
      items: [
        for (int i = 0; i < menuItems.length; i++)
          PopupMenuItem<int>(
            value: i,
            enabled: menuItems[i].enabled,
            child: Row(
              children: [
                if (menuItems[i].icon != null) ...[
                  Icon(menuItems[i].icon, size: 18),
                  const SizedBox(width: EdenSpacing.space2),
                ],
                Text(menuItems[i].label),
              ],
            ),
          ),
      ],
    );
    if (selected != null && menuItems[selected].enabled) {
      menuItems[selected].onSelected();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryBg = theme.colorScheme.primary;
    final primaryFg = theme.colorScheme.onPrimary;
    final disabledOpacityPrimary = _primaryEnabled ? 1.0 : 0.4;
    final disabledOpacityDropdown = _dropdownEnabled ? 1.0 : 0.4;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Primary segment — Flexible so long labels ellipsize within available
        // width instead of forcing horizontal overflow on narrow viewports.
        Flexible(child: Semantics(
          button: true,
          enabled: _primaryEnabled,
          label: primaryLabel,
          container: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _primaryEnabled ? onPrimary : null,
            child: ExcludeSemantics(child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(
                horizontal: EdenSpacing.space4,
                vertical: EdenSpacing.space2,
              ),
              decoration: BoxDecoration(
                color: primaryBg.withValues(alpha: disabledOpacityPrimary),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(EdenRadii.lg),
                  bottomLeft: Radius.circular(EdenRadii.lg),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (primaryIcon != null) ...[
                    Icon(primaryIcon, size: 18, color: primaryFg),
                    const SizedBox(width: EdenSpacing.space2),
                  ],
                  Flexible(
                    child: Text(
                      primaryLabel,
                      style: theme.textTheme.labelLarge?.copyWith(color: primaryFg),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            )),
          ),
        )),
        // 1-pixel divider seam between segments
        Container(
          width: 1,
          height: 44,
          color: theme.colorScheme.onPrimary.withValues(alpha: 0.25),
        ),
        // Dropdown segment
        Builder(builder: (innerContext) {
          return Semantics(
            button: true,
            enabled: _dropdownEnabled,
            label: 'More actions',
            container: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _dropdownEnabled ? () => _openMenu(innerContext) : null,
              child: ExcludeSemantics(child: Container(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 44),
                padding: const EdgeInsets.symmetric(
                  horizontal: EdenSpacing.space2,
                  vertical: EdenSpacing.space2,
                ),
                decoration: BoxDecoration(
                  color: primaryBg.withValues(alpha: disabledOpacityDropdown),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(EdenRadii.lg),
                    bottomRight: Radius.circular(EdenRadii.lg),
                  ),
                ),
                child: Icon(Icons.arrow_drop_down, color: primaryFg, size: 24),
              )),
            ),
          );
        }),
      ],
    );
  }
}
