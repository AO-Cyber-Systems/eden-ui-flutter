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

## Boundaries

- Keep this package transport-agnostic.
- Backend contracts and generated API clients belong in `eden-platform-api-dart`.
- App/session orchestration belongs in `eden-platform-flutter`.
