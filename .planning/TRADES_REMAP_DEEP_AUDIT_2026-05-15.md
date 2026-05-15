# Trades Remap — Deep Audit

**Date:** 2026-05-15
**Companion to:** `VERTICAL_COVERAGE_ASSESSMENT_2026-05-15.md` (parent assessment)
**Sources audited:**
- `AOCyber-Trades/trades-flutter` @ `feature/multi-model-adaptive` — 36 feature folders, ~420 dart files under `lib/features/`, 41 widgets under `lib/shared/widgets/`
- `AOCyber-Trades/trades` (trades-react) @ `main` — React 18 + Vite + Tailwind + shadcn/ui (65 primitives) + React Flow + Wouter + Tauri 2.x (iOS/Android/desktop), ~30 component groups, ~50 page modules, 190+ DB tables, 113 RBAC flags

**Output of this doc:** per-feature-folder remap matrix + sub-system port plan + donor map + revised Wave B-trades component list that supplements the parent assessment.

---

## 1. TL;DR

The trades-vertical remap is **not** a "port one app to another." It's three concurrent moves:

1. **Track D1 (admin features)** — 36 trades-flutter feature folders absorb into `eden-biz-flutter/lib/features/trades/` (or vertical-gated under existing features), classified into admin vs companion build target.
2. **Track A4 (visual builders)** — port two React-Flow-based sub-systems from trades-react to eden-ui-flutter: **VisualProcessCanvas** (21 files, 1012 LOC in canvas alone) + **WorkflowDesigner** (20 files, 7 node types). Largest single missing primitive from the parent assessment.
3. **Track B-trades library deltas** — eden-ui-flutter component additions beyond what the parent assessment captured: AI sidebar/insight ladder, offline queue + indicator, swimlane editor, mobile bottom-nav tab strip, contextual tour overlay, dispatcher map, role-specific forefront dashboard panels.

**Volume reality check:** the 2026-05-02 doc estimated trades-flutter shared/widgets port at ~14 widgets (Wave 2-5). The 36-folder walk reveals the inside-the-folders pattern reuse is **denser** — every folder has 1-3 widget-shaped patterns (sidebar, ai-insights panel, sub-panel) that recur in eden-biz today as ad-hoc compositions. Codifying the recurrences as library primitives cuts ~30-40% of the remap LOC.

**Companion-vs-admin split** (per `VERTICAL_SKIN_ARCHITECTURE.md`, Path α — single binary + mode flag):
- **Companion (field/mobile build target)** — 4 folders are field-first: `field_crew`, `mobile_home`, `dispatch`, plus `schedule/mobile_view`. Plus the mobile-only views inside multi-mode folders.
- **Admin (eden-biz-flutter desktop/web shell)** — 32 folders are admin/dispatcher/back-office. Many of these need a mobile-responsive variant but not a separate route registration.

**One under-covered area:** **role-based dashboards**. trades-react has 6 forefront panels (Head/Lead/Dispatcher/Tech/Admin/AppointmentDialog) — eden-ui-flutter has none. This is a Wave-A-class addition because every vertical needs role-specific home screens.

---

## 2. Sub-systems — the three big rocks

### 2.1 VisualProcessCanvas — A4-a (≈4 wk)

**Trades-react location:** `client/src/components/customizations/processes/visual-builder/` (21 files)

**Shape:**
- `VisualProcessCanvas.tsx` (1012 LOC) — the canvas root using `@xyflow/react`
- `Toolbox.tsx` — drag-from-palette source
- 6 node types: `StartNode`, `EndNode`, `PhaseNode`, `TaskGroupNode`, `TaskNode`, `DecisionNode`, `OrphanNode`
- 3 dialogs: `PhaseEditorDialog`, `TaskGroupEditorDialog`, `TaskEditorDialog`
- `NodeContextMenu`, `EdgeContextMenu`
- `utils/layoutEngine.ts` (likely uses Dagre — `@types/dagre` is in package.json) + `utils/processValidation.ts`
- `hooks/useProcessToFlow.ts` — model-to-flow bidirectional sync

**Flutter port options:**
- **Option 1 — port to `graphview` + custom CustomPainter.** Most control, largest LOC.
- **Option 2 — `flutter_flow_chart` package.** Closer to React Flow's API; less control of edge routing.
- **Option 3 — port to `eden-ui-flutter/eden_diagram/`** (already a sub-suite, currently used for system diagrams). Extend it to support node types + drag-from-toolbox + dialogs.

