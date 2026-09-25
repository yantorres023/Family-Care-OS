# Baton (codename: Family Care OS)

A private, shared to-do and handoff list for families caring for a parent. Every task has an owner or clearly "needs someone"; a note tells the next person what happened; one tap sends the plan to the family group chat. Not a medical app.

**Start here:** [RELEASE_REPORT.md](RELEASE_REPORT.md) · [docs/PROJECT_STATE.md](docs/PROJECT_STATE.md)

## Repository layout
| Path | Contents |
|---|---|
| `app/` | Flutter app (Android + iOS) |
| `docs/research/` | Market research, competitors, evidence ledger, red teams, validation debt |
| `docs/product/` | Strategy, PRD, UX spec, analytics, brand |
| `docs/engineering/` | Technical plan, privacy model |
| `docs/business/` | Monetization, distribution |
| `release/` | Store listings, Android/iOS prep, QA checklist, screenshots |
| `legal/` | Draft privacy policy and terms (need legal review) |
| `landing/` | Static landing page |

## Develop
```bash
cd app
flutter pub get
flutter analyze
flutter test
flutter run                      # device/emulator
flutter test tool/screenshots_test.dart   # regenerate release/screenshots
```
Requires Flutter 3.47.5 (stable). CI: `.github/workflows/ci.yml`.
