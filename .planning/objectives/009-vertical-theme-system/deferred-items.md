# Deferred items discovered during objective 009 execution

## Pre-existing test failures NOT caused by objective 009

### test/widgets/eden_card_interactive_test.dart — 14 tests fail
- **Root cause:** test file references `EdenCard.interactive(...)` constructor that does not exist in `lib/src/widgets/eden_card.dart`
- **Origin commit:** f69221b — `test(010-07): add failing EdenCard.interactive test list including WRONG-TAP isolation`
- **Verified pre-existing:** `git stash` of all 009 work → `flutter test test/widgets/eden_card_interactive_test.dart` still fails identically
- **Scope:** belongs to objective 010 (Eden Visual Polish Pass), specifically TRD 010-07 which planted the RED tests but has not yet GREENed them. Out of scope for objective 009 per scope-boundary rule.
- **Action:** none — leave for objective 010 executor to GREEN.

## Notes
- All other 1874+ widget tests pass GREEN after objective 009 lands.
- The objective 009 contract (back-compat: no existing test modified) is honored — none of the 14 failures are caused by changes in this objective.
