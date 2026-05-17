---
objective: 015-cross-vertical-commerce-completer
kind: ui-lib
work: feature
status: planned
estimated_effort: 3-4 weeks Claude execution
trd_count: 8
waves: 3
---

# Objective 015 — Cross-Vertical Commerce Completer

## Goal

Ship the **8 cross-vertical commerce / operations primitives** that surface as BLOCKED `must-launch` gaps in **2+ verticals simultaneously** per the use-case audits in `USE_CASES_SALON_2026-05-17.md`, `USE_CASES_RETAIL_2026-05-17.md`, and `USE_CASES_TRADES_2026-05-17.md`. After this objective ships:

- A stylist/cashier takes a **tip** (preset chips + custom amount + no-tip) via `EdenTippingSelector`, and splits it across staff via `EdenTipSplitEditor`. Closes SALON-016/017/018 (POS bedrock), RETAIL UC-04 tip-screen-after-tender prompt, medical co-pay gratuity.
- A chair-side salon checkout flow renders as a single **bottom-sheet composer** `EdenCheckoutSheet` wrapping Obj-012 `EdenLineItemEditor` + 015-01 `EdenTippingSelector` + Obj-012 `EdenPaymentEntry` + `EdenSplitTender` + Obj-014 `EdenReceiptPreview`. Closes SALON-016.
- A staff member sells / redeems / looks-up / rebalances **gift cards** via the `EdenGiftCardManager` family (issue / redeem / lookup / balance / ledger). Closes SALON-019/020 + RETAIL UC-08/09/28.
- An owner configures **commissions** (% / fixed / tiered / split) for stylists, retail employees, trades technicians via `EdenCommissionsEditor`. Closes SALON-046 `EdenCommissionStructureEditor` + RETAIL UC-39 + TRADES UC-58 (BLOCKED ServiceTitan parity gap, Recommendation #6).
- Staff **clock in/out** via `EdenTimeClock` (PIN-gated kiosk variant) and managers approve hours via `EdenTimeCard`. Closes SALON-045 + RETAIL UC-37/UC-38 + TRADES UC-15/UC-25.
- A cashier closes the drawer (denomination count + cash drop + bank deposit) via `EdenCashDrawerClose`. Closes RETAIL UC-45/46/47 (entire End-of-day 0/10 cluster) + SALON-053.
- A manager prints the end-of-shift X/Z report and posts the shift close via `EdenShiftClose` + `EdenXZReport`. Closes RETAIL UC-48 + the salon end-of-day surface that composes the same primitives.
- A marketing manager authors promotions (BOGO / member-pricing / coupon code / member-only) via `EdenPromotionAuthor` and applies them at checkout via `EdenPromotionApply`. Closes RETAIL UC-30/UC-31/UC-32 + SALON-041/042.

These widgets close the **highest-leverage launch-blocker cluster left in the library**: every retailer closes a drawer daily (RETAIL §1 cluster #9 hard-blocker), every salon checkout includes a tip (SALON Top-10 #4), every multi-vertical SMB pays employees (cluster across 3 verticals), every retailer runs at least one promotion type. The cluster is **transactional commerce + day-close + workforce** — three of the five biggest gaps Square / Shopify / Vagaro / Clover ship day-1 that Eden Biz does not yet.

These are the lowest-layer commerce + ops primitives. **Backend codegen, transport, persistence, and orchestration belong in `eden-biz-flutter` / `eden-platform-flutter`, not here.** Per `eden-libs/CLAUDE.md`: "Keep platform logic in `eden-platform-flutter`, not in `eden-ui-flutter`."

## Why now

- **Salon SKU is gated by 015-01/02/03/05/04 today.** Per `USE_CASES_SALON_2026-05-17.md` §1.16 + §5: SALON-016 (Checkout) is BLOCKED because there is no `EdenTippingSelector` + no `EdenCheckoutSheet`. SALON-018 (Tip split) is BLOCKED. SALON-019/020 (Gift card) is BLOCKED. SALON-045 (Time clock) is PARTIAL. SALON-046 (Commission) is PARTIAL. SALON-053 (Cash drawer) is BLOCKED. Five BLOCKED must-launch + two PARTIAL must-launch use cases land FULL after this objective.
- **Retail SKU is gated by 015-06/07.** Per `USE_CASES_RETAIL_2026-05-17.md` §1 Cluster #9 — **End-of-Day & Reconciliation 0/10 score** is the single worst cluster and a *hard launch blocker* ("every retailer closes a register every day"). Square / Clover / Lightspeed all ship drawer-count + cash-drop + bank-deposit + X/Z report day-1; we have none.
- **Trades SKU is gated by 015-04 (Commissions) + 015-05 (TimeClock).** Per `USE_CASES_TRADES_2026-05-17.md` §5 Recommendation #6: `EdenTimeEntry` + `EdenCommissionsEditor` is the named gap; UC-58 is one of the 4 BLOCKED use cases ServiceTitan + Workiz both ship.
- **Promotions are leverage across 2+ verticals.** RETAIL Cluster #5 (`EdenPromotionRuleBuilder` absent — Square Plus marketed pillar) + SALON-041/042 (Define + apply offer). Build once, win two clusters.
- **Composes obj 012 primitives heavily.** `EdenCheckoutSheet` composes `EdenLineItemEditor` + `EdenPaymentEntry` + `EdenSplitTender`. `EdenGiftCardManager` redeem-at-checkout composes `EdenLineItemEditor`. `EdenPromotionApply` composes `EdenLineItemEditor`. `EdenShiftClose` composes `EdenReceiptPreview` (obj 014) + `EdenAggregateKpiStrip` (obj 012). Net-new code is bounded; most surface is composition.
- **No new pubspec deps.** Confirmed for every component — all primitives reuse existing widgets + tokens + Material 3.

## Components in scope

| ID | Component | Composes | Verticals served |
|---|---|---|---|
| 015-01 | `EdenTippingSelector` + `EdenTipSplitEditor` | `EdenChip`, `EdenInput`, `EdenSegmentedControl`, `EdenCurrencyDisplay`, `EdenBanner` | Salon (16/17/18), retail (UC-04 tip prompt), medical co-pay |
| 015-02 | `EdenCheckoutSheet` (composite) | `EdenBottomSheet`, obj-012 `EdenLineItemEditor` + `EdenPaymentEntry` + `EdenSplitTender`, 015-01 `EdenTippingSelector`, obj-014 `EdenReceiptPreview`, 015-08 `EdenPromotionApply` (graceful fallback) | Salon checkout composite |
| 015-03 | `EdenGiftCardManager` (issue / redeem / lookup / balance / ledger) | `EdenBarcodeScanner`, `EdenCurrencyDisplay`, `EdenInput`, `EdenDataTable`, `EdenStatusBadge`, `EdenChip`, `EdenLineItemEditor` (redeem-at-checkout) | Salon (19/20), retail (UC-08/09/28) |
| 015-04 | `EdenCommissionsEditor` (% / fixed / tiered / split) | `EdenForm`, `EdenInput`, `EdenDataTable`, `EdenSegmentedControl`, `EdenChip`, `EdenCurrencyDisplay` | Salon stylists (46) + retail (UC-39) + trades (UC-58 BLOCKED) |
| 015-05 | `EdenTimeClock` + `EdenTimeCard` | `EdenOtpInput` (PIN), `EdenSegmentedControl`, `EdenStatusBadge`, `EdenApprovalQueue`, `EdenDataTable`, `EdenBanner` | Salon (45) + retail (UC-37/38) + trades (UC-15/25) |
| 015-06 | `EdenCashDrawerClose` (drawer count → cash drop → bank deposit) | `EdenForm`, `EdenInput`, `EdenCurrencyDisplay`, `EdenBanner`, `EdenDataTable` | Retail end-of-day cluster (UC-45/46/47) + salon (53) |
| 015-07 | `EdenShiftClose` + `EdenXZReport` | 015-06 `EdenCashDrawerClose`, obj-014 `EdenReceiptPreview` (print + email + sms modes), obj-012 `EdenAggregateKpiStrip`, `EdenDataTable` | Retail end-of-day cluster (UC-48) + salon end-of-day |
| 015-08 | `EdenPromotionAuthor` + `EdenPromotionApply` (BOGO / member-pricing / coupon / member-only) | `EdenForm`, `EdenSegmentedControl`, `EdenToggle`, `EdenChip`, `EdenDatePicker`, `EdenLineItemEditor` (apply mode), `EdenCurrencyDisplay`, `EdenBanner` | Salon (41/42) + retail (UC-30/31/32) |

## Critical constraints (locked)

- **Composes obj 012 primitives.** `EdenLineItemEditor`, `EdenPaymentEntry`, `EdenSplitTender` are shipped in `lib/eden_ui.dart` (verified). 015-02/03/07/08 compose them directly; no shim layer needed (unlike obj 014's pre-012 shim pattern).
- **Composes obj 014 primitives.** `EdenReceiptPreview` is shipped; 015-07 composes it for X/Z report printing.
- **Theme-profile aware via Obj 009.** Every component reads `EdenStatusPalette` via `Theme.of(context).extension<EdenStatusPalette>()` with `EdenStatusPalette.commercial()` fallback (commercialWarm baseline matches today's EdenColors values exactly). No vertical-specific hard-coded colors.
- **Generic value classes.** Every component takes a vertical-agnostic value class. Consumers map their domain (`StaffMember` → `EdenCommissionTarget`, `Sale` → `EdenTipContext`, `GiftCard` → `EdenGiftCardRecord`, `Drawer` → `EdenDrawerSession`). The library never binds to salon / retail / trades / medical entities directly.
- **Transport-agnostic.** Payment processing, persistence, barcode scanner hardware, printer hardware are all consumer callbacks. The library produces drafts + intent; consumer wires actual processors.
- **Currency via existing `EdenCurrencyDisplay`** (Obj 001-04). No new currency formatter; no new intl dep.
- **No new pubspec deps.** Every component composes existing widgets. Confirmed for all 8.
- **iPhone-narrow ≥390pt baseline.** Every component renders without `RenderFlex overflowed` warnings at 390pt logical width. LayoutBuilder-driven responsive layouts, not MediaQuery on root size.
- **TDD strict per user playbook.** Every testable task carries `tdd="true"`. Test-list-first checklist included in every TRD. Hand-built fixtures only (no LLM-generated test data). Outside-in test ordering (rendering → interaction → responsive → a11y). One test at a time per habit 3.
- **Multi-tenant isolation N/A.** This is a UI library — transport-agnostic, no data access. The user-playbook habit 6 multitenancy assertion does not apply (defaults table cell `security_isolation: n/a` for `(ui-lib, feature)`).

## Wave structure

| Wave | TRDs | Theme | Parallelism |
|---|---|---|---|
| **1 — Atomic commerce** | 015-01 (Tipping), 015-04 (Commissions) | Self-contained primitives; no obj-012/014 composition required | Parallel (disjoint files; 015-01 appends commerce_screen, 015-04 bootstraps staff_screen) |
| **2 — Lifecycle managers** | 015-03 (GiftCard), 015-05 (TimeClock), 015-08 (Promotion) | Multi-screen managers that compose Wave 1 primitives in places | Parallel within wave per logical theme. 015-03 + 015-08 both append `commerce_screen.dart` so the orchestrator MUST resequence them on shared-file ground (per `feedback_planner_proto_conflict.md`); they're flagged via `co_modified_files`. 015-05 appends `staff_screen.dart` only — fully parallel-safe |
| **3 — Composite flows** | 015-02 (CheckoutSheet), 015-06 (CashDrawerClose), 015-07 (ShiftClose+XZReport) | Wrapping composites that consume Wave 1 + Wave 2 outputs | 015-02 + 015-06 parallel (disjoint files — commerce_screen vs eod_screen-bootstrap); **015-07 sequential after 015-06** per user spec (composes 015-06) |

## Dev catalog screen plan

| Screen | Status | Sections added by 015 |
|---|---|---|
| `lib/dev_app/screens/commerce_screen.dart` | Exists (obj 012); already extended by obj 014 | 015-01 Tipping, 015-03 GiftCard, 015-08 Promotion, 015-02 CheckoutSheet (composite demo) |
| `lib/dev_app/screens/staff_screen.dart` | **NEW** — bootstrapped by 015-04 | 015-04 Commissions, 015-05 TimeClock+TimeCard |
| `lib/dev_app/screens/eod_screen.dart` | **NEW** — bootstrapped by 015-06 | 015-06 CashDrawerClose, 015-07 ShiftClose+XZReport |
| `lib/dev_app/screens/home_screen.dart` | Exists | Two new category tiles (Staff, End of Day) registered by 015-04 + 015-06 |

## Out of scope

- **Backend orchestration.** Storing time-card entries, posting cash-drop ledgers, persisting promotion rules, looking up gift-card balances over the network — all belong in `eden-biz-flutter` / `eden-platform-flutter`. The library produces drafts; consumer wires the platform side.
- **Receipt printer hardware.** Generating thermal-print bytes for 80mm/58mm rolls is handled by `EdenReceiptPreview` (Obj 014). Driver-level print spooling is a consumer concern.
- **Payment processor SDKs.** Stripe Connect onboarding (SALON-061), Square SDK wiring, card-reader BLE pairing — all consumer-side.
- **Native iOS payment-sheet (Apple Pay / Google Pay).** Tokenization handed off to platform; the library shows the result.
- **Tax engine.** Tax calculation lives in `eden-biz-flutter` or a tax-service integration. The library accepts tax-inclusive vs tax-added totals and renders them; it does not compute tax rates.
- **Payroll export.** CSV / Gusto / QBO export from approved time cards is a `eden-biz-flutter` concern. The library produces approved time-card drafts; export is downstream.
- **Schedule publishing / shift-swap workflow.** RETAIL UC-40 surface deferred; obj 004 `EdenScheduler` already ships the grid. Publishing workflow is a separate composer; not in 015 scope (queued for a later objective).
- **Loyalty / store credit / member-pricing engine.** RETAIL UC-26/UC-27 deferred per OBJECTIVE-014 out-of-scope list. 015-08 promotions handles BOGO / coupon / member-only access; loyalty-points-ledger is a separate widget.
- **Salon-specific service-catalog tile.** SALON-060 `EdenServiceCatalogTile` is a separate gap (Top-10 #3 in salon audit); not in 015 scope. Tracked for a follow-up objective.
- **Gift-card artwork upload + custom designer.** SALON-019 mentions artwork-picker for physical card sales; the gift-card manager handles purchase + redeem + balance + ledger but defers the artwork-customization surface to a later v2 widget.

## References

- `.planning/USE_CASES_SALON_2026-05-17.md` §1.16–§1.22 (POS bedrock), §1.45–§1.46 (staff), §1.53 (cash drawer), §5 (Top-10 gap-closers)
- `.planning/USE_CASES_RETAIL_2026-05-17.md` §1 Cluster #5 (Promotions), Cluster #7 (Employee), Cluster #9 (End-of-Day)
- `.planning/USE_CASES_TRADES_2026-05-17.md` §5 Recommendation #6 (Time entry + Commissions), §4.3 BLOCKED list (UC-58)
- `.planning/objectives/012-cross-vertical-commerce-primitives/012-SUMMARY.md` — obj 012 shipped primitives composed throughout
- `.planning/objectives/014-b-retail-back-office/014-SUMMARY.md` — obj 014 shipped primitives composed by 015-07
- `~/.claude/CLAUDE.md` — TDD Playbook (6 habits applied)
- `.planning/PROJECT.md` — `ui-lib` constraints (transport-agnostic, no new deps, ≥390pt baseline)
- `lib/eden_ui.dart` — confirmed shipped: `EdenLineItemEditor`, `EdenPaymentEntry`, `EdenSplitTender`, `EdenReceiptPreview`, `EdenStatusPalette`, `EdenBarcodeScanner`, `EdenOtpInput`, `EdenSegmentedControl`, `EdenApprovalQueue`, `EdenCurrencyDisplay`, `EdenAggregateKpiStrip`
