---
objective: 024
status: passed
verified: 2026-10-09
branch: feat/intent-composition
base: feat/card-proposal (832f990)
commits: 6
---

# Objective 024 — verification

## Definition of done, item by item

| # | Must have | Evidence | Verdict |
|---|---|---|---|
| 1 | A raw fixture payload to ONE entry point gives the right widget, for all 14 | dispatcher case 1 (5 built ids render, asserted on painted text) + case 2 (all 14 dispatch; the 5 unbuilt land on an `EdenRefusal` that NAMES the id; `refusals == 5` so the loop cannot pass covering none) | ✓ |
| 2 | Unknown id, malformed payload, missing host field each refuse naming the cause; none throws, none guesses | decoder cases 9–15, dispatcher cases 3, 4, 8, 9. Nothing throws: decoder case 8 wraps all 14 in try/catch and asserts the catch list is empty | ✓ |
| 3 | Factory map key set == `kDataDisplayComponents` | dispatcher case 5, asserted BOTH directions with the difference named; case 6 does the same for builders vs decoders | ✓ |
| 4 | Vendored set hash gated against `9c4520d9…` | fixture cases 3 and 4 — two assertions, neither detecting the other's failure | ✓ |
| 5 | No path binds an action to a route | dispatcher case 13, a source scan of `lib/src/agent_intent/` (a behavioural test cannot prove a path's absence). Case 14 does the same for fetching | ✓ |
| 6 | Full suite green, custom_lint 0, CI dispatch green | local all green (below); **CI dispatch NOT YET RUN — needs a push, which was not authorised** | ◆ partial |

## Local gates

```
flutter test                    exit 0   5142 pass / 67 skip   (was 5096 at branch point, +46)
dart run custom_lint            exit 0   no issues
lints/ dart test                exit 0   the design rules' own tests
tool/lint_gate_assert.sh        exit 0   the gate still fires on the deliberate probe
flutter analyze <this objective> exit 0  0 issues across test/fixtures,
                                         lib/src/agent_intent, test/agent_intent
```

## Differential controls — 7 run, every one reverted with zero diff

| probe | expected | actual |
|---|---|---|
| one byte changed in fixture 11 | 2, 3 fail; 4 passes | as expected — **my TRD predicted 4 would also fail; it was wrong** |
| manifest `set_sha256` zeroed | 3, 4 fail; 2 passes | as expected |
| unknown id falls back to a decoder | case 9 alone | as expected |
| `_int` coerces a numeric String | case 11 alone | as expected |
| missing required string defaults to `''` | case 10 alone | as expected |
| `currencyCode` defaults to USD | case 8 alone | as expected — the highest-value control here |
| a route binding added to the layer | case 13 alone | as expected (first attempt silently failed to apply — zsh ate a backtick; the assertion caught it) |
| one builder removed from the map | case 5 alone | **cases 1, 5, 6, 7, 8 — my prediction was too narrow** |

Two predictions were wrong and are recorded as wrong. A control whose
expectation is edited afterwards to match the result is not a control.

## What the objective found that it did not set out to find

- **Case 8 of the decoder caught its own author.** It first asserted all 14
  recordings decode, on the premise that every recorded `component_id` is
  renderable. False — the 14 span TEN ids and five have no renderer, which
  the epic already said. The test now pins the partition both ways and is
  meant to break when component six lands.
- **DoD item 1 was under-tested by my own case 2**, which asserted only
  "nothing throws". An empty box throws nothing. Strengthened in dd4e808.
- **Five analyzer infos survived the first fix** because I scoped the check
  to where I expected findings. Cleared in a27bba9.

## Deliberate non-goals, confirmed absent

Components 6–10; any eden-biz change; the theme fix (#71); the stacked-PR CI
fix (#70); any network client. `grep` for `http`/`Navigator` in the layer
returns nothing, asserted by cases 13 and 14 rather than by this sentence.

## Honest residuals

1. **CI has not run.** A stacked PR triggers zero checks (#70), so the only
   real signal is a manual `gh workflow run ci.yml --ref feat/intent-composition`.
   That needs the branch pushed, which has not been authorised.
2. **`scheduler_performance_test` failed on 2 of ~9 full-suite runs** — a
   200ms wall-clock budget for 500 events, in a subsystem this branch does
   not touch, passing in isolation and on the other 7 runs. Load-sensitive,
   not caused here, but a real CI flake risk and not dismissed.
3. **The host context pushes two unverifiable claims onto the caller.**
   `currencyCode` and `proposalSubject` are supplied by the host and nothing
   can check them against the proposal they describe. That is the stopgap
   working as designed; the fix is eden-biz#860 and #863.
4. **Nothing on the eden-biz side sends an intent to a UI yet.** This layer
   can now receive one. The producer half is not built and is not in scope.