**Recommendation:** Option 3 — extend `eden_diagram`, treat process builder as the second consumer (system diagrams was the first). Reuses the diagram coordinate system, edge router, viewport controls.

**Already-half-done in trades-flutter:** `process_builder/` has `swimlane_canvas.dart` + `swimlane_toolbar.dart` — a **swimlane** model, not free-form like the React canvas. Same intent, different metaphor. Open question: do we ship swimlanes (trades-flutter), free-form canvas (trades-react), or both?

### 2.2 WorkflowDesigner — A4-b (≈3 wk)

**Trades-react location:** `client/src/components/workflow/` (20 files)

**Shape:**
- `WorkflowDesigner.tsx`, `WorkflowCanvas.tsx`, `WorkflowSidebar.tsx`, `WorkflowToolbox.tsx`, `WorkflowTemplatesList.tsx`, `WorkflowTemplateDialog.tsx`, `ActiveExecutionsMonitor.tsx`, `FieldBrowser.tsx`
- 7 node types: `TriggerNode`, `ActionNode`, `BranchNode`, `ConditionNode`, `DelayNode`, `MergeNode`, `EndNode`

**Differs from VisualProcessCanvas:** workflows model event-driven automation (trigger → condition → action ladder) vs process templates (phase → task-group → task hierarchy). Same canvas engine, different node grammar.

**Recommendation:** ship **after** 2.1 lands the canvas engine in `eden_diagram`. Then 2.2 is "register 7 more node types + their editors + bind to workflow service." Estimated ≈half the cost of 2.1 because the canvas infra is reusable.

**Known backend gap from trades-react CLAUDE.md:** workflow automation trigger types missing `entity_created` in backend Zod enum — workflows never auto-fire. This is a trades-go bug, not a UI issue, but the remap planner should flag it so the Flutter port doesn't ship dead UI.

### 2.3 Offline sync + WebSocket fabric — D-companion infra (≈2 wk in library)

**Trades-react location:** `client/src/services/offlineSync.ts` (IndexedDB) + `/ws` WebSocket with 6 channels (locations, projects, dispatch, documents, notifications, forefront).

**Trades-flutter location:** `field_crew/data/offline_queue_item_model.dart` + `offline_queue_page.dart` + the 5 shared `offline_banner.dart`/`offline_queue_badge.dart`/`sync_indicator.dart`-shaped widgets.

**Library primitives needed in eden-ui-flutter:**
- `EdenOfflineBanner` — already partly in trades-flutter shared (per parent assessment Wave 3).
- `EdenOfflineQueueBadge` — counter pill on action items.
- `EdenSyncIndicator` — already in eden-ui-flutter (`sync_indicator/`).
- `EdenOfflineQueueViewer` — list of queued mutations with conflict-resolution affordance. **Net-new.**
- `EdenWebSocketChannelMonitor` — dev/debug overlay showing channel status. **Net-new** — optional.

These are companion-app prereqs but useful for any vertical where intermittent connectivity matters (medical home-visit, fuel-truck drivers, salon mobile services). Pull these into Wave A's "cross-vertical fundamentals."

---

## 3. Per-feature-folder remap matrix

Columns:
- **Folder** — trades-flutter `lib/features/<x>/`
- **#dart** — file count
- **React peer** — corresponding trades-react component group / page
- **Target shell** — `admin` (eden-biz-flutter desktop/web), `companion` (field/mobile build target), `both` (admin desktop + mobile-responsive)
- **Vertical gating** — `trades` (lives under `lib/features/trades/`), `cross` (vertical-agnostic, lives under top-level `lib/features/`), `shared-with-x` (lift to library)
- **Library asks** — what eden-ui-flutter primitives this folder requires (✓ exists | + needed)

### Band 1 — Cross-vertical CRUD (lift gated under existing eden-biz feature folders)

