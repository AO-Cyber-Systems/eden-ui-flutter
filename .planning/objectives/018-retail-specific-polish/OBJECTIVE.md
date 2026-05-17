---
objective: 018-retail-specific-polish
kind: ui-lib
work: feature
status: planned
estimated_effort: 1.5-2 weeks Claude execution
trd_count: 6
waves: 2
---

# Objective 018 — Retail-Specific Polish (Square-Parity Wave 1)

## Goal

Close the **highest-criticality remaining gaps** in the retail UI surface area per `USE_CASES_RETAIL_2026-05-17.md` §0 + §5 — the cluster of L1 / L2 "hard blocker" and "soft blocker" widgets that obj 014 explicitly punted as `out of scope`, plus the catalog adjacencies that the parity reference (§3.1) flags as **`✗` missing** vs Square / Shopify / Lightspeed / Clover. After this objective ships:

- A cashier opens a **loyalty member profile** with tier badge + points balance + recent purchases + birthday-promo callout via `EdenLoyaltyMemberDetail` (was deferred from obj 014 per `OBJECTIVE.md` "out of scope" §6 — UC-25 + UC-26).
- A cashier looks up a customer's **store-credit balance + history + holds** via `EdenStoreCreditLedger` (UC-27 — currently zero coverage).
- A cashier looks up a **gift-card balance + last-N activity** via `EdenGiftCardBalanceLookup` (UC-28 + UC-09 balance-pre-apply affordance).
- A cashier walks a multi-step **refund flow** (scan/lookup sale → select line items → method picker → manager-override capture) via `EdenRefundFlow` (was deferred from obj 014 — UC-04 hard blocker).
- A cashier walks a **layaway lifecycle** (deposit → installments → release / cancel → customer notifications) via `EdenLayawayFlow` (UC-06 — Lightspeed-marketed pillar).
- An inventory specialist walks an **inter-location stock transfer** (source/dest + items + shipping → in-transit / received) via `EdenStoreTransfer` (UC-16 — Square + Shopify + Lightspeed all market as pillar).

These six widgets close UC-04 + UC-06 + UC-16 + UC-25 + UC-26 + UC-27 + UC-28 from the use-cases inventory and bring Eden's Cluster 1 (Checkout / POS) from 30% canonical → ~55%; Cluster 2 (Inventory mgmt) from 38% → ~50%; Cluster 4 (Customer / loyalty) from 0% → ~60%. Square-parity envelope on the headline gaps with the deepest customer-impact (refunds + customer detail + store credit + gift card balance).

**Backend codegen, transport, and orchestration belong in `eden-biz-flutter` / `eden-platform-flutter`, not here.** Per `eden-libs/CLAUDE.md`: "Keep platform logic in `eden-platform-flutter`, not in `eden-ui-flutter`."

## Why now

- **Refund flow + customer detail + store credit are L1 hard blockers** per `USE_CASES_RETAIL_2026-05-17.md` §0. Every retail store has refunds Day 1; loyalty profile lookup is 30-60% of transactions; store credit is Day 1 for no-receipt returns. obj 014 explicitly deferred `EdenLoyaltyMemberDetail` + `EdenRefundFlow` as `out of scope` — this objective closes those two punted commitments.
- **Gift-card balance + layaway + store-transfer are L2 soft blockers** per the same source. Each has explicit competitor parity gaps in §3.1 (`✗` vs Square / Shopify / Lightspeed marked widgets).
- **All 6 compose extensively from obj 012 + obj 014 + obj 001 primitives.** Heavy reuse — every widget composes ≥3 existing primitives. Lowest risk gap-closure objective in the retail roadmap because the foundation is already shipped.
- **Cross-vertical reuse beyond retail.**
  - `EdenLoyaltyMemberDetail` → salon membership profile, fuel fleet-account profile, medical patient summary card, trades customer-of-record detail (generic loyalty/tier/history pattern).
  - `EdenStoreCreditLedger` → trades customer-credit / deposits ledger, salon prepaid-package balance, fuel customer-account credit.
  - `EdenGiftCardBalanceLookup` → fuel fleet-card lookup, salon prepaid-card lookup, medical FSA/HSA card lookup, gov benefit-card lookup.
  - `EdenRefundFlow` → trades invoice-refund, salon service-refund, fuel delivery-refund, medical claim-reversal (same multi-step shape).
  - `EdenLayawayFlow` → trades deposit-on-quote, salon prepaid-package install, medical payment-plan lifecycle.
  - `EdenStoreTransfer` → trades truck-to-truck inventory transfer, salon back-bar transfer, fuel parts-truck transfer, gov supply-depot transfer.
