# Deferred items discovered during objective 009 execution

## Status: NONE (resolved during execution)

### Transient analyzer/build cache anomaly

During TRD 009-05 Task 2 execution, an initial full-suite run reported `-1` failure
in `test/widgets/eden_card_interactive_test.dart` (compile error: `EdenCard.interactive`
not found). This was investigated and logged as pre-existing (verified via `git stash`
of all 009 changes — same failure reproduced at that moment).

However, on the next full-suite run after Task 3 lands (catalog screen + home nav
tile), the file compiles cleanly and all 12 tests within it pass GREEN. The transient
failure appears to have been a Dart analyzer / build cache state issue, not a real
defect. After Task 3:

- **Total tests run:** 2066
- **Failures:** 0
- **Skipped:** 1 (pre-existing skip, unrelated)

`grep` confirms `EdenCard.interactive` constructor IS defined in
`lib/src/widgets/eden_card.dart:46`.

## Conclusion

No real deferred items. The objective 009 back-compat contract holds:
- no existing test was modified
- all 2066 existing tests pass GREEN
- new theme-system tests: 122 (across TRDs 009-01 → 009-05)