| Folder | #dart | React peer | Target shell | Vertical gating | Library asks |
|---|---|---|---|---|---|
| customers | 20 | `pages/Customers.tsx`, `components/customers/` | both | cross | ✓ list/detail scaffolds (A1/A2), ✓ data_grid, ✓ tabs; + `EdenCustomerHeader` w/ pin/star/chat icons, + `EdenAttentionBanner`, + `EdenQuickActionsBar` (3 tabs: contacts/work/transactions) |
| projects | 12 | `pages/Projects.tsx`, `pages/ProjectTracking.tsx` | admin | cross | ✓ data_grid, ✓ workflow_stepper; + `EdenFullProcessView` (timeline-style project lifecycle) |
| appointments | 7 | `pages/Schedule.tsx`, `components/appointments/` | both | cross | ✓ scheduler (enhanced per Wave B-trades-5), ✓ data_table |
| invoices | 10 | `pages/BillingCenter.tsx`, `components/invoices/` | admin | cross | ✓ data_grid; + `EdenReadyToBillSection`, + `EdenBillingPipeline` (status-buckets bar) |
| payroll | 11 | `pages/PayrollAudit.tsx` | admin | cross | ✓ data_table; + `EdenApprovalChain` (multi-step approval ladder w/ avatars + states), + `EdenDailyBreakdownTable`, + `EdenPayPeriodNav` |
| team | 15 | `pages/TeamMembers.tsx` | admin | cross | ✓ data_grid; + `EdenOrgView` (org-chart layout — reuses A4-a canvas), + `EdenDepartmentCard`, + `EdenMemberHeader` w/ certifications/skills strip |
| documents | 5 | `pages/Documents.tsx`, `pages/ProjectDocuments.tsx` | both | cross | ✓ file_list_tile, ✓ document_viewer; + `EdenDocumentStatusBadge` (sig/approval states — partially exists) |
| notifications | 7 | `pages/Notifications.tsx`, `services/push-notification` | both | cross | ✓ notification_list; + `EdenNotificationPreferences` panel |
| tasks | 6 | `pages/Tasks.tsx` (3113-LOC monolith — flag for decomp) | both | cross | ✓ task_list, ✓ data_grid, ✓ workflow_stepper |
| analytics | 12 | `pages/Analytics.tsx` | admin | cross | ✓ chart, ✓ stat_card; + `EdenBlockingRiskCard`, + `EdenCustomerHealthCard`, + `EdenRevenueTrendChart` (preset shape) |
| callbacks | 7 | `pages/Callbacks.tsx` | both | trades-flavored cross | ✓ data_grid; + `EdenSentimentIndicator`, + `EdenResponseTimeBadge` — **gen-useful for helpdesk, retail returns, medical follow-up** |
| change_orders | 5 | `components/changeOrders/` | admin | trades-flavored cross | ✓ data_grid, ✓ workflow_stepper; uses `EdenApprovalChain` from payroll |
| status_sheets | 6 | (no direct React peer) | admin | trades | + `EdenStatusSheetView` (multi-project status board) — flag for review whether this lives in lib or only in trades feature folder |
| auth | 6 | `pages/Login.tsx`, `components/auth/` | both | cross | ✓ eden_login_page, ✓ eden_splash_page |
| home | 5 | `pages/Forefront.tsx`, `pages/Dashboard.tsx`, `components/forefront/` (6 role panels) | both | cross | + **`EdenRoleDashboardShell`** — role-specific home (Head/Lead/Dispatcher/Tech/Admin variants). **Promote to Wave A — every vertical needs it.** + `EdenDispatchMap` (companion of A4 EdenMapPreview) |
| admin | 38 | `pages/Settings.tsx`, `pages/Customizations.tsx`, `components/customizations/sections/` (10 sections) | admin | cross | ✓ settings_section/settings_tile; + `EdenCustomFieldsEditor`, + `EdenFeatureFlagsSection` (already have feature_flag_row), + `EdenIntegrationsPage` shell, + `EdenWorkCategoriesEditor` |
| onboarding | 11 | (split between Landing.tsx + new-tenant flow) | both | cross | + **`EdenAppTourOverlay`** (showcase-based: trades-flutter uses `showcaseview` already in pubspec), + `EdenStarterTemplateCard`, + `EdenContextualTip` — **already in 2026-05-02 doc, surface again** |
| portal | 9 | `pages/CustomerPortal.tsx`, `pages/SubcontractorPortal.tsx` | admin-rendered (web embed) | cross | ✓ scaffolds; portal lives in Templ (Go-side) per `SALON_VERTICAL_UX_PLAN`; Flutter portal version is alternative |
| equipment | 5 | (component-level, no top page) | admin | trades | ✓ data_grid, ✓ description_list |
| maintenance | 6 | `pages/Maintenance.tsx` | admin | cross | ✓ kanban; + `EdenMaintenanceKanbanCard` shape (preset of kanban_card) |
| subcontractors | 12 | `pages/Subcontractors.tsx` | admin | cross | ✓ data_grid; + `EdenInsuranceComplianceCard` (W9/cert tracking) — **reuses `eden_compliance_badge` and `eden_certificate_card`** |
| ai_search | 3 | (via command palette) | both | cross | ✓ command_palette, ✓ sources_footer |
| process_builder | 14 | `customizations/processes/visual-builder/` (21 files) | admin | cross | **A4-a sub-system port (§2.1)**; + `EdenSwimlaneCanvas` if shipping trades-flutter's metaphor in parallel |
| agent_builder | 15 | (no direct peer — Flutter-only feature; aoid/aodex-adjacent) | admin | cross | ✓ ai/, ✓ agent_decision_log, ✓ agent_run_card; + `EdenRuleEditorCanvas` (rules-as-flowchart — reuses A4-a canvas), + `EdenMcpToolPanel`, + `EdenPersonaSessionPanel` |
| templates | 12 | `pages/Templates.tsx`, `components/templates/` (block-based) | admin | cross | + **`EdenBlockBuilder`** — block-palette + drag-to-canvas + variables-panel. **Third visual-builder** alongside A4-a and A4-b. Likely a fourth `eden_diagram` consumer. |