- **Theme-profile aware (`retailVibrant`)** via obj 009 — widgets read theme via `Theme.of(context)`, never hard-code retail palettes.

## Components in scope

| TRD | Widget | Composes | Wave |
|---|---|---|---|
| 018-01 | `EdenLoyaltyMemberDetail` | `EdenMembershipTierBadge` (obj 001-06) + `EdenActivityFeedItem` (obj 003-06) + `EdenStatCard` + `EdenDetailHeader` (obj 001-02) + `EdenCurrencyDisplay` (obj 001-04) | 1 (atomic) |
| 018-02 | `EdenStoreCreditLedger` | `EdenCurrencyDisplay` + `EdenStatCard` + `EdenDataTable` + `EdenBadge` (hold state) + `EdenEmptyState` | 1 (atomic) |
| 018-03 | `EdenGiftCardBalanceLookup` | `EdenSecretField` (obj 011-08 classified mode for card # entry) + `EdenCurrencyDisplay` + `EdenActivityFeedItem` (recent activity) + private `_GiftCardManagerShim` (obj-015 dependency policy) | 1 (atomic) |
| 018-04 | `EdenRefundFlow` | `EdenLineItemEditor` (obj 012-01) + `EdenPaymentEntry` (obj 012-03) + `EdenSecretField` (manager-override PIN) + `EdenSelect<EdenRefundReason>` + `EdenSearchInput` | 2 (multi-step flow) |
| 018-05 | `EdenLayawayFlow` | `EdenLineItemEditor` (obj 012-01) + `EdenPaymentEntry` (obj 012-03) + `EdenDatePicker` (pickup-by date) + `EdenSelect<EdenLayawayAction>` + `EdenStepper` / inline step indicator | 2 (multi-step flow) |
| 018-06 | `EdenStoreTransfer` | `EdenSelect<EdenLocation>` (source/dest) + `EdenLineItemEditor` (obj 012-01) + `EdenBadge` (transit state) + `EdenInput` (shipping carrier + tracking) + `EdenSearchInput` (item scan) | 2 (multi-step flow) |

## Wave structure

| Wave | TRDs | Theme | Parallelism |
|---|---|---|---|
| **1 — Atomic primitives** | 018-01 (`EdenLoyaltyMemberDetail`), 018-02 (`EdenStoreCreditLedger`), 018-03 (`EdenGiftCardBalanceLookup`) | Three atomic widgets, no inter-dependencies. 018-01 creates `lib/dev_app/screens/retail_polish_screen.dart` (lowest sub-id wins create); 018-02 + 018-03 append `Section()` entries. Run parallel. | All 3 parallel; `co_modified_files` serializes `lib/eden_ui.dart` + `retail_polish_screen.dart` within the wave |
| **2 — Multi-step flows** | 018-04 (`EdenRefundFlow`), 018-05 (`EdenLayawayFlow`), 018-06 (`EdenStoreTransfer`) | All three are multi-step state machines. Compose obj-012 commerce primitives (`EdenLineItemEditor`, `EdenPaymentEntry`). Mirror the obj 014-05 `EdenReceivingFlow` state-machine pattern. Run parallel. | All 3 parallel; `co_modified_files` serializes shared files |

**File-collision discipline (mirrors obj 014):**
- `lib/eden_ui.dart` — every TRD appends export line(s) under section header `// Objective 018 — Retail-Specific Polish Wave N`. Mark each TRD `co_modified_files: [lib/eden_ui.dart]`.
- `lib/dev_app/screens/retail_polish_screen.dart` — **new file, created by TRD 018-01 (Wave 1, lowest sub-id)**. Subsequent TRDs (018-02 .. 018-06) each APPEND one `Section()` entry. TRDs 018-02 .. 018-06 mark `co_modified_files: [lib/dev_app/screens/retail_polish_screen.dart]`.
- `lib/dev_app/screens/home_screen.dart` — **register the `RetailPolishScreen` `_Category` entry once in TRD 018-01** with subtitle covering all 6 widgets. Later TRDs do NOT modify `home_screen.dart`.

**Why a new screen (not `retail_screen.dart`):** `retail_screen.dart` is owned by obj 014 (POS / back-office). obj 018 is the customer/loyalty + refund/layaway/transfer cluster — distinct enough to merit its own category tile per obj 014's category-organization precedent (separate "B-Retail — Back-Office + POS" vs "B-Retail — Customer & Service Flows"). If reviewer flips this, executor can collapse into `retail_screen.dart` via APPEND.

## Obj 012 / obj 014 / obj 015 dependency policy

This objective composes:

- **obj 012 (shipped)** — `EdenLineItemEditor`, `EdenPaymentEntry`, `EdenSplitTender`. Import directly from `package:eden_ui_flutter/eden_ui.dart`.
- **obj 014 (shipped)** — `EdenPOSRegisterScaffold` (not composed here, but TRDs may reference for visual continuity), `EdenInventoryRowEditor` (not composed here — store-transfer uses `EdenLineItemEditor` for the line list). Just confirms the export chain is real.
- **obj 015 (NOT shipped)** — `EdenGiftCardManager`, `EdenPromotionAuthor`. Per orchestrator brief: "composes obj 015 EdenGiftCardManager (graceful fallback if 015 not shipped)". Each affected TRD (018-03 in particular) includes a **`<obj_015_dependency_strategy>`** subsection in its `<context>` block enumerating:
  1. The specific obj-015 widget expected to exist eventually.
  2. The expected obj-015 public API surface (derived from `USE_CASES_RETAIL_2026-05-17.md` §5 Rec 3 + §2 UC-08 / UC-28).
  3. **Behavioural shim:** private `_GiftCardManagerShim` (or `_PromotionAuthorShim` where applicable) replicating the minimal API needed by this TRD. Shim is a private widget — replaced by one-liner when obj-015 lands.
  4. **Detection rule:** executor checks `lib/src/widgets/eden_gift_card_manager.dart` at TRD start. Present → import + compose; absent → inline shim + add `TODO(obj-018→obj-015 swap):` marker comment.

Mirrors obj 014's `<obj_012_dependency_strategy>` pattern verbatim.

## Critical design constraints (locked, do not revisit)

1. **TDD strict (Iron Law) + test-list-first.** Every TRD's testable tasks carry `tdd="true"`. Test-list checklist at the top of every TRD enumerating happy / edge / failure cases BEFORE any test code. Hand-built fixture builders only (`no_llm_test_data` active). Fixture files named `test/widgets/_fixtures/eden_{component}_fixtures.dart` with header `// Do NOT regenerate via LLM — hand-built fixtures for Eden{Component}.`. RED → GREEN → REFACTOR. One test at a time. Per `~/.claude/CLAUDE.md` TDD Playbook habits 1-4.
2. **Outside-in for UI** per Playbook habit 5. Static rendering tests first → interaction tests → helper unit tests. For multi-step flows (018-04, 018-05, 018-06): state machine + step transitions FIRST, then per-step rendering, then helper logic. Mirror the obj 014-05 `EdenReceivingFlow` test-pattern order.
3. **Test pattern locked.** `testWidgets('renders ...', (tester) async {...})` with `wrap()` helper at the top of each test file. Mirror `test/widgets/eden_receiving_flow_test.dart` (obj 014-05) + `test/widgets/eden_alert_test.dart`. Widget tests, NOT integration tests.
4. **Transport-agnostic.** No `dio` / `http` / `connectrpc` / `grpc` / `stripe_terminal` / `square_reader`. No card-network calls — PAN entry composes obj 011-08 `EdenSecretField.classified` (clipboard mode). Photo capture / printer / email / SMS / customer notifications are callbacks (`onNotifyCustomer: (channel, payload) async => ...`); consumer wires platform plugin in their app.
5. **Material 3 + tokens.** Use `EdenSpacing`, `EdenRadii`, `EdenColors`, `EdenTypography` from `lib/src/tokens/`. Touch targets ≥48pt on tablet (per Apple HIG for POS); ≥44pt minimum elsewhere.
6. **iPhone-narrow safe (≥390pt).** Every TRD's test list includes a 390pt-width test asserting no `RenderFlex overflowed` warnings. Multi-step flows (018-04, 018-05, 018-06) collapse to single-column / tabbed at <700pt mirroring obj 014-05's split-pane-vs-tabbed pattern.
7. **Theme-profile aware.** `EdenThemeProfile.retailVibrant` (obj-009) for visual prominence. Widgets don't hard-code retail-vibrant colors; they read from theme via `Theme.of(context)` so theme switching just works.
8. **PCI-aware via obj 011-08's `EdenSecretField` classified mode** for gift-card # entry (018-03), refund-card-on-file lookup if applicable (018-04). **Re-use only — no new card-handling widgets in this objective.** Verify by `grep -E "card_number|cvv|pan" lib/src/widgets/eden_gift_card_balance_lookup.dart lib/src/widgets/eden_refund_flow.dart` returning empty.
9. **Generic types — don't bind to retail domain.** Every component takes a generic value class:
   - `EdenLoyaltyMemberDetail` accepts `EdenLoyaltyMember(id, name, tier?, points?, lifetimeSpendCents?, birthday?, recentPurchases: List<EdenLoyaltyPurchase>, joinedAt?)`. Consumer maps domain.
   - `EdenStoreCreditLedger` accepts `EdenStoreCreditLedgerData(customerId, balanceCents, history: List<EdenStoreCreditEntry>, holds: List<EdenStoreCreditHold>)`.
   - `EdenGiftCardBalanceLookup` is an interactive widget (no input value class; consumer wires `Future<EdenGiftCardBalanceResult?> onLookup(String cardNumber)`).
   - `EdenRefundFlow` accepts `EdenRefundFlow(onLookupSale, onManagerApprove, onSubmit, ...)` callback constructor; consumer fetches sale.
   - `EdenLayawayFlow` accepts `EdenLayawayState(id, cartItems, depositCents, balanceCents, installments, pickupByDate, status)`.
   - `EdenStoreTransfer` accepts `EdenStoreTransfer(sourceLocation, destLocation, items, status, shippingCarrier?, trackingRef?)`.
10. **No backend bind.** No Square / Stripe / Shopify / loyalty-vendor API knowledge in lib. Manager-override approval is a callback (`onManagerApprove: () async => bool` returning auth-success). Customer notify (layaway) is a callback (`onNotifyCustomer: (EdenLayawayNotifyChannel) async => ...`).
11. **No new pubspec deps.** Default: `flutter/material.dart` + `dart:math` + existing eden-ui-flutter primitives only. Receipt print is a callback; consumer wires platform print plugin in their app.
12. **No breaking changes to existing widgets.** Existing 700+ widget exports must continue to pass `flutter test`. This objective is purely additive.
13. **Visual catalog entry per component.** Every TRD appends a `Section()` to `lib/dev_app/screens/retail_polish_screen.dart`. TRD 018-01 creates the file with the LoyaltyMemberDetail section.
14. **Anti-pattern constraints (resolver-enforced — opt-out only via TRD frontmatter):**
    - `no_llm_test_data` — Fixture builders hand-built (header line locked, no opt-out).
    - `no_property_based_default` — No `rapid` / `gopter` / `fast_check`. Descriptive `testWidgets('...')` names.
    - `no_gherkin_layer` — No `.feature` files, no Cucumber.

## Success criteria (must-haves, observable truths)

1. All 6 TRDs ship; `flutter analyze` clean; `flutter test` passes (existing 700+ tests still pass + ~90-120 new retail-polish-widget tests pass).
2. **`EdenLoyaltyMemberDetail` renders member profile** with: header (avatar + name + `EdenMembershipTierBadge`); 3-KPI strip (lifetime spend / points balance / days since last visit); recent-purchases list (last 5-10 via `EdenActivityFeedItem`); optional birthday-promo callout when `birthday` is within ±14 days; loyalty join date footer. Generic value class — no retail-specific binding.
3. **`EdenStoreCreditLedger` renders customer-attached store-credit balance** with: current balance (large `EdenCurrencyDisplay`); held-amount sub-row (when holds exist) showing balance − holds = available; history table (`EdenDataTable`) with columns Date / Type (issued / spent / adjustment / expired) / Amount / Reason / Receipt-# (optional); empty state for zero-history customers (`EdenEmptyState`). All amounts in cents, no business-logic validation.
4. **`EdenGiftCardBalanceLookup` interactive lookup widget** with: PCI-aware card # entry via `EdenSecretField.classified` (clipboard mode locked off); 'Lookup' button → fires `onLookup(cardNumber)`; result shows balance + last-N (5 default, configurable) activity rows via `EdenActivityFeedItem`; error state for `card not found` / `deactivated`; loading state during lookup. Composes private `_GiftCardManagerShim` until obj-015 lands (graceful fallback per OBJECTIVE.md obj-015 dependency policy).
5. **`EdenRefundFlow` walks 4-step refund multi-step.** Step 1 (`LookupSale`) — search by receipt # / phone / email / card-last-4 wired to `onLookupSale(query)` callback returning `Future<EdenSaleRecord?>`. Step 2 (`SelectLines`) — composes `EdenLineItemEditor.refundMode` (per-line refund-qty column ≤ original qty); each line has an `EdenSelect<EdenRefundReason>` (damaged / wrongItem / notAsDescribed / changedMind / other). Step 3 (`Method`) — `EdenPaymentEntry` constrained to refund methods (original tender / store credit / cash); shows `originalTender` callout for re-routing. Step 4 (`ManagerApprove`) — when refund total ≥ configurable threshold OR refund-method ≠ original-tender, prompt `onManagerApprove()` returning bool. Emits `EdenRefundDraft(saleId, lines, method, managerApproved, reasonAggregate)` on `onSubmit`.
6. **`EdenLayawayFlow` walks 4-step layaway lifecycle.** Step 1 (`Create`) — composes `EdenLineItemEditor` (read-only cart from session) + customer attach callback. Step 2 (`Deposit`) — `EdenPaymentEntry` for deposit collection (min-deposit-% configurable; default 20%). Step 3 (`Schedule`) — `EdenDatePicker` for pickup-by date + optional installment-plan count input. Step 4 (`Manage`) — for existing layaways: 3 actions via `EdenSelect<EdenLayawayAction>` (recordInstallment / releaseToCustomer / cancelAndRefund); customer-notify callback fires on transitions (`onNotifyCustomer(channel: email | sms | none, payload)`). Emits `EdenLayawayDraft` on `onSubmit`.
7. **`EdenStoreTransfer` walks 4-step transfer lifecycle.** Step 1 (`SelectLocations`) — `EdenSelect<EdenLocation>` × 2 (source + dest); validates source ≠ dest. Step 2 (`SelectItems`) — `EdenLineItemEditor` for transfer line items; barcode scan callback for fast add. Step 3 (`Shipping`) — optional carrier name + tracking ref `EdenInput`s; allow "Walk-in transfer" (no carrier) checkbox. Step 4 (`ConfirmDispatch`) — confirm dispatch → emit `EdenStoreTransferDraft(status: inTransit)`. For receiving leg: Step 5 (`Receive`) shown only when transfer is `inTransit` and arriving at dest → confirm receive → `status: received` + per-line variance reason if needed (reuse `EdenVarianceReason` from obj 014-05). Emits `EdenStoreTransferDraft` on each transition.
8. **Hand-built fixtures with locked header line.** Every fixture file under `test/widgets/_fixtures/eden_{component}_fixtures.dart` has line 1: `// Do NOT regenerate via LLM — hand-built fixtures for Eden{Component}.`. Verified by `grep -L 'Do NOT regenerate' test/widgets/_fixtures/eden_loyalty_member_detail_fixtures.dart test/widgets/_fixtures/eden_store_credit_ledger_fixtures.dart test/widgets/_fixtures/eden_gift_card_balance_lookup_fixtures.dart test/widgets/_fixtures/eden_refund_flow_fixtures.dart test/widgets/_fixtures/eden_layaway_flow_fixtures.dart test/widgets/_fixtures/eden_store_transfer_fixtures.dart` returning empty.
9. **Dev catalog entry.** `lib/dev_app/screens/retail_polish_screen.dart` exists and is registered in `home_screen.dart` `_categories` list with subtitle: `'Loyalty member detail, store credit ledger, gift card balance lookup, refund flow, layaway flow, store transfer'`. `just dev-ui` → tap "B-Retail — Customer & Service Flows" tile → all 6 components render with sample data.
10. **Exports section.** `lib/eden_ui.dart` has `// ─────────── Objective 018 — Retail-Specific Polish ───────────` section with sub-headers `Wave 1` / `Wave 2` and 6 export lines.
11. **Backward compat — no regressions.** `flutter test` runs all 700+ existing tests successfully. No public API changes to any existing widget. New widgets are purely additive.
12. **iPhone-narrow safe (≥390pt)** — every TRD's test list includes a `tester.binding.setSurfaceSize(Size(390, 800))` test asserting no `RenderFlex overflowed` warnings.
13. **No new pubspec deps.** `pubspec.yaml` unchanged across all 6 TRDs. Verified by `git diff pubspec.yaml` returning empty after objective completes.
14. **Roadmap updated:** objective 018 added to Active Objectives with TRD checklist (all `[ ]`).

## Out of scope (deferred or skipped)

- **`EdenExchangeFlow`** (UC-05) — single-transaction exchange (refund + add-to-cart hybrid). Mirror of `EdenRefundFlow` shape; defer to obj 019 or v2 ("Retail extras"). Tracked as future TRD: `018-future: EdenExchangeFlow`.
- **`EdenVoidWithReason`** (UC-04 edge) — void-without-receipt modal. Composable from `EdenConfirmDialog` + `EdenSelect<EdenVoidReason>`. Defer.
- **`EdenStockCountSession`** (UC-14, UC-15) — full / cycle count session. Per `USE_CASES_RETAIL_2026-05-17.md` §5 Rec 5, ships in proposed obj-014.E "Retail inventory ops" (separate objective).
- **End-of-day cluster** (UC-45 .. UC-48, `EdenDrawerCount`, `EdenCashDrop`, `EdenBankDeposit`, `EdenShiftReport`) — per §5 Rec 1, ships in proposed obj-014.B "Retail close-of-day" (separate objective). HARD BLOCKER but outside this objective's scope.
- **Promotion authoring** (UC-31, UC-32) — `EdenPromotionRuleBuilder`, `EdenPricingTierEditor`. Per §5 Rec 7, ships in proposed "Retail promotions" objective.
- **Employee mgmt** (UC-37 .. UC-40) — `EdenTimeClock`, `EdenTimeCardApproval`, `EdenCommissionRateEditor`. Per §5 Rec 8, ships in cross-vertical "Employee ops" objective (high cross-vertical leverage).
- **BOPIS / omnichannel** (UC-49) — per §5 Rec 9, separate "Retail omnichannel" objective.
- **Catalog depth** (UC-20, UC-21, UC-23) — variant matrix, kit builder, label printer. Per §5 Rec 4, separate "Retail catalog depth" objective.
- **Vendor / PO authoring** (UC-33, UC-34, UC-35) — vendor directory + PO author. Per §5 Rec 6, separate "Retail purchasing" objective.
- **Stripe Terminal / Square Reader integration.** Library is transport-agnostic. Card entry via obj 011 `EdenSecretField.classified`.
- **Thermal printer driver wiring.** Receipt-of-refund / layaway-receipt print is a callback.
- **Real-time inventory sync.** All ledger widgets are presentation primitives; consumer re-renders on backend update.
- **Multi-tenant / multi-store dashboard view.** Value classes single-store. Multi-store dashboards are a consumer composition concern.
- **Visual regression baselines** (VRT-01 v2 future objective).
- **Real-device iOS / Android / web testing** (downstream apps gate this).

## References

**Primary spec:**
- `.planning/USE_CASES_RETAIL_2026-05-17.md` §0 executive summary (worst clusters), §2 use-case taxonomy (UC-04, UC-06, UC-16, UC-25, UC-26, UC-27, UC-28), §3.1 competitor parity matrix, §5 top-10 gap-closing recommendations.

**Dependency: obj 014 (shipped):**
- `.planning/objectives/014-b-retail-back-office/OBJECTIVE.md` — locked decisions B-R1 (iPad-native v1), obj-012 dependency policy template, locked constraints (PCI / theme / fixtures / iPhone-narrow / no-new-deps), `out of scope` items that this objective closes.
- `.planning/objectives/014-b-retail-back-office/014-SUMMARY.md` — actual implementation outcomes; `EdenPOSRegisterScaffold`, `EdenInventoryRowEditor`, `EdenReceivingFlow` shape references.
- `.planning/objectives/014-b-retail-back-office/014-05-TRD.md` — canonical multi-step state-machine TRD shape; this objective's Wave 2 TRDs (018-04, 018-05, 018-06) mirror exactly.

**Dependency: obj 012 commerce primitives (shipped):**
- `lib/src/widgets/eden_line_item_editor.dart` — composed by 018-04, 018-05, 018-06.
- `lib/src/widgets/eden_payment_entry.dart` — composed by 018-04, 018-05.
- `lib/src/widgets/eden_split_tender.dart` — referenced by 018-04 (refund-method picker may composite if multi-tender refund needed).

**Dependency: obj 011 compliance overlay (shipped):**
- `lib/src/widgets/eden_secret_field.dart` classified mode — composed by 018-03 (gift card #) + 018-04 (manager-override PIN).

**Dependency: obj 001 + obj 003 atomic primitives (shipped):**
- `lib/src/widgets/eden_membership_tier_badge.dart` (obj 001-06) — composed by 018-01.
- `lib/src/widgets/eden_activity_feed_item.dart` (obj 003-06) — composed by 018-01, 018-02, 018-03.
- `lib/src/widgets/eden_currency_display.dart` (obj 001-04) — composed by 018-01, 018-02, 018-03, 018-04, 018-05, 018-06.

**Theme / tokens:**
- `lib/src/theme/eden_theme_profile.dart` (`EdenThemeProfile.retailVibrant` — obj 009) — POS prominence.
- `lib/src/tokens/colors.dart`, `spacing.dart`, `radii.dart`, `typography.dart`.

**Library context:**
- `.planning/PROJECT.md` (transport-agnostic constraint, test pattern, validation commands, iPhone-narrow ≥390pt baseline).
- `eden-libs/CLAUDE.md` ("Keep platform logic in eden-platform-flutter, not in eden-ui-flutter").
- `~/.claude/CLAUDE.md` TDD Playbook (global — strict TDD + test-list-first + hand-built fixtures + outside-in for UI + one test at a time).

**Pattern references (canonical TRD shape):**
- `.planning/objectives/014-b-retail-back-office/014-05-TRD.md` — multi-step state machine pattern (selectPo → variance → costUpdate → disposition). This objective's Wave 2 mirrors verbatim.
- `.planning/objectives/014-b-retail-back-office/014-03-TRD.md` — `<obj_012_dependency_strategy>` pattern + private-shim approach. This objective's `<obj_015_dependency_strategy>` mirrors.
- `.planning/objectives/011-compliance-overlay-primitives/011-01-TRD.md` — bootstrap-screen-from-first-TRD pattern (018-01 creates `retail_polish_screen.dart`).
