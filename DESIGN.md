# Eden UI — Design Tokens

This file is the **token reference** for `package:eden_ui_flutter`: the colour, type
scale, spacing and radii values the widgets actually use, generated straight from
`lib/src/tokens/*.dart` so it can never quietly drift from the code.

Design **rules** — when to use which token, layout conventions, interaction
patterns — live elsewhere, not here:

- DevFlow's `design-stack-flutter.md`
- this objective's `design/patterns/` (23-09)

## Token tables

The table below the marker is generated. Do not hand-edit it — a
`flutter test` gate (`test/design/design_md_fresh_test.dart`) fails if it drifts
from `lib/src/tokens/`.

<!-- BEGIN GENERATED TOKENS — do not edit by hand; run: flutter test tool/gen_design_md.dart -->

## Colors

| Token | Value |
|---|---|
| `gold` | `0xFFD4A853` |
| `blue` | `0xFF3B82F6` |
| `emerald` | `0xFF10B981` |
| `purple` | `0xFFA855F7` |
| `red` | `0xFFEF4444` |
| `slate` | `0xFF64748B` |
| `neutral` | `0xFF71717A` |
| `success` | `0xFF10B981` |
| `successBg` | `0x1A10B981` |
| `warning` | `0xFFF59E0B` |
| `warningBg` | `0x1AF59E0B` |
| `error` | `0xFFEF4444` |
| `errorBg` | `0x1AEF4444` |
| `info` | `0xFF3B82F6` |
| `infoBg` | `0x1A3B82F6` |
| `auroraPurple` | `0xFFA855F7` |
| `auroraBlue` | `0xFF3B82F6` |
| `auroraCyan` | `0xFF06B6D4` |
| `auroraEmerald` | `0xFF10B981` |
| `cyan` | `0xFF06B6D4` |

## Type scale

| Token | Value |
|---|---|
| `displayLarge` | `48px, w800, line-height 1.1 (Outfit)` |
| `displayMedium` | `36px, w700, line-height 1.2 (Outfit)` |
| `displaySmall` | `30px, w700, line-height 1.2 (Outfit)` |
| `headlineLarge` | `24px, w700, line-height 1.3 (Outfit)` |
| `headlineMedium` | `20px, w600, line-height 1.3 (Outfit)` |
| `headlineSmall` | `18px, w600, line-height 1.4 (Outfit)` |
| `bodyLarge` | `16px, w400, line-height 1.6 (PlusJakartaSans)` |
| `bodyMedium` | `14px, w400, line-height 1.5 (PlusJakartaSans)` |
| `bodySmall` | `12px, w400, line-height 1.5 (PlusJakartaSans)` |
| `labelLarge` | `14px, w600, line-height 1.4 (PlusJakartaSans)` |
| `labelMedium` | `12px, w600, line-height 1.4 (PlusJakartaSans)` |
| `labelSmall` | `11px, w500, line-height 1.4 (PlusJakartaSans)` |
| `codeLarge` | `15px, w400, line-height 1.6 (JetBrainsMono)` |
| `codeMedium` | `13px, w400, line-height 1.5 (JetBrainsMono)` |
| `codeSmall` | `12px, w400, line-height 1.5 (JetBrainsMono)` |

## Spacing

| Token | Value |
|---|---|
| `space0` | `0` |
| `space1` | `4` |
| `space2` | `8` |
| `space3` | `12` |
| `space4` | `16` |
| `space5` | `20` |
| `space6` | `24` |
| `space8` | `32` |
| `space10` | `40` |
| `space12` | `48` |
| `space16` | `64` |
| `space20` | `80` |

## Radii

| Token | Value |
|---|---|
| `sm` | `6` |
| `md` | `8` |
| `lg` | `12` |
| `xl` | `16` |
| `xxl` | `24` |
| `full` | `9999` |

_Not generated: shadows, springs (structured values)._

<!-- END GENERATED TOKENS -->

## Adding a token

1. Edit the Dart source in `lib/src/tokens/` (add/change the `static const`
   declaration).
2. Regenerate this file: `flutter test tool/gen_design_md.dart`.
3. Commit both the token file and the regenerated `DESIGN.md` together.

Forgetting step 2 fails `test/design/design_md_fresh_test.dart` in CI, naming the
stale file and the regeneration command.