### Band 2 — Trades-flavored (lib/features/trades/, vertical-gated)

| Folder | #dart | React peer | Target shell | Library asks |
|---|---|---|---|---|
| bidding | 14 | `pages/Bidding.tsx`, `pages/Bids.tsx` | admin | + `EdenWinProbabilityCard`, + `EdenBidPipelineChart`, + `EdenStreamingEstimateSheet` (LLM streaming output panel — reuse `eden_streaming_indicator`), + `EdenEstimateReviewSheet` |
| inventory | 19 | `pages/Inventory.tsx`, `components/purchasing/` | both | ✓ stock_level_indicator (port pending); + `EdenLocationTree` (nested location picker), + `EdenStockAlertsSection`, + `EdenInventoryTrackingPage` shell |
| purchasing | 25 | `pages/Purchasing.tsx`, `pages/PurchasingDashboard.tsx`, `pages/Deliveries.tsx` | admin | ✓ data_grid; + `EdenPoPipeline` (PO state board), + `EdenMaterialStatusGrid`, + `EdenSupplierSidebar`/`EdenSupplierDetailPanel` |
| fleet | 17 | `pages/Fleet.tsx` (2442-LOC monolith) | admin (+ companion truck view) | + **`EdenFleetStatCards`**, + `EdenTruckInventorySection`, + `EdenMaintenanceHistorySection`, + `EdenCrewSection` (truck-crew assignment), + `EdenTodaysScheduleSection` (per-truck day view) |
| job_records | 9 | (no top React page) | admin | ✓ data_grid; + `EdenJobRecordFilters` (faceted filter rail), + `EdenJobRecordCard` |
| forefront | 10 | `pages/Forefront.tsx`, `pages/Dashboard.tsx`, `components/forefront/*` (6 role panels) | both | **`EdenRoleDashboardShell` (Wave A promotion)** + section primitives: `EdenBlockedWorkSection`, `EdenIncomingWorkSection`, `EdenNeedsYourActionSection`, `EdenAiInsightsSummary` |
| incomplete_work | 3 | `pages/IncompleteWork.tsx` | admin | ✓ data_grid (composition; no new primitive) |
| finance | 3 | `pages/PayrollAudit.tsx` adjunct | admin | (memory extraction — backend-only) |

### Band 3 — Companion field/mobile (companion build target)

