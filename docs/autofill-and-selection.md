# Autofill And Selection

How password-manager autofill and universal copy/paste work in `eden_ui_flutter`, what you
must configure in **your** app before either works, and which parts are broken upstream today.

Read section 8 before filing a bug against this package.

Every framework claim below cites the Flutter source file and line it was read from. Paths are
relative to the Flutter SDK checkout (`/opt/homebrew/share/flutter` on a Homebrew install);
`web_ui/...` is `engine/src/flutter/lib/web_ui/lib/src/engine/text_editing/text_editing.dart`.
The behaviour was read against Flutter 3.41.4 and holds from the declared floor 3.27.0 upward.

---

## 1. What this package gives you

### `EdenFieldPurpose` — one value, the whole input contract

`EdenFieldPurpose` is a 26-member enum. Choosing one resolves `autofillHints` (in
platform-correct order), `keyboardType`, `obscureText`, `textInputAction`,
`textCapitalization`, `autocorrect` and `enableSuggestions` as one consistent set.

```dart
EdenInput(
  label: 'Email',
  hint: 'you@example.com',
  controller: _emailController,
  purpose: EdenFieldPurpose.email,
)
```

**Why a purpose and not raw hints — this is the part people get wrong.**

`TextField` resolves `keyboardType` in its own **constructor initializer list**
(`material/text_field.dart:355`):

```dart
keyboardType = keyboardType ?? (maxLines == 1 ? TextInputType.text : TextInputType.multiline),
```

That runs *before* `EditableText` is ever constructed, so `editable_text.dart:965`'s
`keyboardType ?? _inferKeyboardType(...)` **never** sees null. The inference path is dead for
`TextField`, `TextFormField`, and everything in this package built on them.

Consequence: **adding `autofillHints:` on its own fixes nothing.** The field still resolves to
`TextInputType.text`. And `editable_text.dart:1855-1858` states that some hints only work with a
matching keyboard — `AutofillHints.email` works only with `TextInputType.emailAddress`. So a
hint-only change leaves iOS autofill broken while looking correct in code review. `EdenFieldPurpose`
sets both halves together, which is the only combination that actually works.

Hint **order** is also load-bearing (`services/autofill.dart:688-694`): iOS uses only the FIRST
hint, web uses only the FIRST hint, Android uses ALL of them. Every hint list in
`eden_field_purpose.dart` is ordered iOS/web-first with Android-only extras after index 0. You
cannot get that wrong by naming a purpose; you can very easily get it wrong by hand.

Always set `hint:` as well on a purposed field. `hintText` becomes the DOM `placeholder`
(`web_ui/.../text_editing.dart:471`), and password-manager heuristics read placeholders. It is free
signal.

`EdenFieldPurpose.none` is a real, greppable member meaning "deliberately no autofill purpose".
It emits `autofillHints == null` — never an empty list.

### `EdenAutofillScope` — the SAVE half

An `AutofillGroup` plus the one call that makes a platform offer to save what was typed. See
section 2; this is the part nothing works without.

```dart
EdenAutofillScope(
  child: Column(children: <Widget>[ /* credential fields */ ]),
)
```

`EdenForm` and `EdenAsyncFormScaffold` already provide one ambiently (`autofillScope`, default
`true`), so most callers never construct it directly — they just call
`EdenAutofillScope.of(context).commit()`.

### `EdenSelectableRegion` — selection and a working web context menu

Makes every piece of text in a subtree drag-selectable, with no per-widget change. On web it also
calls `BrowserContextMenu.disableContextMenu()` once per process, so Flutter's own "Copy" menu
appears on right-click instead of the browser's native menu.

```dart
EdenSelectableRegion(
  child: MyContent(),
)
```

It is **already on by default** in `EdenDesktopLayout` and `EdenMobileLayout` and in the 10 library
pages. See section 6.

### TSV table copy

`edenCopyTsv`, `edenRowsToTsv`, `edenTsvRow` and `edenTsvCell` in `lib/src/utils/eden_tsv.dart`,
plus a `copyable` flag on the five table widgets. Selection alone cannot copy a table usefully —
see section 6.

```dart
EdenDataTable(
  columns: columns,
  rows: rows,
  copyable: true,
)
```

---

## 2. The two halves: FILLABLE is not SAVABLE

These are two independent directions, and this package used to have only one of them.

