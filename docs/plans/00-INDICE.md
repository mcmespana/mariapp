# Planes pendientes (ejecutar en orden)

Cada plan es autocontenido. Antes de empezar, lee `CLAUDE.md` y `docs/ARQUITECTURA.md`.
Definición de "hecho": el workflow **Compila Mariapp** en verde + criterios de aceptación del plan cumplidos + casilla marcada aquí.

- [x] [01 — Menú setmanal](01-menu-setmanal.md) ⭐ prioridad
- [x] [02 — Metges](02-metges.md) ⭐
- [x] [03 — Calendari compartit](03-calendari.md)
- [x] [04 — IA: sugerencias y análisis](04-ia.md)
- [x] [05 — Llista de la compra](05-llista-compra.md)
- [x] [06 — Pulido macOS](06-macos.md)
- [x] [07 — Widgets extra](07-widgets.md)
- [x] [08 — TestFlight automático](08-testflight-automatico.md) _(workflow listo; falta que una persona cree los 4 secrets, ver `docs/TESTFLIGHT.md`)_
- [x] [09 — Tests](09-tests.md)

### Segunda tanda
- [ ] [10 — Resum setmanal](10-resum-setmanal.md) ⭐
- [ ] [11 — Creuar dades (aigua ↔ molèsties)](11-creuar-dades.md)
- [ ] [12 — Receptes del món amb IA](12-receptes-ia.md) ⭐
- [ ] [13 — Widget de la compra](13-widget-compra.md)
- [ ] [14 — Apple Salut (HealthKit)](14-healthkit.md)
- [ ] [15 — Apple Watch](15-apple-watch.md) ⭐ (después del 13 y del 14)

Reglas comunes de esta tanda: campos nuevos opcionales (`init(from:)`), lógica pura en funciones testeables con tests en `MariappTests/`, y añadir las carpetas nuevas a `paths` de `.github/workflows/build.yml`.

## Cómo lanzarlo con Claude Code
> "Lee CLAUDE.md y ejecuta el siguiente plan sin marcar de docs/plans/00-INDICE.md. Haz push y no pares hasta que el workflow esté en verde."
