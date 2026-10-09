---
number: 024
name: Agent-intent composition layer
slug: agent-intent-composition-layer
status: in_progress
mode: quick-build
tdd: required
roadmap: none (quick-build; roadmap deliberately untouched)
branch: feat/intent-composition
base: feat/card-proposal (832f990)
tracks: eden-ui-flutter#50
---

# Objective 024: Agent-intent composition layer

## Goal

Turn five rendered widgets into something a headless agent can actually
drive. Today every component takes typed Dart data and a human writes
`EdenServiceList(data: …)` by hand. After this objective a caller hands an
agent's wire payload `{component_id, data, actions}` to one entry point and
gets a correct widget or an honest refusal.

## Why this before components 6-10

`kDataDisplayComponents` pairs a `component_id` with a Dart `Type`. A `Type`
cannot be constructed without reflection and AOT Flutter has none, so that
list can DETECT an unknown id and can never RENDER a known one. Five more
components first would mean ten things nothing can call.

## BINDING CONTRACT — every TRD and every reviewer brief repeats this

1. **The renderer never fetches.** Everything drawn comes from the payload.
   No repository, no provider, no future anywhere in this layer.
2. **Affordances are granted by the payload.** A control exists only when
   `intent.actions` carries its id. Empty actions = read-only, which is
   correct and not degraded.
3. **Actions bind to tool ids or proposal ids, NEVER to routes.** A route
   binding would be an authorization bypass.
4. **Refusal is one-sided** — zero actions, and it carries a reason.
5. **Anything this layer cannot do honestly becomes a refusal** — never a
   guess, never a crash. Unknown id, malformed data, missing required field,
   missing caller context: all refuse with a reason naming the cause.
6. **§22** — a check whose failure mode is indistinguishable from its success
   mode is not a check.

## TRDs

| # | TRD | type | depends |
|---|---|---|---|
| 024-01 | Vendored fixtures + set-hash drift gate | tdd | — |
| 024-02 | `EdenAgentIntent` envelope + per-component decoders | tdd | 024-01 |
| 024-03 | Dispatcher factory + host context + action egress | tdd | 024-02 |

## Out of scope

- Components 6-10 (`detail/appointment`, `detail/customer-history`,
  `list/availability-slots`, `summary/scheduling`, `summary/pipeline`).
- Any eden-biz change. The two schema gaps stay filed (#860, #863).
- The theme contrast fix (#71) — lands alone.
- Fixing #70 (stacked PRs run no CI) — a gate change lands alone.
- Any network, HTTP or MCP client. This layer never fetches.

## Definition of done

1. A caller hands a raw fixture payload to one entry point and gets the right
   widget — proven for all 14 vendored fixtures.
2. An unknown `component_id`, a malformed payload, and a missing
   host-context field each produce a refusal naming the cause. None throws,
   none guesses.
3. The factory map's key set is asserted EQUAL to `kDataDisplayComponents`.
4. The vendored fixture set hash is gated against `9c4520d9…`.
5. No path in this layer binds an action to a route, proven by a test.
6. Full suite green, `custom_lint` exit 0, manual CI dispatch green.
