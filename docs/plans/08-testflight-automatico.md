# 08 — TestFlight automático

Requiere que el humano cree en App Store Connect una **API Key** (Users and Access → Integrations → App Store Connect API → Team Key con rol *App Manager*) y la guarde como secrets del repo:
`ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8` (contenido del .p8), `TEAM_ID`.

1. Workflow `.github/workflows/testflight.yml` (manual `workflow_dispatch` + tags `v*`):
   xcodegen → `xcodebuild archive` con firma automática usando `-allowProvisioningUpdates -authenticationKeyPath …` → `xcodebuild -exportArchive` (method `app-store-connect`, destination `upload`).
2. Número de build automático: `CURRENT_PROJECT_VERSION=$GITHUB_RUN_NUMBER`.
3. Igual para macOS (job separado).
4. Documentar en `docs/TESTFLIGHT.md`.
Alternativa sin secretos en GitHub: **Xcode Cloud** (se configura desde Xcode → Product → Xcode Cloud; 25 h/mes gratis).