| Direction | What makes it work |
|---|---|
| **Fillable** — the OS, browser or password manager pushes a stored credential in | Correct hints + matching keyboard, i.e. `purpose:` |
| **Savable** — the platform offers to store what the user just typed | Exactly one call: `TextInput.finishAutofillContext(shouldSave: true)` |

**Nothing is ever saved on any platform without that call.** On web the engine builds a real
hidden `<form>` carrying a hidden submit button (`web_ui/.../text_editing.dart:243-346`), and
`saveForms()` literally **clicks it** (`web_ui/.../text_editing.dart:2245`). That synthetic click is
what raises the browser's "Save password?" prompt. No call, no prompt — on web, iOS or Android.

### How to commit

```dart
Future<void> _signIn() async {
  final result = await api.login(
    email: _emailController.text,
    password: _passwordController.text,
  );
  if (!mounted) return;
  if (result.isSuccess) {
    // ONLY here. The credential has actually been accepted.
    EdenAutofillScope.of(context).commit();
    _goToHome();
  } else {
    _showError(result.message);   // no commit — the password was wrong
  }
}
```

### Two deliberate defaults that look wrong until you know why

**`EdenForm.commitAutofillOnSubmit` defaults to `false`** (`lib/src/widgets/eden_form.dart:90`).

`EdenForm.onSubmit` is a bare `VoidCallback`. It returns the instant the async login is *dispatched*,
long before the server answers, so "returned without throwing" is not a success signal. Auto-committing
there would make the OS and 1Password offer to save credentials that were subsequently **rejected**.
Set it to `true` only for a form whose `onSubmit` is genuinely synchronous and cannot fail.

**`EdenAutofillScope.onDisposeAction` defaults to `AutofillContextAction.cancel`** — which is NOT
Flutter's default.

`AutofillGroup` defaults it to `commit` (`widgets/autofill.dart:75`), and its `dispose` then calls
`TextInput.finishAutofillContext()` with `shouldSave` defaulting to true
(`widgets/autofill.dart:232-243`). Under that default, simply **navigating away** from a form offers
to save whatever was typed — including after a failed sign-in. That is how a password manager ends up
storing a wrong password, and it would also bypass `commit()` and `commitAutofillOnSubmit` entirely,
making both controls decorative.

So here dispose **cancels**, and saving happens only through an explicit `commit()`. Pass
`AutofillContextAction.commit` if a surface genuinely wants Flutter's implicit behaviour, and say why
at the call site.

There is also `EdenAutofillScopeState.cancel()`, which ends the context without saving. Do not reach
for it as a "safe default" in place of `commit()` — tearing the context down without saving guarantees
the credential is never stored. If you are not saving, call nothing.

---

## 3. iOS setup — required, and NOT something this package can do for you

iOS Password AutoFill will not associate a stored credential with your app until **you** publish a
domain association. `eden_ui_flutter` cannot do any of this; it lives in your app and on your web
server.

### 3.1 Add the Associated Domains capability

In Xcode: select the Runner target -> **Signing & Capabilities** -> **+ Capability** ->
**Associated Domains**. Add one entry per domain:

```
webcredentials:example.com
```

That writes into `ios/Runner/Runner.entitlements`:

```xml
<key>com.apple.developer.associated-domains</key>
<array>
  <string>webcredentials:example.com</string>
</array>
```

The capability must also be enabled for the App ID in the Apple Developer portal, or the build
will fail to sign.

### 3.2 Publish the `apple-app-site-association` file

Serve it at:

```
https://example.com/.well-known/apple-app-site-association
```

Minimal content for Password AutoFill:

```json
{
  "webcredentials": {
    "apps": ["ABCDE12345.com.example.myapp"]
  }
}
```

`ABCDE12345` is your **Team ID**; `com.example.myapp` is the **bundle identifier**. The entry is
`<TeamID>.<BundleID>`, joined by a dot.

Requirements that silently break this if you miss them:

- **HTTPS, with a valid certificate.** Plain HTTP is not fetched.
- **No redirects.** Apple does not follow them for this file. A host that 301s `example.com` to
  `www.example.com` will fail unless the file is served directly at the domain you named in the
  entitlement.
- **No `.json` extension.** The path is exactly `/.well-known/apple-app-site-association`.
- Serve it as `application/json`.
- **No authentication.** It must be publicly fetchable.

### 3.3 Expect propagation delay

Since iOS 14 the AASA file is fetched through an **Apple-managed CDN**, not directly from your
server. Publishing a change does not take effect immediately, and a device that already cached a
failed lookup will keep failing for a while. Plan for hours, not seconds, and do not conclude the
entitlement is wrong after one test.

