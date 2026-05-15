# Deferred / Out-of-Scope Items

## Wave 2 executor view (at Wave 2 start)

- `test/widgets/eden_detail_header_test.dart` + `test/widgets/_fixtures/eden_detail_page_scaffold_fixtures.dart` — compile errors referencing `EdenDetailPageScaffold` / `EdenDetailTab` symbols not yet exported. This is Wave 1 TRD-02's RED state (RED commit shipped, GREEN not yet landed). Owned by parallel Wave 1 executor; out of scope for Wave 2. **RESOLVED 2026-05-15** — Wave 1 GREEN landed (commits `a3691bd`, `38382de`).

These were not regressions caused by Wave 2 changes.

## Wave 1 executor view (at Wave 1 close, 2026-05-15)

### `eden_network_status_bar_test.dart` (Wave 2 / TRD 001-08) — intermittent pumpAndSettle timeouts

**Observed:** Full-repo `flutter test` intermittently reports 1-2 failures with `pumpAndSettle timed out` in tests for `EdenNetworkStatusBar` (`status=reconnecting renders amber banner...`, `state transition online → offline animates in via SlideTransition`).

**Root cause:** The `reconnecting` state renders an indeterminate spinner that never settles, so `await tester.pumpAndSettle()` times out instead of returning. Likely fixes:
- Pump fixed-time frames (`await tester.pump(const Duration(milliseconds: 100))`) instead of `pumpAndSettle()`, or
- Swap the spinner for a non-animating placeholder in the test wrap.

**Scope:** file owned by the parallel Wave 2 executor (commit `faa95d7 test(001-08): RED — EdenNetworkStatusBar fixture + 8 failing widget tests`). Wave 2's in-flight RED — NOT a Wave 1 deviation.

**Wave 1 scope verified independent:** `flutter test test/widgets/eden_list_page_scaffold_test.dart test/widgets/eden_detail_header_test.dart test/widgets/eden_detail_page_scaffold_test.dart test/widgets/map_providers/eden_map_provider_test.dart` → 42 / 42 pass deterministically.