| Folder | #dart | React peer | Target shell | Library asks |
|---|---|---|---|---|
| schedule | 25 | `pages/Schedule.tsx` (3140-LOC monolith), `pages/SchedulePopout.tsx` | both | + **`EdenScheduler` enhancement** (Wave B-trades-5 already planned): drag-reschedule, resource swimlanes, mobile-gesture variant; + `EdenScheduleAiSidebar`, + `EdenIncomingWorkQueue`, + `EdenDispatchTruckList`, + `EdenMiniCalendar` (already partial) |
| dispatch | 4 | `components/forefront/DispatchMap.tsx`, `pages/Map.tsx` | both | + `EdenDispatchPage` shell — composes scheduler + map + crew list; reuses A4 EdenMapPreview |
| field_crew | 17 | `components/fieldService/{DigitalInspectionForm,HandwrittenNoteConverter,OfflineIndicator}` | companion | + **`EdenInspectionFormPage`** (form-with-photos pattern), + **`EdenSignatureCapturePage`** (full-screen sig flow on top of `eden_signature_pad`), + `EdenFieldNotesPage`, + `EdenPackoutPage` (truck-load checklist), + `EdenPhotoCapturePage`, + `EdenCheckInPage` (GPS clock-in), + `EdenLocationMapPage` (full-bleed map view), + `EdenOfflineQueuePage` (uses 2.3 EdenOfflineQueueViewer) |
| mobile_home | 16 | (mobile equivalent of `pages/Forefront.tsx`) | companion | + **`EdenMobileQuickAccessGrid`** (icon-tile launcher — visible in `mobile-forefront.png`), + `EdenMobileBottomNav` (already partial — reorderable tabs per `mobile-forefront.png` "Reorder" affordance), + `EdenMobileInsightCard`, + `EdenMobileAiFab` + `EdenMobileAiChatSheet` (FAB + bottom sheet) |

**Companion-build mode flag pattern (per VSO Path α):** all four Band-3 folders live in `eden-biz-flutter/lib/features/<folder>/companion/` and register routes only when `AppMode.fieldCompanion`.

---

## 4. Donor map — trades-react → eden-ui-flutter

trades-react has 65 shadcn primitives + ~20 bespoke. Most of the shadcn primitives have eden-ui-flutter equivalents already. The **bespoke** ones are donation candidates:

| trades-react UI primitive | eden-ui-flutter status | Action |
|---|---|---|
| `address-fields-group.tsx` | ✗ missing | **Donate as A4 `EdenAddressInput`** (parent assessment Wave A; this is the canonical donor source) |
| `address-preview-card.tsx` | ✗ missing | **Donate as A4 `EdenMapPreview`** companion (read-only address card with map thumb) |
| `google-places-autocomplete.tsx` | ✗ missing | Donate as **default provider impl** for `EdenMapProvider` interface (per pluggable adapter locked decision) |
| `map-pin-picker.tsx` | ✗ missing | Donate; pairs with A4 EdenAddressInput for "pick on map" UX |
| `navigation-address-field.tsx` | ✗ missing | Donate; this is the routing-aware variant (turn-by-turn-friendly) |
| `signature-pad.tsx` | ✓ `eden_signature_pad.dart` exists | Verify parity; trades-react version may have witness-signature affordance |
| `status-badge.tsx` | ✓ `eden_status_badge.dart` exists (recently donated) | Verify; likely duplicate of trades-flutter port |
| `responsive-tabs.tsx` | ✓ `eden_tabs.dart` | Verify breakpoint handling matches |
| `mobile-data-list.tsx` | ◐ partial (data_grid has mobile mode) | Compare; may surface enhancement to `eden_data_grid` |
| `authenticated-image.tsx` | ✗ missing | Donate as `EdenAuthenticatedImage` — wraps `eden_attachment_preview` with per-tenant signed-URL auth header injection (matches obj 018-02 backend work) |
| `empty-state.tsx` | ✓ `eden_empty_state.dart` | skip |
| `error-boundary.tsx` | ✗ missing | Donate as `EdenErrorBoundary` — Flutter equivalent (composition + ErrorWidget builder) |
| `file-upload.tsx` | ✓ `eden_file_upload.dart` | Verify scan/CUI states (Wave C C9) |
| `loading-spinner.tsx` | ✓ `eden_spinner.dart` | skip |
| `clickable-title.tsx` | ✓ ad-hoc in eden-ui-flutter | skip |
| `sidebar.tsx`, `sidebar-collapse-header.tsx` | ✓ `eden_layout/` | Verify trades-react has features eden_layout doesn't |
| `work-type-legend.tsx`, `work-type-selector.tsx` | ✗ missing | Donate? Trades-specific; better in `eden-biz-flutter/lib/features/trades/` |
| `input-otp.tsx` | ✗ missing | Donate as `EdenInputOtp` — useful for SMS-verify in A7 (`EdenPhoneInput`) and Wave C MFA |
| `chart.tsx` | ✓ `eden_chart.dart` | Verify; trades-react chart is recharts-based |