To verify what Apple's CDN currently serves for your domain, fetch it from Apple's own endpoint
rather than from your server — your server can be correct while the CDN is still stale.

---

## 4. Android setup

- **Autofill requires API 26+ (Android 8.0).** Below API 26 the platform autofill framework
  does not exist and hints are inert. Set `minSdkVersion` accordingly in
  `android/app/build.gradle` if autofill is a requirement for your app.
- No entitlement or domain-association file is needed for basic field autofill.
- **Behaviour varies by the active autofill service.** Google's autofill service and third-party
  managers (1Password, Bitwarden) differ in what they will save and when they offer to. Android
  reads ALL hints in the list, not just the first, which is why the Android-only extras in
  `EdenFieldPurpose`'s lists sit after index 0.

---

## 5. Web — the DOM mechanism

Flutter web writes your autofill hint straight into the DOM. From
`web_ui/.../text_editing.dart:514-531` (`AutofillInfo.applyToDomElement`):

```dart
if (autofillHint != null) {
  element.name = autofillHint;
  element.id   = autofillHint;
  element.type = autofillHint.contains('password') ? 'password' : 'text';
}
element.autocomplete = autofillHint ?? 'on';
```

Three consequences:

1. **No hints means no identity.** With no `autofillHints`, the element gets
   `autocomplete="on"`, **no `name` and no `id`**. A password manager has nothing to classify the
   field by. This — not a Flutter bug — is the usual root cause of "autofill doesn't work".

2. **`obscureText` does NOT produce a web password field.** DOM `type="password"` is derived from
   the **hint string** containing `"password"`, never from `obscureText`. An obscured field with no
   password-family hint renders as `type="text"`: the secret sits in plaintext in the DOM, and
   1Password will neither fill it nor offer to save it. **This is why an obscured field MUST carry
   a password-family purpose** — `currentPassword`, `newPassword` or `newPasswordConfirm`. Every
   obscured member of `EdenFieldPurpose` emits a password-family hint at index 0, and the test suite
   enforces it.

   (The check is against the *browser token*, not the raw Flutter constant. The engine maps
   `hints.first` through `BrowserAutofillHints.flutterToEngine` first
   (`web_ui/.../text_editing.dart:466-468`), turning `password` into `current-password` and
   `newPassword` into `new-password`, and only then runs the case-sensitive
   `.contains('password')`. The raw camelCase constant `'newPassword'` would fail a naive
   case-sensitive match — any guard you write must map through the browser token or lowercase first.)

3. **`hintText` becomes the DOM `placeholder`** (`web_ui/.../text_editing.dart:471`). Set `hint:`
   on every purposed field.

### The duplicate-id constraint

Because `element.name` **and** `element.id` both come from the hint string, two fields sharing a
hint inside one autofill scope emit **duplicate DOM ids**.

This is accepted deliberately for the new-password pair: `newPassword` and `newPasswordConfirm` are
separate enum members that resolve the same hint, because two `autocomplete="new-password"` inputs
is the standard HTML signup shape and the alternatives are worse (dropping the hint on confirm makes
it `type="text"`; inventing a custom token emits an invalid `autocomplete` value).

It is **not** accepted for repeated fields. Before assigning a hint-bearing purpose, ask whether the
widget can render that field more than once inside a single scope:

- Repeater rows (`eden_schema_form.dart`) deliberately do not inherit the spec's purpose — N rows
  sharing one hint would emit N duplicate ids.
