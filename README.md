# eden_ui_flutter

Shared UI/design-system package for Eden Flutter apps.

It contains:

- theme and token definitions
- reusable widgets
- layout primitives
- a visual dev catalog under `lib/dev_app`

## Run The Catalog

```bash
flutter run -t lib/main.dart
```

## Autofill And Selection

Every text input resolves its autofill hints, keyboard type and obscure flag from a single
`EdenFieldPurpose`. Rendered text is selectable and copyable by default in the Eden layouts.

iOS needs an Associated Domains entitlement and a published AASA file before any of it works in a
real app — see [docs/autofill-and-selection.md](docs/autofill-and-selection.md).

## Boundaries

- Keep this package transport-agnostic.
- Backend contracts and generated API clients belong in `eden-platform-api-dart`.
- App/session orchestration belongs in `eden-platform-flutter`.