**Layout-level donors (`components/layout/`):**

| trades-react | eden-ui-flutter | Action |
|---|---|---|
| `AppLayout.tsx` | ✓ `eden_layout/` desktop+mobile | skip |
| `MobileBottomNav.tsx` | ◐ `eden_bottom_nav` exists | Compare; trades-react version has reorder UX (`mobile-forefront.png` "Reorder") — port if missing |
| `Navbar.tsx` | (handled per-app) | skip |
| `NetworkStatusBar.tsx` | ✗ missing | Donate as `EdenNetworkStatusBar` — top-of-app bar showing online/offline + retry count |
| `PageHeader.tsx` | ✓ `eden_page_header` (iPhone-narrow fix already landed) | skip |
| `QuickActionBar.tsx` | ✗ missing | Donate as `EdenQuickActionBar` — bottom action strip (pin/chat/call/print row visible in `mobile-customer-detail.png`) |
| `SideNavigation.tsx` | ✓ `eden_layout/` | skip |
| `UXModeToggle.tsx` | ✗ missing | Donate as `EdenUxModeToggle` — useful for the companion-app mode flag UX (Path α v1) |

---

## 5. Revised Wave B-trades component list

Replaces the 5-item B-trades list in the parent assessment (`VERTICAL_COVERAGE_ASSESSMENT_2026-05-15.md` §3 Wave B). New count: **18 component groups**, organised by sub-track.

### B-trades-A — Field/companion (8 components, ≈2 wk)

- B-T-A1 `EdenInspectionFormPage` — checklist + photo strip + signature + GPS metadata.
- B-T-A2 `EdenSignatureCapturePage` — full-screen sig flow above `eden_signature_pad`.
- B-T-A3 `EdenPackoutPage` — truck-load checklist with sub-counts.
- B-T-A4 `EdenPhotoCapturePage` — full-screen capture with categorisation (before/during/after).
- B-T-A5 `EdenCheckInPage` — GPS clock-in/out with map confirm.
- B-T-A6 `EdenLocationMapPage` — full-bleed map view (composes A4 map provider).
- B-T-A7 `EdenMobileQuickAccessGrid` — icon-tile launcher (companion home).
- B-T-A8 `EdenMobileAiFab` + `EdenMobileAiChatSheet` — FAB + bottom sheet variant of AI panel.

### B-trades-B — Dispatch/scheduling (5 components, ≈2-3 wk; supersedes B-T1..B-T5 in parent doc)

- B-T-B1 ⚠ enhance `EdenScheduler` — drag-reschedule, resource swimlanes, mobile gesture variant. **2026-05-02 Wave 1 port; still owed.** Largest single item.
- B-T-B2 `EdenScheduleAiSidebar` — AI insight rail next to scheduler.
- B-T-B3 `EdenIncomingWorkQueue` — sticky lane of unscheduled work, drag target into scheduler.
- B-T-B4 `EdenDispatchTruckList` — sidebar showing trucks + crew + current assignment.
- B-T-B5 `EdenDispatchMap` — map view with truck pins + ETA — composes A4 map provider.

### B-trades-C — Admin domain primitives (5 components, ≈1.5 wk)

- B-T-C1 `EdenWinProbabilityCard` + `EdenBidPipelineChart` (bidding).
- B-T-C2 `EdenPoPipeline` + `EdenMaterialStatusGrid` (purchasing).
- B-T-C3 `EdenFleetStatCards` + `EdenTruckInventorySection` + `EdenMaintenanceHistorySection` (fleet).
- B-T-C4 `EdenInsuranceComplianceCard` (subcontractors — composes `eden_compliance_badge` + `eden_certificate_card`).
- B-T-C5 `EdenApprovalChain` (payroll + change_orders — multi-step approver ladder).

### B-trades-Cross — Cross-vertical primitives surfaced during this audit (promote to Wave A)

These were surfaced inside trades feature folders but apply to **every** vertical. Promote from B-trades to Wave A in the parent assessment.

