# Absorption Research — AOCore / Platform / AO Identity

**Date:** 2026-05-15
**Companion to:** `TRADES_FLUTTER_ABSORPTION_PLAN_2026-05-15.md` (§7 open research actions)
**Method:** read-only inventory across `eden-libs/`, `aocyber-compliance/`, `aosentry-*/`, `aodex-*/`, `AOCyber-Trades/trades-flutter/` + GitHub issue / branch search on `AO-Cyber-Systems`
**Author:** absorption-research agent

---

## TL;DR

All three open research questions resolve in the **same direction**: the work that the absorption plan treated as "may need to invent" is **already substantially in flight on `eden-platform-go` origin/main**, surfaced through `eden-libs/eden-ai-dart` + `eden-ai-flutter` for Flutter consumers.

| Q | Status | Recommendation |
|---|---|---|
| **Q5 — AOCore client lib** | `eden-libs/eden-ai-dart` ships a full AOSentry/AI-gateway client (5 files, ~1 025 LOC), `eden-ai-flutter` ships the Riverpod providers (4 files). Already on `feature/multi-model-adaptive` of the eden-libs monorepo. | **Option (c) "keep `aodex_client.dart` name pending consolidation" is OBSOLETE.** Adopt `eden-ai-dart`'s `AosentryClient` + `eden-ai-flutter`'s `aosentryClientProvider`. Delete trades-flutter's `aodex_client.dart` + `aodex_models.dart` in the absorption; map per-method to the eden-ai-dart equivalents and the small delta (knowledge_collections, conversations, personas write paths) goes into eden-ai-dart as targeted additions. |
| **Q1 — eden-platform-flutter Connect shape** | Real ConnectRPC transport via `connectrpc/connect.dart` + `eden_platform_api_dart` codegen; `AuthService`, `CompanyService`, `RegistryService`, `RbacService`, `WebhookService` clients live. Auth has full session + secure token storage + SSO. Entitlements layer exists. Nav layer exists. | **Donate trades' `ConnectClient` upward IS NOT NEEDED.** trades-flutter's Dio-based `ConnectClient` is a Connect-over-Dio shim invented because the codegen path wasn't yet available. Replace with platform-flutter's generated Connect transport in Phase 2. Auth folder fully discardable per locked Q4. RBAC has a different mental model in platform-flutter (`canUseFeature(entitlement)` vs `hasPermission(perm)`) — Q2 keeps the trades-style RBAC in biz, so this is a **net add** not a collision. |
| **Q2 — AO Identity Service** | **IN FLIGHT and SHIPPING.** Objs 29/30/31 merged to origin/main as `cmd/aoid/` + `internal/aoid/{clients,composition,discovery,federation,...}`. AODex registered as pilot client. ws-ao-id-pilot-aodex branch active. AOID has working PKCE + token issuance + refresh rotation + /userinfo + ML-DSA-65 JWT signing. | RBAC migration to AOID is a **months-horizon**, not idea-only. Biz admin RBAC PR (Q2 lock) should include a documented migration path: today = biz-owned RBAC table; future = AOID issues scoped JWT, biz consumes `Scopes` claim. Reference the existing `platform/auth` Scopes claim work (PR #19, 2026-05-15). |

The headline reframe for the absorption plan §7 / §8:

- **Phase 0 decisions on Q5 and Q1 are easier than expected** — the answers are "use the existing eden-libs/eden-ai-* packages" and "use the existing eden-platform-flutter Connect stack."
- **Phase 2 infra reconciliation shrinks** — no need to design a Connect channel or AOCore lib placement from scratch. The reconciliation work becomes "wire the trades-flutter repositories onto the existing stacks + close small API deltas in eden-ai-dart."
- **The plan's "AOCore lib is in-flight per memory" rumour is confirmed and richer than expected.** AOID is real, partially merged, AOSentry-client (`platform/aigateway`) is real and beta-stable.

---

## Section 1 — AOCore client lib status (Q5 unblock)

### 1.1 What exists today — the big finding

**`eden-libs/eden-ai-dart`** ships a complete AOSentry HTTP client + ecosystem packages. Lives at `/Users/markemerson/Source/eden-libs/eden-ai-dart/`. Branch: `feature/multi-model-adaptive` (the eden-libs monorepo branch). Latest commit on relevant files: `56155d9` (chore: gitignore), feature work was `e023f2f` (Riverpod 3.x migration, 21-03), `7de30e0` (intelligence engine tests, 21-06), `cd09b6e` (MemoryStore + InMemoryStore).

Files (commit refs to feat commits in chronological order):

| File | LOC | First-introduced commit | Purpose |
|---|---|---|---|
| `lib/src/aosentry/client.dart` | 248 | `beb6be7` feat(15-05) | Full HTTP client: chat (sync + stream), embeddings, web_search, web_fetch, image gen, audio (TTS + STT), guardrails, PII, prompt refine, list models, health, spend, budget, feedback. 16 methods. |
| `lib/src/aosentry/types.dart` | 519 | `beb6be7` feat(15-05) | All request/response types |
| `lib/src/aosentry/catalog.dart` | 150 | `beb6be7` feat(15-05) | Model catalog client |
| `lib/src/aosentry/errors.dart` | 82 | `beb6be7` feat(15-05) | Typed error mapping |
| `lib/src/aosentry/stream.dart` | 26 | `beb6be7` feat(15-05) | SSE parsing for chat stream |
| `lib/src/chat/request_builder.dart` + `response_parser.dart` + `vision.dart` | — | `aa40b17` feat(15-02) | Chat request/response abstractions, vision support |
| `lib/src/skills/skill.dart` + `skill_step.dart` | — | `402389a` feat(15-03) | Skill orchestration contracts |
| `lib/src/memory/types.dart` + `store.dart` | — | `cd09b6e` feat(21-03) + `2c2fada` feat(15-04) | Memory layer w/ InMemoryStore + 14 tests |
| `lib/src/spend/types.dart` | — | `f8058e5` feat(15-04) | Spend/budget types |
| `lib/src/metadata/builder.dart` + `intelligence_context.dart` | — | `5de1a8c` feat(21-02) + `f8058e5` | Intelligence context fluent builder |

Exports are unified through `lib/eden_ai_dart.dart` as a single library entry point.

**`eden-libs/eden-ai-flutter`** ships the Riverpod 3.x reactive wrappers:

| File | LOC | Commit | Purpose |
|---|---|---|---|
| `lib/src/providers/ai_chat_provider.dart` | ~40 | `f94c4d3` feat(15-06) → `e023f2f` Riverpod 3.x migration | `aosentryClientProvider`, `chatProvider`, `chatStreamProvider`, `embeddingsProvider` |
| `lib/src/providers/skill_provider.dart` | — | `f94c4d3` | Skill detection/routing providers |
| `lib/src/providers/budget_provider.dart` | — | `f94c4d3` | Budget/spend providers |
| `lib/src/providers/intelligence_context_provider.dart` | — | `5de1a8c` feat(21-02) | Intelligence context binding |

Pattern matches the locked global preference of host-app-overrides-provider: `aosentryClientProvider.overrideWithValue(AosentryClient(baseUrl: ..., apiKey: ...))` at `ProviderScope` time.

**`eden-libs/eden-ai-go`** is the Go counterpart — same packages (chat, embed, intelligence, memory, prompt, orchestration, spend, skills, metadata) for backend services. Confirms eden-ai-* is the **cross-language platform AI SDK**.

**On the FedRAMP/AOCore side:**

| Artifact | Location | Status |
|---|---|---|
| `aosentry` issue #25 `[Objective 7] AOCore-Aware Design Hooks` | `https://github.com/AO-Cyber-Systems/aosentry/issues/25` | OPEN; 6 success criteria covering audit dual-emit + identity context header shape + LLM-egress allowlist + internal mTLS + OSCAL pinning + AOID-carve-out readiness checks. Created 2026-05-14. |
| `aosentry/internal/auth/` AOID-carve-out interface | aosentry repo | Per AOCORE-06 success criterion — every PR touching `internal/auth/` runs an AOID-carve-out-readiness check |
| `eden-platform-go/platform/aigateway/` | eden-platform-go origin/main | **The AOSentry-client implementation.** 27 files (chat, audio, embeddings, guardrails, images, moderation, pii, prompts, stream, transport). README + MIGRATION.md. Consolidates 7 prior AOSentry-client forks per memory. |
| `eden-platform-go/cmd/aoid/` | eden-platform-go origin/main | AOID service binary. Dockerfile + boot.go + main.go. |
| `eden-platform-go/internal/aoid/{clients,composition,discovery,federation,...}` | eden-platform-go origin/main | AOID internals: client registry, OIDC discovery, JWKS, federation surface, ML-DSA-65 JWT signing |

### 1.2 What's in-flight (not yet merged)

| Branch / PR | Repo | Scope |
|---|---|---|
| `ws-ao-id-pilot-aodex` | eden-platform-go | AOID pilot integration with AODex. Already PR-merged as #14 (`1662939` "Obj 30 Phase A: activate AO ID OIDC issuer + register AODex client") but branch still active. |
| `feature/multi-model-adaptive` | eden-libs (this branch) | Where the eden-ai-dart + eden-ai-flutter packages live; pending merge to eden-libs main. |
| `feature/multi-model-adaptive` | aosentry | 100 unpushed commits + 2 stashes (per memory). Reserved — DO NOT disturb per `project_aocore_aware_fedramp_2026-05-14.md`. |
| `fedramp-prep` | aosentry-fedramp-prep worktree | FedRAMP Phase 1 isolated work; 5 objectives (008–012) covering audit-logger-wiring + LLM-proxy-audit + data-access-audit + admin-UI audit coverage + polish/deploy. None of these are client-library work — all are AOSentry-server hardening. |

**Planning docs that mention AOCore client work:**

- `/Users/markemerson/Source/aocyber-compliance/.planning/AOCORE_VS_FEDRAMP_REVIEW.md` — exists; review of how Justin's AOCore vision relates to the FedRAMP scope.
- `/Users/markemerson/Source/aosentry-fedramp-prep/.planning/AOCORE_VISION.md` — Justin's AOCore vision doc.
- No `.planning/` doc mentions client-library work that's distinct from what `eden-ai-dart` + `eden-ai-flutter` already ship.

**`aodex-flutter`** at `/Users/markemerson/Source/aodex-flutter/` is the AODex end-user app (separate from `aodex` Rails repo). It is not a shared lib — it ships its own AODex API client internally, scoped to the AODex product. **Not a candidate for trades-flutter to depend on.**

### 1.3 trades-flutter's parallel implementation

`AOCyber-Trades/trades-flutter/lib/shared/api/`:

| File | LOC | Method count | What it talks to |
|---|---|---|---|
| `aodex_client.dart` | 390 | 13 (`isAvailable`, persona CRUD, memory CRUD, semanticSearch, knowledge_collections CRUD, conversation create, `streamChat`) | AODex REST API (`/api/v1/personas`, `/memories`, `/search/semantic`, `/knowledge_collections`, `/conversations`, `/chat/stream`) — i.e. AODex Rails server, NOT the AI gateway |
| `aodex_models.dart` | 302 | 8 types (`AodexChatRequest`, `AodexStreamChunk`, `AodexPersona`, `AodexMemory`, `AodexSearchResult`, `AodexKnowledgeCollection`, `AodexConversation`) | — |
| `connect_client.dart` | 195 | 3 generic call shapes (`call`, `callList`, `callVoid`) | trades-go ConnectRPC (`/trades.v1.{Service}/{Method}`) — JSON-over-Dio shim, no protobuf codegen |
| `api_client.dart` | 346 | — | Generic Dio wrapper |

**Critical disambiguation:** trades-flutter's `aodex_client.dart` is talking to **AODex (the Rails app — personas, memories, knowledge collections, conversations, SSE chat)**, not to AOSentry (the AI gateway). These are **different upstream services**:

- **AODex** = the persona/memory/conversation persistence layer (Rails server, with knowledge_collections, semantic search, etc.)
- **AOSentry** = the AI gateway (model routing, guardrails, PII, spend tracking, embeddings, audio, etc.) — this is what `eden-ai-dart`'s `AosentryClient` talks to
- **`platform/aigateway`** (Go) = the in-process AOSentry-client library that backend services use to call the AOSentry gateway

So trades-flutter is using **AODex-direct** for persona/memory/conversation/streaming-chat surfaces. eden-ai-dart's AosentryClient covers the **gateway-side concerns** (chat/embed/guardrails/audio/spend). These are **complementary**, not duplicate.

### 1.4 Recommendation — Q5 resolution

**Pick: hybrid of (a) + (c) re-framed.**

The user's original three options were:
- (a) New shared lib at `eden-libs/eden-aocore-flutter/`
- (b) `eden-biz-flutter` level rename
- (c) Keep `aodex_client.dart` name pending consolidation

**Recommended actual path — option (d), born from the research:**

1. **Adopt `eden-ai-dart` + `eden-ai-flutter` as the AOSentry-gateway client layer.** Already exists. Don't create a new `eden-aocore-flutter` package. The naming is `eden-ai-*` and that's the canonical surface; AOSentry / AOCore are the products that the SDK targets.
2. **Keep the AODex-direct API surface (personas / memories / knowledge_collections / conversations / streaming chat) as an `AodexClient` separate from `AosentryClient`.** Two reasons:
   - They talk to different backends (AODex Rails app vs AOSentry gateway).
   - Eden-ai-dart exists today specifically as the AOSentry-gateway surface. The AODex-direct surface has no upstream donor yet.
3. **Plant the AODex-client donation in `eden-libs/eden-ai-dart/lib/src/aodex/` as a sibling of `aosentry/`.** Same package, two clients, one library. This avoids both:
   - The (a) penalty of a brand new package + workspace + pubspec churn.
   - The (b) penalty of letting biz own a client that other apps (aodex-flutter, eden-ai apps, future Eden apps) will also need.
4. **Trades-flutter's `aodex_client.dart` becomes the donor** for `eden-ai-dart/lib/src/aodex/client.dart`. Trades-flutter's 390 LOC is the largest existing AODex Flutter client in the workspace. Donate it; add Riverpod providers in `eden-ai-flutter/lib/src/providers/aodex_provider.dart` mirroring the AOSentry provider pattern.
5. **Eden-ai-flutter exports both** through `aosentryClientProvider` (already exists) and a new `aodexClientProvider` (host app overrides with base URL + token).
6. **Drop trades-flutter's `aodex_client.dart` + `aodex_models.dart` from absorption** — replace with `import 'package:eden_ai_flutter/eden_ai_flutter.dart';` in the W17/W18/W20 AI-streaming feature folders.

**Why this beats (a)/(b)/(c):**
- **vs (a)** new `eden-aocore-flutter` lib: there's no reason for a fourth Flutter package when eden-ai-dart already owns the AI/AOSentry surface and has the cross-language pair (eden-ai-go). A separate `eden-aocore-flutter` would mostly be re-exporting eden-ai-flutter.
- **vs (b)** biz-level rename: biz isn't the right owner because aodex-flutter, future verticals, and eden-ai sample apps would all need the same surface. Putting it in eden-biz forces upstream apps to depend on biz.
- **vs (c)** keep `aodex_client.dart` name: trades-flutter as an app sunsets (Q11 lock). The client either moves to eden-biz (option b) or to a shared lib (option a or d). Option (d) puts it at the right altitude — sibling to AOSentry under the AI SDK umbrella.

**Phase 0 effort delta:** Q5 unblock cost drops from "design + create new package + workspace plumbing" (~3-5 days) to "design two `eden-ai-dart/lib/src/aodex/` files + Riverpod provider + tests" (~1-2 days). The trades-flutter donor is already in good shape.

**Open question for Mark:** the FedRAMP/AOCore rename plan (`RENAME_PLAN.md` in aosentry, per memory) eventually renames aosentry → aocore. If that rename lands, do we also rename `eden-ai-dart/lib/src/aosentry/` → `lib/src/aocore/`? Recommend: defer; `aosentry/` matches the current server name. When the rename lands, it's a single-folder rename + export-line update in the eden-ai SDKs.

---

## Section 2 — eden-platform-flutter Connect/Auth/Nav/RBAC shape (Q1 follow-up)

`eden-libs/eden-platform-flutter/lib/src/` — 5 sub-areas, ~25 dart files.

### 2.1 Connect channel — real ConnectRPC, not a Dio shim

**File:** `lib/src/api/platform_repository.dart` (231 LOC).

- Uses `connectrpc/connect.dart` package (the real Connect-RPC Dart runtime — not a homemade Dio wrapper).
- Imports `package:eden_platform_api_dart/eden_platform_api_dart.dart` — codegen Dart Connect clients for `AuthService`, `CompanyService`, `RegistryService`, `RbacService`, `WebhookService`. Per `eden-libs/CLAUDE.md` package responsibilities, these are generated from `eden-platform-go/proto/platform/v1` and refreshed via `just generate`.
- `ConnectPlatformRepository` constructor: `createPlatformTransport(baseUrl: baseUrl)` returns a `Transport` — single channel reused for every method call.
- Auth header injection: per-call `Headers()` with `Authorization: Bearer ${accessToken}` (e.g., `listCompanies(accessToken)`, `listNavItems(accessToken, companyId)` — see lines 27–31 + 86–139).
- Retry policy: none in the repository. Connect's transport-level retries (if enabled in `createPlatformTransport`) apply. Failures are mapped to `PlatformError` taxonomy (`AuthError`, `NetworkError`, `ServerError`) via `_wrapConnectError` (lines 212–229) based on `ConnectException.code` (unauthenticated → `AuthError`, unavailable/deadline → `NetworkError`, others → `ServerError`).
- No multiplexing concern — it's vanilla Connect-over-HTTP/2 (or HTTP/1 + chunked).

**Per-RPC methods on `PlatformRepository`:**

| Method | RPC |
|---|---|
| `login(email, password)` | `AuthServiceClient.login` |
| `signUp(email, password, displayName)` | `AuthServiceClient.signUp` |
| `refreshToken(refreshToken)` | `AuthServiceClient.refreshToken` |
| `logout(refreshToken)` | `AuthServiceClient.logout` |
| `listCompanies(accessToken)` | `CompanyServiceClient.listCompanies` |
| `listNavItems(accessToken, companyId)` | `RegistryServiceClient.getNavItems` + `getBadgeCounts` |
| `initiateSSOForDesktop(provider, redirectUri)` | `AuthServiceClient.initiateOIDC` |
| `updateProfile(accessToken, displayName, avatarUrl)` | `AuthServiceClient.updateProfile` |

JWT parsing is in-repo (line 197 `_extractClaims`) — pulls `cid` (company id) + `role` claims out of the access token's base64-decoded payload.

### 2.2 Auth model

**File:** `lib/src/auth/auth_provider.dart` (219 LOC).

- `AuthState` is a discriminated state with statuses `unknown` / `refreshing` / `authenticated` / `unauthenticated` / `error`.
- `AuthNotifier` (a `StateNotifier<AuthState>`):
  - Wraps `PlatformRepository` + `TokenStorage`.
  - `login(email, password)` → persists tokens, transitions to `authenticated`.
  - `signUp(email, password, displayName)` — same shape.
  - `restoreSession()` — reads refresh token from storage, calls `refreshToken` RPC, transitions.
  - `loginWithSSO(provider, redirectUri)` — delegates to `SSOAuthService` (separate file). Desktop opens browser + captures callback; web redirects window.
  - `updateProfile(displayName, avatarUrl)` — calls `updateProfile` RPC.
  - `logout()` — calls `logout` RPC + clears stored tokens.
  - `_persistTokens(session)` writes access + refresh to storage. `_clearPersistedTokens()` clears.
- Token storage abstraction (`TokenStorage` interface):
  - Default impl: `SecureTokenStorage` using `flutter_secure_storage` 9.2.4 (Keychain on iOS, EncryptedSharedPreferences on Android). Includes transparent migration from `shared_preferences` for upgraded installs.
  - Tests override with fake.
  - Apps may override for app-managed encryption keys.
- Base URL resolution (line 48 `_resolvePlatformBaseUrl`):
  - `API_BASE_URL` env at compile time → win
  - Else `Uri.base` if http(s) + host → win
  - Else `http://localhost:8080` fallback
- Multi-tenancy:
  - JWT claim `cid` (company id) is extracted into `PlatformSession.companyId`. Nav and entitlements key off of it (see 2.3).
  - No explicit "tenant header" — multi-tenancy travels in the JWT claim, not as a separate request header.

### 2.3 Entitlements / RBAC — not RBAC, entitlements

**Files:** `lib/src/entitlements/{entitlements_models.dart, entitlements_repository.dart, entitlements_provider.dart, feature_gate.dart, quota_bar.dart, plan_badge.dart}` (~6 files).

**This is NOT trades-style RBAC.** Different mental model:

- Platform-flutter has `PlatformSubscription`, `PlatformPlan`, `PlatformEntitlement` (with `isQuota` flag and `allowed` boolean), `PlatformFeatureFlag`.
- `EdenFeatureGate(feature: 'knowledge_base', child: ..., fallback: UpgradePrompt(...))` — gates UI on whether the **subscription plan grants this feature**.
- `EdenFlagGate(flag: 'new_chat_ui', child: ..., fallback: ...)` — gates on feature flag.
- `canUseFeatureProvider(featureKey)` returns `false` while loading (deny-by-default).
- `entitlementsRepositoryProvider` defaults to `HttpEntitlementsRepository(baseUrl: 'http://localhost:9090')` — i.e. it expects an Eden Biz endpoint. Apps override per `ProviderScope`.

**Comparison with trades-flutter RBAC:**

| Dimension | trades-flutter | eden-platform-flutter |
|---|---|---|
| Concept | Permission strings (`'customers:create'`) | Feature keys (`'knowledge_base'`) + flags |
| Granularity | 99 per-action perms | Plan-bundle feature entries |
| Use case | "Can this user (role) take this action?" | "Does this company's subscription plan grant this feature?" |
| Multi-vertical? | Trades-specific perm list | Plan/entitlement-driven, vertical-agnostic |
| Backend tie | trades-go user.permissions[] | Eden Biz subscriptions + plans + entitlements + feature_flags |
| Provider shape | `hasPermissionProvider(perm)` | `canUseFeatureProvider(featureKey)` |

**Critical insight for Q2:** the locked Q2 decision is "RBAC lives in biz admin function for now; future migration to AO Identity Service." This means **the per-user permission model is NOT in platform-flutter today**. Platform-flutter's entitlements layer is **per-company subscription state**, not per-user permissions. The two are complementary:

- `EdenFeatureGate(feature: 'knowledge_base')` — does this company's plan include the feature?
- `PermissionGate(permission: 'customers:create')` — does this user, in this role, have this action perm?

So the trades-flutter RBAC layer **doesn't collide** with platform-flutter's entitlements — it's a different concept that **adds** alongside. Per Q2, it lives in biz, plugged into platform-flutter's auth session (consuming `auth.role` claim or fetching from a biz RBAC endpoint). The platform-flutter `EdenFeatureGate` continues to wrap subscription-level gating.

### 2.4 Navigation primitives

**Files:** `lib/src/navigation/{nav_provider.dart, sidebar.dart}` (~393 LOC total).

- `NavState` = `{isLoading, items: List<PlatformNavItem>, selectedId, errorMessage}`.
- `PlatformNavItem` model fields: `id, label, icon, path, feature, priority, section, badgeCount` (from `models/platform_models.dart`).
- `NavNotifier.loadForCompany(companyId)` calls `platformRepositoryProvider.listNavItems(accessToken, companyId)` → `RegistryServiceClient.getNavItems` + `getBadgeCounts`. **Nav items are server-driven** (not hardcoded client-side like trades' `navigation.dart`).
- `PlatformSidebar` widget (235 LOC) — renders nav items grouped by `section` field, with icon resolution from a baked-in `_resolveIcon(iconName)` map. Composes `eden-ui-flutter` (imports `package:eden_ui_flutter/eden_ui.dart`).
- Auto-reload triggers: company switch (`currentCompanyProvider` listener) + login/logout (`authProvider` listener).

**Q3 locked decision was: eden-platform-flutter grows a `VerticalNavSkin` interface; trades = first implementation.** The current platform-flutter nav layer is server-driven from the registry — there's no client-side "skin" notion today. The Q3 lock means adding a layer that takes the server `PlatformNavItem[]` and lets verticals decorate it with per-vertical icons, section names, or sub-items (e.g., trades' 8-group sidebar with sub-items per `lib/config/navigation.dart` 592 LOC).

**Comparison with trades-flutter nav:**

| Dimension | trades-flutter | eden-platform-flutter |
|---|---|---|
| Source | Client-side hardcoded list (`navigation.dart` 592 LOC, 8 groups, ~50 items with sub-items) | Server-driven via `RegistryService.getNavItems` |
| Filtering | Client-side RBAC filtering by permission strings | Server pre-filters by company + entitlements |
| Sub-items | Yes (groups with children: `EdenNavItem.children`) | No (flat list grouped by `section` field) |
| Mobile reorder | Built-in (per deep audit / mobile-forefront.png "Reorder") | Not surfaced |
| Tour-key support | `widgetKey: tourKeyDailyGroup` for showcase | None |
| Path resolution | `navRoutes` Map<navId, path> | Each item has `path` field directly |

The trades-flutter nav is **richer** than platform-flutter's today. Q3's `VerticalNavSkin` interface should let the rich layer be a vertical skin while preserving platform-flutter's server-driven base.

### 2.5 Auth UI — what platform-flutter ships

**Files:** `lib/src/auth/{login_screen.dart, signup_screen.dart, sso_auth_service.dart}` (read login_screen.dart head — 60 lines verified).

- `PlatformLoginScreen` — full screen with email + password fields, SSO buttons (Microsoft + Google via `_loginWithSSO`), error state, `onSignUpTap` + `onLoginSuccess` callbacks.
- `PlatformSignupScreen` — same pattern for signup.
- `SSOAuthService` — desktop (opens browser, captures callback) + web (window redirect) flow.
- MFA: not surfaced in current login screen — `auth_provider.dart` has no MFA paths. Per `aosentry` issue #20 [Objective 2] MFA + Session + Auth Boundary Hardening, MFA enrollment + backup-code consumption are tracked at the AOSentry/auth-server level (success criteria MFA-01/02). UI not yet in platform-flutter.

**Per Q4 lock — trades discards its auth UI in favour of platform-flutter's.** The 99-perm devLogin shortcut becomes `seedDevUser('owner', verticalScope)` in platform dev tooling.

### 2.6 Per-file disposition table for trades-flutter Connect/RBAC/nav/auth absorption

| trades-flutter file | LOC | Disposition | Target | Rationale |
|---|---|---|---|---|
| **lib/shared/api/connect_client.dart** | 195 | **delete** | — | platform-flutter ships real Connect-RPC via `eden_platform_api_dart` codegen; trades' Dio shim was a stand-in. Q1 absorb-pragmatically. |
| **lib/shared/api/api_client.dart** | 346 | **delete** (mostly) — retain Dio instance + interceptors only if eden-biz repos still need a Dio for non-Connect endpoints | eden-biz-flutter shared infra | Most calls migrate to ConnectPlatformRepository; AODex calls go through eden-ai-flutter (Section 1). |
| **lib/shared/api/api_exception.dart** | 84 | **rewrite as adapter** | eden-biz-flutter | Replace with `PlatformError` taxonomy from `eden-platform-flutter/errors/platform_errors.dart` (`AuthError`, `NetworkError`, `ServerError`). Add `ValidationException` / `ForbiddenException` shapes if platform-errors doesn't cover them. |
| **lib/shared/api/api_response.dart** | 72 | **delete** | — | Generic wrapper replaced by Connect-RPC typed responses. |
| **lib/shared/api/paginated_response.dart** | 63 | **donate** | eden-platform-flutter `lib/src/api/` or eden-biz-flutter shared | Pagination shape is generic — useful upstream. |
| **lib/shared/api/aodex_client.dart** | 390 | **donate to `eden-ai-dart/lib/src/aodex/client.dart`** (per Section 1) | eden-ai-dart | Largest existing Flutter AODex client; gets sibling status to `aosentry/`. |
| **lib/shared/api/aodex_models.dart** | 302 | **donate to `eden-ai-dart/lib/src/aodex/types.dart`** | eden-ai-dart | Companion to client. |
| **lib/shared/rbac/permissions.dart** | 122 | **donate as `lib/features/admin/rbac/permissions.dart`** in eden-biz-flutter | eden-biz-flutter | Q2 lock: RBAC lives in biz. The 99 permissions are the trades-vertical permission set; biz registers them per vertical. |
| **lib/shared/rbac/route_permissions.dart** | 538 | **rewrite + relocate** | eden-biz-flutter `lib/features/admin/rbac/` | The route-to-permission map needs reconciliation with biz's go_router config — straight donation will collide with eden-biz route names. |
| **lib/shared/rbac/rbac_provider.dart** | 57 | **donate as adapter** | eden-biz-flutter | The `permissionsProvider` / `hasPermissionProvider` pattern is generic — needs to consume `authProvider.user` from platform-flutter. |
| **lib/shared/rbac/permission_gate.dart** | 100 | **donate to `eden-ui-flutter` as `EdenPermissionGate`** (parallel widget to `EdenFeatureGate` already in platform-flutter) | eden-ui-flutter or eden-biz-flutter | Generic widget; either fits in eden-ui-flutter as a token-driven gate or in eden-biz-flutter alongside the perm registry. Recommend eden-ui-flutter — gate widget is transport-agnostic. |
| **lib/features/auth/data/auth_repository.dart** | 79 | **delete** | — | Trades calls `Env.authLoginUrl` (POST raw email/password) — platform-flutter's `AuthServiceClient.login` does the same plus token refresh + secure storage + SSO. Q4 lock. |
| **lib/features/auth/providers/auth_provider.dart** | 167 | **delete** | — | Replaced by `eden-platform-flutter/auth/auth_provider.dart` `AuthNotifier`. Q4 lock. |
| **lib/features/auth/domain/user_model.dart** | 97 | **partial — extract `permissions` field handling** | eden-biz-flutter | The `User.permissions: List<String>` field is what `rbac_provider.dart` consumes. Platform-flutter's `PlatformUser` has no permissions field. Either (a) extend `PlatformUser` with optional `permissions` (per Q2 biz-owns-RBAC, this is a biz concern, so probably no), or (b) biz fetches user permissions from a separate biz RPC. Recommend (b). |
| **lib/features/auth/domain/auth_state.dart** | 60 | **delete** | — | Replaced by `eden-platform-flutter` `AuthState`. |
| **lib/features/auth/presentation/login_page.dart** | 218 | **delete** | — | Replaced by `PlatformLoginScreen`. |
| **lib/features/auth/presentation/splash_page.dart** | 49 | **delete or rewrite** | — | Replaced by platform-flutter's auth-state-driven shell (`PlatformShell` renders `CircularProgressIndicator` while `AuthStatus.unknown / refreshing`). Trades splash may have branding — donate any branding bits to eden-ui-flutter `EdenSplashScreen` if not already present. |
| **lib/config/router.dart** | 752 | **rewrite onto biz_shell + eden-platform-flutter PlatformShell** | eden-biz-flutter | Q3 lock: nav grows VerticalNavSkin interface; trades' router is the donor for trades skin. |
| **lib/config/navigation.dart** | 592 | **donate as trades VerticalNavSkin** | eden-platform-flutter (`lib/src/navigation/skins/trades.dart`) | Q3 lock makes trades the first VerticalNavSkin. The 8-group structure + sub-items + tour-keys are the skin's contribution. |
| **lib/config/env.dart** | 29 | **adapt to platform-flutter `platform_config.dart`** | eden-biz-flutter | Env URLs become `API_BASE_URL` per platform-flutter's resolver. |
| **lib/config/theme.dart** | 10 | **delete or merge into eden-ui-flutter theme** | eden-ui-flutter | 10 LOC — likely just a `MaterialApp.theme` pointer; eden-ui-flutter owns tokens. |

**Aggregate counts:**
- 13 files deletable (trades' auth + Connect-shim layers fully replaced by platform-flutter)
- 5 files donated upward (`aodex_client.dart`, `aodex_models.dart`, `permissions.dart`, `permission_gate.dart`, `navigation.dart` skin, `paginated_response.dart`)
- 3 files rewritten in biz (`route_permissions.dart`, `rbac_provider.dart`, `router.dart`)
- ~1 file partially salvaged (`user_model.dart`'s permissions field handling)

**Effort estimate (Phase 2 reconciliation, per locked plan):**
- Connect adapter (W15 UUID + ConnectClient → platform-flutter Connect transport rewrite): ~3-4 days. Mostly rewriting repository call sites in eden-biz-flutter — all repos use `ConnectClient.call/callList/callVoid` today, all become `XServiceClient(_transport).method()`.
- Auth full discard + platform-flutter wiring in eden-biz-flutter ProviderScope: ~1 day.
- RBAC re-implementation in eden-biz-flutter admin layer + AO Identity migration-path doc: ~2-3 days.
- Nav VerticalNavSkin interface in platform-flutter + trades skin donation: ~2 days.

Phase 2 totals roughly 8-10 dev-days vs the plan's 2-wk estimate — fits comfortably.

---

## Section 3 — AO Identity Service status (Q2 future-migration)

### 3.1 Status: **IN FLIGHT and PARTIALLY SHIPPED to origin/main**

AO Identity is **not** an idea — it has a working OIDC issuer with PKCE, token issuance, refresh rotation, /userinfo, and ML-DSA-65 JWT signing. AODex is the pilot client.

**Code locations (eden-platform-go origin/main):**

| Artifact | Path |
|---|---|
| Service binary | `cmd/aoid/{main.go, boot.go, Dockerfile}` |
| Internal packages | `internal/aoid/{clients,composition,discovery,federation,config,...}` — 20+ files |
| Reusable auth lib (consumed by AOID, AOSentry, eden-biz, AODex, AOFamily) | `platform/auth/` |

**Merged objectives:**

| PR / commit | Objective | Description |
|---|---|---|
| `4a408a3` (PR #13) | Obj 29 | AO ID service scaffolding (cmd/aoid + OIDC discovery + JWKS + composition) |
| `1662939` (PR #14) | Obj 30 Phase A | Activate AO ID OIDC issuer + register AODex client |
| `f99a779` (PR #17) | Obj 31-01..04 (M8) | AO ID federation surface + decommission plan |
| `73cb129` (PR #19, 2026-05-15) | feat(auth) | Add `Scopes` claim + Navigators issuance (politihub ADR-0003) |

**Active worksession branches:**

- `ws-ao-id-pilot-aodex` — AOID pilot integration with AODex. Tip: `614741b` docs(30) update aoid README for active OIDC issuer.

**Pending / planned (per aosentry issue #25 success criteria):**

- `internal/auth/` AOID-carve-out-readiness check on every PR (AOCORE-06)
- Identity context header shape `X-AOEdge-Identity-Context` accepted by handlers; verifier is swappable so AOEdge-issued sigs replace it without handler changes (AOCORE-02)

**Estimated horizon for "fully consumed by biz-flutter":** weeks-to-months, not days. The OIDC issuer + AODex pilot work landed in the last 7-14 days (May 2026). The full federation surface and decommission plan (Obj 31) is in tree but presumably AODex is the first real client; eden-biz / Eden Biz Flutter will be a later integration. **Months horizon**, not years; not idea-only.

### 3.2 GitHub issue surface

- `https://github.com/AO-Cyber-Systems/aosentry/issues/25` — `[Objective 7] AOCore-Aware Design Hooks` (open). Covers AOCore-aware patterns including AOID carve-out readiness checks. Created 2026-05-14.
- `https://github.com/AO-Cyber-Systems/aosentry/issues/20` — `[Objective 2] MFA + Session + Auth Boundary Hardening` (open). Includes SESS-03 success criterion: `internal/auth/` exports a stable public interface; no business handler imports an `auth` internal package directly; AOID-carve-out-readiness checklist passes for every file.
- No issues found in the `eden-platform-go` repo specifically tracking AOID — but the work is landing via PRs #13/#14/#17/#19 with the AOID Obj 29-31 labels.

### 3.3 Planning docs

- `/Users/markemerson/Source/aocyber-compliance/.planning/AOCORE_VS_FEDRAMP_REVIEW.md` — exists; deep review.
- `/Users/markemerson/Source/aosentry-fedramp-prep/.planning/AOCORE_VISION.md` — Justin's vision doc (per memory).
- Memory file `project_aocore_aware_fedramp_2026-05-14.md` — has the authoritative mapping of Vision name → eden-platform-go location, including AOID = `cmd/aoid/` + `internal/aoid/`.

### 3.4 Implication for Q2 RBAC migration path doc

The Q2 locked decision says: "RBAC lives in biz admin function for now; future migration to AO Identity Service when that lands. Document the migration path in the RBAC absorption PR."

**Concrete migration path the RBAC absorption PR should document:**

**Today (biz-owned RBAC):**

```
Login flow:
  eden-biz-flutter → eden-platform-flutter PlatformLoginScreen
  → AuthServiceClient.login (eden-platform-go AuthService)
  → returns JWT with claims {sub, cid, role}
  → eden-biz-flutter calls biz RPC for user permissions list:
       BizAdminService.getUserPermissions(userId)
       → returns ['customers:create', 'projects:view', ...]
  → biz-side rbac_provider.dart caches permissions
  → PermissionGate(permission: 'X') checks the cached set
```

**Future (AOID-owned scopes):**

```
Login flow:
  eden-biz-flutter → eden-platform-flutter PlatformLoginScreen
  → AOID OIDC authorize → token exchange
  → JWT contains `Scopes` claim per platform/auth PR #19 (politihub ADR-0003)
       Scopes = scoped capability set — e.g.
       ['trades.customers.create', 'trades.projects.view', ...]
  → biz-side rbac_provider.dart consumes the Scopes claim directly (no biz RPC)
  → PermissionGate(permission: 'X') reads from Scopes
```

**The migration step is mechanical** once AOID issues `Scopes` claims that biz recognizes:

1. Biz publishes its permission registry (the trades 99-perm set + future verticals' sets) to AOID's scope catalog.
2. AOID's user-role mapping → scope-set definition lands.
3. Biz `rbac_provider.dart` swaps source from `BizAdminService.getUserPermissions(userId)` to `authProvider.session.scopes` claim parse.
4. `BizAdminService.getUserPermissions` deprecates / retires.

**Estimated work for the RBAC absorption PR (today, in eden-biz-flutter):**

- Donate trades' 99 permission constants to `eden-biz-flutter/lib/features/admin/rbac/permissions.dart`.
- Rewrite `route_permissions.dart` against biz route names.
- Donate `rbac_provider.dart` as `permissionsProvider` consuming `BizAdminService.getUserPermissions` (new biz RPC — depends on whether biz already exposes this; if not, ~1 day of trades-go-equivalent biz RPC work).
- Donate `permission_gate.dart` to eden-ui-flutter as `EdenPermissionGate`.
- Document the AOID-migration path above as an inline comment on `rbac_provider.dart` + a section in the PR description, referencing `eden-platform-go` PR #19 (Scopes claim) and AODex pilot work.

The PR should **NOT** wait for AOID to be ready for biz consumption — that's months out and blocking absorption Phase 2 on it would block 18 other absorption PRs.

---

## Cross-cutting recommendations — impact on absorption plan §7 / §8

The three findings collectively simplify the absorption plan rather than complicate it. Specific amendments to the plan's §7 (locked decisions) and §8 (next actions):

### Phase 0 (decisions, 1 wk) — what to lock and what's already locked

| Item | Status after this research |
|---|---|
| **Q5 AODex/AOSentry client placement** | Resolvable now. Recommend: donate trades' `aodex_client.dart` + `aodex_models.dart` to `eden-libs/eden-ai-dart/lib/src/aodex/`; eden-ai-flutter exports `aodexClientProvider` mirroring the existing `aosentryClientProvider` pattern. eden-biz-flutter consumes both via Riverpod overrides. **No new `eden-aocore-flutter` package needed.** |
| **Q1 follow-up Connect shape** | Resolved. Connect channel is real (codegen + `connectrpc/connect.dart`); auth is fully serviced by `eden-platform-flutter/auth/`; entitlements layer covers subscription-level gating but does NOT cover user-action RBAC (that's biz per Q2). Per-file disposition table in §2.6. |
| **Q2 AO Identity migration path** | AOID is real and in flight. RBAC absorption PR includes a migration-path doc referencing eden-platform-go PRs #13/#14/#17/#19. Don't block Phase 2 on AOID adoption — months out. |

### Phase 1 (eden-ui-flutter library donations, 2-3 wk) — unchanged

Phase 1's 16 widgets are not affected by these findings. Net new addition: `EdenPermissionGate` (donated from trades, sibling to `EdenFeatureGate` already in platform-flutter's entitlements layer).

### Phase 2 (infra reconciliation, 2 wk) — meaningfully smaller

The four originally-planned infra PRs collapse to **three**:

1. **eden-biz-flutter Connect wiring** — replace `ConnectClient`+`ConnectRepository` with `eden-platform-flutter`'s `ConnectPlatformRepository` + generated `eden_platform_api_dart` clients. Repository call sites migrate. ~3-4 days.
2. **eden-biz-flutter auth wiring** — discard trades auth; add `PlatformLoginScreen` + `PlatformShell` to biz; override `tokenStorageProvider` / `platformRepositoryProvider` for biz env. ~1 day.
3. **eden-biz-flutter RBAC + permission registry** — donate trades' permission constants + gate widget + provider; biz RPC for user permissions (or extend existing); add inline AOID-migration-path doc. ~2-3 days.
4. **eden-platform-flutter VerticalNavSkin interface + trades skin** — new file `lib/src/navigation/vertical_nav_skin.dart` (interface) + `lib/src/navigation/skins/trades_skin.dart` (donated from trades' 592-LOC navigation.dart, restructured to use server-provided `PlatformNavItem[]` as base + decoration via skin). ~2 days.

Combined: 8-10 dev-days. **No AOCore-lib placement decision needed in this phase** (Q5 resolved in Phase 0 already).

### Phase 3 (per-folder absorption) — small change

- W17/W18/W20 AI-streaming feature folders import `package:eden_ai_flutter/eden_ai_flutter.dart` instead of `package:trades/shared/api/aodex_client.dart`. Methods map 1:1 (createPersona → createPersona, streamChat → streamChat, etc.) since the donor is trades' own client.
- AI feature folders no longer require trades-flutter's `connect_client.dart` shim — Connect calls go through generated `eden_platform_api_dart` clients.

### Phase 4 (companion build) — unchanged.

### Phase 5 — retired (per Q12 lock).

### Updated "Next concrete actions" table (replaces plan §8)

| # | Action | Owner | Status |
|---|---|---|---|
| 1 | `/df:plan-objective` Phase 1 — 5-PR widget-donation batch to eden-ui-flutter (16 widgets) | df-planner | unchanged; can start now |
| 2 | `/df:plan-objective` Phase 2 — 4-PR infra-reconciliation in eden-biz-flutter (Connect + auth + RBAC + VerticalNavSkin) | df-planner | this research unblocks |
| 3 | **New:** small PR to `eden-libs/eden-ai-dart` — add `lib/src/aodex/{client.dart, types.dart}` + export from `eden_ai_dart.dart` + Riverpod provider in `eden-ai-flutter/lib/src/providers/aodex_provider.dart`. Donor source: `trades-flutter/lib/shared/api/aodex_client.dart` + `aodex_models.dart`. | eden-ai-dart maintainer | Phase 0 — ~1-2 days; can start immediately |
| 4 | **New:** `eden-libs` workspace pubspec wiring confirmation — verify `eden-biz-flutter/pubspec.yaml` has path-deps on `eden-platform-flutter` + `eden-ai-flutter` + `eden-ui-flutter`. (Per `eden-libs/CLAUDE.md` package responsibilities, this is the expected topology.) | eden-biz-flutter planner | spot-check pre-Phase-2 |
| 5 | Trades-go: process-builder entity-type unlock + workflow `entity_created` trigger (per deep-audit §7 decisions 2 + 3) | trades-go planner | unchanged; parallel to absorption |
| 6 | Companion-app build target B2 spec (Path α mode flag) | eden-biz-flutter planner | unchanged; parallel |

### One small open question for Mark

The deep audit's decision §7.7 left `agent_builder/` placement open. With Q6 already locked as cross-vertical at `eden-biz/flutter/lib/features/agent_builder/`, **and** the fact that `eden-ai-dart/lib/src/skills/` + `eden-ai-go/skills/` + `eden-ai-go/orchestration/` already ship a skill orchestration contract — does the trades-flutter `agent_builder/`'s 15 files / 3 621 LOC (rule_editor_canvas, mcp_tool_panel, persona_session_panel) get **donated upward** to eden-ai-flutter as the canonical agent-builder UI, with eden-biz-flutter consuming it via a feature folder that wires biz-specific entity types? Or does eden-biz-flutter own it outright (per Q6 lock literal)?

The Q6 lock said "cross-vertical at biz" without knowing that eden-ai-dart already ships the orchestration contracts. Worth a 30-second reconfirmation: **if** the agent-builder UI is genuinely vertical-agnostic (configures personas, MCP tools, rule editors that target eden-ai-dart skills), it belongs in eden-ai-flutter alongside `aosentryClientProvider`. **If** it has any biz-domain bindings (e.g., binds to biz `Customer` / `Project` entity types directly), Q6's "in biz" placement is correct.

---

*Generated 2026-05-15 by absorption-research agent. Read-only investigation across `eden-libs/` (eden-ai-dart, eden-ai-flutter, eden-ai-go, eden-platform-flutter, eden-platform-api-dart, eden-platform-go path-dep), `aocyber-compliance/`, `aosentry`/`aosentry-fedramp-prep`, `aodex`/`aodex-flutter`, `AOCyber-Trades/trades-flutter`. GitHub search across `AO-Cyber-Systems` org for AOCore / AOSentry / AOID / AO Identity. No source modified. Companion to `TRADES_FLUTTER_ABSORPTION_PLAN_2026-05-15.md` §7 open research actions 1–3.*