- Split components of one logical value (`eden_memorable_date.dart`'s Month/Day/Year boxes) each use
  `none`: `AutofillHints.birthday` denotes the whole date, so claiming it per-box would be both
  semantically false and id-colliding.

Purposes that resolve `autofillHints == null` — `multilineText`, `searchQuery`, `decimalAmount`,
`quantity`, `none` — contribute no hint, so no id, so **no collision**. Repeated notes fields can
safely carry `multilineText`.

---

## 6. Selection and copy

### It is already on

`EdenSelectableRegion` is installed by default in:

- `EdenDesktopLayout` and `EdenMobileLayout`, via `selectableBody` (default `true`), which wraps
  `body`.
- All **10** library pages (`eden_login_page`, `eden_signup_page`, `eden_forgot_password_page`,
  `eden_reset_password_page`, `eden_profile_page`, `eden_settings_page`, `eden_onboarding_page`,
  `eden_splash_page`, `eden_maintenance_page`, `eden_support_panel_demo_page`).

Plain `Text` under a region becomes selectable as-is. No per-widget change is needed, and there are
**zero** `SelectableText` widgets left under `lib/` — a `SelectableText` nested inside a
`SelectionArea` is an un-draggable selection *island* that stops a drag dead at its boundary, so all
13 former sites are plain `Text` now. Do not reintroduce one inside a region.

### Opting out

Two levels, and they are not interchangeable:

```dart
// Whole surface: turn the layout's region off.
EdenDesktopLayout(
  selectableBody: false,
  body: MyContent(),
)

// One subtree: exclude interactive chrome so a drag does not swallow button labels.
EdenSelectableRegion(
  child: Column(
    children: <Widget>[
      const Text('this text is selectable'),
      SelectionContainer.disabled(
        child: TextButton(onPressed: doThing, child: const Text('Action')),
      ),
    ],
  ),
)
```

`SelectionContainer.disabled` (`widgets/selection_container.dart:65`) is the documented per-subtree
opt-out. Use it for buttons, menus and inline row actions.

**Do not disable selection on read-only fields.** A `readOnly: true` field that is not obscured stays
selectable and copyable — `editable_text.dart:935` defaults `enableInteractiveSelection` to
`(!readOnly || !obscureText)`. Only `readOnly && obscureText` together kill selection. Adding
`enableInteractiveSelection: false` to a read-only field removes a working affordance for nothing.

### Apps that use neither Eden layout

Install one region for the whole app via `MaterialApp.builder`:

```dart
MaterialApp(
  builder: (context, child) =>
      EdenSelectableRegion(child: child ?? const SizedBox.shrink()),
  home: MyHomePage(),
)
```

### Nesting collapses; it does not fragment

Two raw `SelectionArea`s nested inside each other are two **separate** selection scopes: a drag begun
in the outer one stops dead at the inner one's boundary, so "select the whole page" silently breaks
exactly where more selection was added.

`EdenSelectableRegion` prevents that. A **plain** nested region — one with no `contextMenuBuilder`,
no `onSelectionChanged` and no `focusNode` — detects the ancestor region and becomes a no-op, leaving
a single scope spanning everything. Since this objective installs regions at layout level, page level
*and* (via the recipe above) app level, nesting is the default outcome, not an edge case.

A **configured** nested region is honoured and does open its own scope, because that is an explicit
request — silently discarding a caller's `contextMenuBuilder` would be worse than the extra scope.
If you pass a custom menu, expect a selection boundary there.

### Tables ALSO need explicit TSV copy

`SelectionArea` concatenates the selected fragments in **tree order with no tab and no newline
between cells**. Drag-copying a table therefore produces run-together text — `AliceAdminBobUser` —
from which no consumer can recover the grid.

Free-form selection and TSV copy are not alternatives. Selection serves "grab that one value"; TSV
copy serves "put this table in a spreadsheet". A tabular surface needs both. Set `copyable: true` on
`EdenDataTable`, `EdenDataGrid`, `EdenKeyValueTable`, `EdenProjectTable` or `EdenLabResultTable`, and
the widget routes through the shared helpers so the library emits exactly one TSV dialect.

```dart
await edenCopyTsv(
  <List<String>>[
    <String>['Alice', 'Admin'],
    <String>['Bob', 'User'],
  ],
  header: <String>['Name', 'Role'],
);
```

**The `eden_tsv` contract** (`lib/src/utils/eden_tsv.dart`), which every caller relies on:

- **Tab between cells, LF between rows.** TSV, not CSV — spreadsheets paste tab-delimited clipboard
  text natively as separate cells. LF never CRLF, because a stray carriage return lands in the last
  cell of every row in consumers that do not strip it.
- **A tab, CR or LF inside a cell collapses to ONE space**, and the cell is trimmed. TSV has **no
  escape mechanism** — the format is purely positional, so a raw tab silently shifts every later
  column of that row and a raw newline splits one record into two. Escaping and CSV-style quoting
  were both rejected: spreadsheets do not un-escape and do not apply CSV quoting rules to
  tab-delimited clipboard text, so the user would see literal junk in the cell. Collapsing is lossy
  in the rare multi-line cell but keeps the grid intact, which is the entire point. A user who needs
  the exact bytes of one cell selects and copies that cell directly.
- **No trailing line delimiter.** A trailing newline pastes as a phantom empty row that then shows up
  in row counts and in any downstream `SUM`/`COUNTA`.
- **Header is an explicit named argument**, not a flag on the data. "Copy table" wants column names;
  "copy row" must never smuggle them in. Making the choice visible at the call site keeps the two
  from being confused.
- **Null becomes an empty cell, never the string `"null"`.** An empty cell still occupies its column,
  so alignment survives a blank.
- **Ragged rows are preserved as-is, never padded.** Padding to the widest row would invent cells the
  caller never supplied and hide the modelling bug that produced the ragged grid.
- An empty grid with no header produces an empty string; an empty grid *with* a header produces just
  the header line.

For `EdenDataTable`, whose cells are opaque `Widget`s, `edenExtractWidgetText` recovers text as a
**fallback**. It reads what is on screen, which for a formatted amount or a relative timestamp is a
rendering rather than the datum. Supply `EdenTableRow.copyValues` whenever the copied value should be
the data.

---

## 7. Secrets

**`obscureText: true` hard-disables copy and cut in the framework.** Not configurable, not a flag
(`editable_text.dart:2641-2646`):

```dart
bool get copyEnabled => !widget.obscureText && !textEditingValue.selection.isCollapsed;
bool get cutEnabled  => !widget.readOnly && !widget.obscureText && !...isCollapsed;
```

Paste still works. So a field the user must be able to copy **cannot** be obscured, and an obscured
field that needs a copy affordance **must** provide an explicit button. There is no third option.

- `EdenSecretField` is the reference pattern: it carries a reveal toggle and an explicit copy button
  precisely because the framework's own copy is unavailable to it.
- `EdenSecretClipboardMode.classified` suppresses that copy button and announces the suppression. It
  is a **deliberate security posture** (a DoD CUI pattern), not a bug — do not "fix" it.
- `EdenFieldPurpose.creditCardSecurityCode` is **deliberately not obscured**. A CVV is conventionally
  visible, and obscuring it would hard-disable copy and cut for no security benefit.

If you write a test asserting clipboard gating, **set a non-collapsed selection first**. `copyEnabled`
is `!obscureText && !selection.isCollapsed`, so with an empty selection it is false for *every* field,
obscured or not — the assertion passes while proving nothing:

```dart
controller.selection = const TextSelection(baseOffset: 0, extentOffset: 13);
await tester.pump();
```

---

## 8. Known limitations — read this before filing a bug

### Upstream Flutter issues

These are framework/engine bugs. This package cannot fix them and deliberately does not invent
workarounds that fight the engine.

| Issue | Subject | State (as of 2026-09-16) |
|---|---|---|
| [flutter#174773](https://github.com/flutter/flutter/issues/174773) | Password-manager autofill does not work on web (Bitwarden, Proton Pass) | Open, P1, PR #190126 in flight |
| [flutter#61301](https://github.com/flutter/flutter/issues/61301) | Autofill doesn't work with password managers on web (open since 2020) | Open, P1, long-running |
| [flutter#116889](https://github.com/flutter/flutter/issues/116889) | `finishAutofillContext()` doesn't bring up the system prompt (iOS) | Open |
| [flutter#69111](https://github.com/flutter/flutter/issues/69111) | `finishAutofillContext()` doing nothing; cannot save user input (Android) | Open |
| [flutter#104547](https://github.com/flutter/flutter/issues/104547) | Reimplement `SelectableText` on `SelectionArea` | Open — confirms `SelectionArea` is the strategic API |

**What this means in practice:** correct hints + an autofill group + `finishAutofillContext` is the
**ceiling** of what the framework can deliver today. Browser-extension password managers on Flutter
web remain partly broken upstream regardless of what this package does. If autofill fails on web with
a browser extension, check flutter#174773 before opening an issue here.

### Autofill is best-effort, always

`services/autofill.dart:688-694` is explicit that providing a predefined hint does **not** guarantee
the field is eligible for autofill — the active autofill service decides. Treat autofill as
best-effort.

**Never gate functionality on it.** A flow that only works if the password manager fills a field is a
broken flow.

### Untested-by-automation: the web right-click menu

`BrowserContextMenu.disableContextMenu()` has **zero automated coverage** in this package, and cannot
have any: `kIsWeb` is a compile-time constant that is `false` under `flutter test`, so the web branch
is unreachable from the test suite. The claim "right-click shows Flutter's Copy menu on web" is
**reasoned from the engine source, not measured**. It wants a manual check in a real browser. If you
find it does not behave as described, that is a genuine gap in our verification, not a documented
guarantee being broken.

### Save-prompt behaviour differs by platform and by manager

Even with everything above correct, whether a save prompt appears is a platform decision. iOS may
suppress it (flutter#116889); Android behaviour differs between Google's autofill service and
third-party managers (flutter#69111). Build the correct contract, then let the platform do what it
does.

---

## 9. Migration for existing consumers

`EdenInput`'s raw `autofillHints`, `keyboardType` and `obscureText` parameters are **deprecated but
still functional**. Removal is targeted at **4.0**.

### Before / after

```dart
// BEFORE — three independent knobs that can silently disagree
EdenInput(
  label: 'Email',
  controller: _emailController,
  keyboardType: TextInputType.emailAddress,
  autofillHints: const <String>[AutofillHints.email],
)

EdenInput(
  label: 'Password',
  controller: _passwordController,
  obscureText: true,                      // renders DOM type="text" on web!
)
```

```dart
// AFTER — one value resolves the whole consistent set
EdenInput(
  label: 'Email',
  hint: 'you@example.com',
  controller: _emailController,
  purpose: EdenFieldPurpose.email,
)

EdenInput(
  label: 'Password',
  controller: _passwordController,
  purpose: EdenFieldPurpose.currentPassword,
)
```

### You cannot mix them

`EdenInput` asserts that a non-`none` `purpose` is not combined with a raw `autofillHints:`,
`keyboardType:` or `obscureText:`. Passing both reintroduces exactly the mismatch the enum exists to
delete, so it is a debug-mode assertion failure with a fix-it message, not a silent precedence rule.
Drop the raw argument.

### Every field needs a purpose — CI enforces it

`test/tool/eden_field_purpose_guard_test.dart` scans `lib/` and fails when a text-input site
carries neither a resolved purpose nor an explicit marker. It asserts two censuses separately:

- **136 sites across 69 files** counting raw `TextField` / `TextFormField` only.
- **202 sites across 87 files** counting `EdenInput(` call sites as well.

All covered, with **zero exemptions**. The scan is comment-aware — a `TextField(` token inside a
dartdoc is not a field, and demanding a purpose for one would force a meaningless marker into a
file with no input in it. It also reads and decodes bytes in Dart rather than shelling out to
`grep`, because `grep` treats a file containing a NUL as binary and reports no matches while
exiting 1 — indistinguishable from "no violations".

A field with no legitimate autofill purpose must say so:

```dart
// eden-field-purpose: EdenFieldPurpose.none — free-text filter box, no stored
// credential corresponds to it.
```

and, only where the rule genuinely does not apply, an exemption **with a written reason**:

```dart
// eden-field-purpose: exempt — layout probe widget with no real text input.
```

The guard rejects a reasonless exemption. If it trips, fix the file, not the guard.

Two notes if you write tests around this:

- **`TextField.autofillHints` defaults to `const <String>[]`, not `null`.** Assert on
  **emptiness**, never on nullness. `hints != null && hints.isNotEmpty` means "has an identity";
  `hints == null || hints.isEmpty` means "has none". Asserting `autofillHints != null` passes on
  fields that carry no hints at all — it certifies exactly the fields this work exists to fix.
- `EdenFieldSemantics` deliberately uses `null` (not an empty list) for "no hints", so the enum has
  two states rather than three. The two types differ; convert explicitly when crossing between them.

### Do not put a raw control byte in source

A literal NUL byte inside a Dart string compiles and runs fine, but `file(1)` then classifies the
source as `data` and **`grep` silently returns nothing for every pattern** — exit 1, no output,
indistinguishable from "the code isn't there". It produced a false review conclusion once in this
objective. Use the escape sequence, and if you are unsure, run `file` on the result and confirm it
reports text.

---

## 10. Note for `eden-platform-flutter`: adopting selection in `PlatformShell`

Out of scope for this package, recorded so it is not forgotten.

`PlatformShell` (`eden-platform-flutter/lib/src/platform_shell.dart`) is the shell many Eden apps
actually mount — such an app never reaches `EdenDesktopLayout` or `EdenMobileLayout`, so it does not
inherit the default selection region described in section 6. It can adopt `EdenSelectableRegion`
around its content slot exactly the way the Eden layouts do, ideally behind a `selectableBody`-style
flag for symmetry.

That change belongs in `eden-platform-flutter`, not here: the workspace `CLAUDE.md` requires platform
logic stay in `eden-platform-flutter` and UI logic stay in `eden-ui-flutter`. Until it lands, an app
on `PlatformShell` should use the `MaterialApp.builder` recipe in section 6.