- A9 (new) `EdenRoleDashboardShell` — role-specific home shell with section slots (Head/Lead/Dispatcher/Tech/Admin variants in trades; salon = Owner/Stylist/Front-desk; medical = Doctor/Nurse/Front-desk; gov = Caseworker/Supervisor/Auditor).
- A10 (new) `EdenAppTourOverlay` + `EdenContextualTip` + `EdenStarterTemplateCard` — onboarding triplet. Uses `showcaseview` Flutter package (already in trades-flutter pubspec).
- A11 (new) `EdenOfflineQueueViewer` — list of queued mutations + conflict resolution. Companion-app prereq; also useful for any disconnected workflow.
- A12 (new) `EdenAuthenticatedImage` — wraps `eden_attachment_preview` with per-tenant signed-URL auth header injection (matches obj 018-02 backend).
- A13 (new) `EdenNetworkStatusBar` — top-of-app online/offline indicator.
- A14 (new) `EdenQuickActionBar` — bottom action strip (pin/chat/call/print row, contextual to current detail screen).

**Net effect on parent assessment:** Wave A grows from 8 to **14** components, ≈4-5 wk (was 3-4 wk). Wave B-trades grows from 5 to **18** components, ≈5-6 wk (was 2-3 wk). Wave C unchanged.

---

## 6. Sub-system tracks (additions to wave plan)

| Track | Scope | Effort | Depends on |
|---|---|---|---|
| **A4-a Visual Process Canvas port** | 21-file React Flow → Flutter port via `eden_diagram` extension | ≈4 wk | None (independent) |
| **A4-b Workflow Designer port** | 20-file React Flow → Flutter port, reuses A4-a canvas | ≈2 wk | A4-a |
| **A4-c Template Block Builder port** | trades-flutter `templates/builder_canvas` + trades-react templates components | ≈2 wk | A4-a (canvas engine) |
| **A5 Role Dashboard Shell** | `EdenRoleDashboardShell` + section primitives (Block, Need-action, Insights-summary) | ≈1.5 wk | A1+A2 scaffolds |
| **D-infra Companion build target + offline fabric** | Path α mode flag + offline queue widgets + websocket-channel viewer | ≈2 wk | Wave A done |

**Recommended sequencing:**
1. Wave A (now expanded to 14 components, 4-5 wk) — runs in parallel with everything else.
2. A4-a Visual Process Canvas — starts as soon as `eden_diagram` engineer is free; gates B-trades-B (which uses canvas for swimlane variant).
3. B-trades-A (companion field surface) — starts after Wave A scaffolds land; runs while A4-a is in flight.
4. A4-b + A4-c — sequential after A4-a.
5. B-trades-B (dispatch/scheduling enhancement) — after A4-a (uses canvas for swimlane).
6. B-trades-C (admin domain primitives) — anywhere after Wave A; smallest, easiest fillers.

**Estimated total trades-remap library effort:** ≈14-18 weeks (was ~6-8 wk in parent assessment). Roughly 50% of that is the three A4 visual builders.

---

## 7. Decisions locked (2026-05-15, resolved with Mark)

1. **Process builder metaphor — support BOTH, default swimlane.**
   `eden_diagram` extension exposes two layout engines: swimlane (default, "likely works better" per Mark) and free-form canvas. Same node model + dialogs; layout-engine swap is a single API choice at canvas instantiation. Process builder itself **stays generic** (vertical-agnostic): node grammar + entity-type + permissions all configurable per vertical via registry.
   *How to apply:* A4-a sub-system port targets generic canvas engine first, then registers swimlane layout, then free-form. Both ship in v1. Trades-flutter `swimlane_canvas.dart` is the primary swimlane donor; trades-react `VisualProcessCanvas.tsx` is the primary free-form donor.

2. **Process builder entity-type — make it generic (registry-driven, not enum-locked).**
   Current trades-go enum lock (`project / appointment / bid` only) is a remap-blocker for fuel-delivery, salon, medical, gov. Replace with a registry/plug-in: verticals register their entity types (`fuel_delivery`, `service_visit`, `case`, `appointment`, `project`, etc.).
   *How to apply:* backend work in trades-go BEFORE A4-a UI port lands; otherwise the canvas can render but can't bind to anything outside trades' three entity types. Flag for trades-go cleanup. Open question: does this work happen pre-absorption (in trades-go) or after the codebase absorbs into eden-biz-go?

3. **A4-b workflow `entity_created` bug — fix it.**
   trades-go workflow automation trigger types missing `entity_created` in Zod enum → workflows never auto-fire. Fix lands as part of the absorption (decision 6 below), NOT as a Flutter UI ticket.
   *How to apply:* A4-b port stays unblocked at the UI layer; backend fix is sequenced into the trades→eden-biz absorption epic.

