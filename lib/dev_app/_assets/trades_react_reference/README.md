# trades-react reference screenshots

Primary-source visual references for the EdenScheduler parity demo
(`lib/dev_app/screens/scheduler_screen.dart`).

Captured from `AOCyber-Trades/trades` (trades-react Schedule.tsx +
EnhancedCalendar.tsx + MobileScheduleView + TruckAvailabilityView) on
2026-05-16. Reproduced here under internal-engineering reference use; not
redistributed beyond the eden-libs monorepo.

## Files

| Asset                                | Captured from                                                  |
| ------------------------------------ | -------------------------------------------------------------- |
| `qa-admin-scheduler.png`             | `qa-admin-forefront.png` (closest admin scheduler view)        |
| `qa-admin-forefront.png`             | Eden Trades admin forefront layout                             |
| `mobile-projects.png`                | trades-react mobile projects list (mobile pattern reference)   |
| `mobile-forefront.png`               | trades-react mobile forefront (companion-mode shell reference) |
| `mobile-forefront-team-expanded.png` | mobile forefront with team picker expanded                     |
| `desktop-customer-detail.png`        | customer detail page (cross-pattern reference for swimlane)    |

## Do NOT regenerate these via automation

These are primary-source screenshots from the canonical trades-react
Schedule implementation. They are the parity reference; the EdenScheduler
implementation must match them visually per objective 004 OBJECTIVE.md
acceptance criteria.

Replace ONLY when the trades-react Schedule itself ships visual updates
AND the eden-ui-flutter EdenScheduler has caught up.