4. **Monolith decomposition during port — yes, decompose, do not 1:1 translate.**
   Fleet.tsx (2442 LOC), Schedule.tsx (3140 LOC), TasksView.tsx (3113 LOC) in trades-react. Each decomposes into 4-6 Flutter sub-files following trades-flutter's `<feature>/presentation/{page,widgets/*}.dart` shape. Decomposition planning happens inside each port objective, not as a separate refactor.
   *How to apply:* port objectives include "decomposition plan" as a deliverable. Reviewer checks for 1:1 monolith translations and rejects.

5. **Companion mode default — UX optimization target: simple, on-the-go.**
   Selection mechanism still open (screen size / JWT claim / first-launch picker), but the design goal is locked: **companion mode must privilege on-the-go simplicity** — fewer routes, larger touch targets, gesture-first, minimal admin chrome. The mechanism follows from the UX; recommend screen-size auto-detect (mobile breakpoint → companion) + a one-tap escape hatch to admin mode for users who want it. Resolve at B2 implementation time.
   *How to apply:* B-trades-A (field/companion) components default to gesture-first; admin variants of same screens (e.g., schedule admin view) are different components, not toggle-mode variants of the same widget.

6. **trades-flutter `multi-model-adaptive` branch (218 commits ahead) — ABSORB into eden-biz, do not maintain as a parallel app.**
   Big reframe: **trades-flutter as a separate app goes away.** Its content distributes per `VERTICAL_SKIN_ARCHITECTURE.md`:
   - **Admin features** (≈32 of 36 folders per Band 1+2 above) → land in `eden-biz-flutter/lib/features/<feature>/` with `business_vertical=trades-hvac` gating.
   - **Companion/field surface** (Band 3: schedule mobile, dispatch, field_crew, mobile_home) → land as the **trades-companion-app build target** of `eden-biz-flutter` (Path α — single binary + mode flag).
   - The `multi-model-adaptive` 218-commit delta gets analyzed + folded in as part of the absorption.
   *How to apply:* **spawn a research agent** to inventory `multi-model-adaptive` vs `main`, classify changes by feature folder, and produce an absorption plan (atomic commits or one big merge? per-folder or all-at-once?). This is the next concrete action after Wave A planning.

7. **`agent_builder/` — likely cross-vertical OR within-vertical (kept open).**
   trades-flutter ships a rich agent-builder (15 files, `rule_editor_canvas`, `mcp_tool_panel`, `persona_session_panel`). Overlaps with aodex/aosentry agent surfaces.
   *How to apply:* during absorption (decision 6), the absorption-plan agent flags `agent_builder/` for explicit placement decision. Default landing zone: cross-vertical under `lib/features/agent_builder/`, vertical-gated only if a vertical needs to hide it. Re-evaluate once aocyber agent infra (AOCore-aware FedRAMP design principles) crystallizes.

## 8. Next concrete actions

| # | Action | Owner | Blocker |
|---|---|---|---|
| 1 | Spawn absorption-plan agent — inventory `multi-model-adaptive` (218 commits ahead) vs trades-flutter `main`; classify by feature folder; produce trades→eden-biz absorption plan with atomic-commit strategy. | Research agent | None — can start immediately |
| 2 | `/df:plan-objective` Wave A (now 14 components, 4-5 wk) as single eden-libs objective; pull donor map from §4 as concrete starting material. | df-planner | None |
| 3 | Backend ticket — trades-go: remove process-builder entity-type lock + add `entity_created` workflow trigger. Sequenced with absorption epic (decision 6). | trades-go planner | None; can run parallel to absorption analysis |
| 4 | `/df:plan-objective` A4-a Visual Process Canvas + Swimlane port (4 wk) — depends on absorption analysis (decision 6) to confirm trades-flutter swimlane donor is current. | df-planner | Action 1 complete |
| 5 | Companion-app build target B2 spec — locks decision 5 (mode selection mechanism); produces eden-biz-flutter PR setting up the dual-mode build pipeline. | eden-biz-flutter planner | None (can run parallel) |

---

*Generated 2026-05-15. Companion to `VERTICAL_COVERAGE_ASSESSMENT_2026-05-15.md` and `EDEN_UI_FLUTTER_COMPONENT_OPPORTUNITIES.md` (2026-05-02). Lives in `eden-libs/eden-ui-flutter/.planning/` alongside the parent assessment.*
