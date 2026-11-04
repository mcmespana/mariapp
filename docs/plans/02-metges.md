# 02 — Metges 🚨

**Objetivo**: que a María NO se le olvide ningún médico. Esta sección rompe la calma a propósito: rojo, alertas exageradas, divertido.

## Ya existe
- Modelos `Cita`, `EstatCita` (`perDemanar`, `programada`, `feta`), `CategoriaMetge` (+ `perDefecte`, se siembran solas). Colecciones `store.cites`, `store.categoriesMetge`, `store.categoriesOrdenades`.
- `Avisos.programa(cita:categoria:)` y `Avisos.cancela(citaId:)` (alertas *time-sensitive* con `sirena.wav`; solo en el dispositivo de María).
- `ServeiCalendari.shared.sincronitza(cita:categoria:)` crea/actualiza el evento en el calendario (con alarmas) y devuelve el `eventIdentifier`; `esborra(esdevenimentId:)`.
- `Paleta.alerta` y `Paleta.alertaFons`.

## A construir (en `Mariapp/Features/Metges/`)
1. **MetgesView**:
   - Cabecera gigante: "🚨 METGES 🚨" con `Paleta.alerta`, pulsando suavemente (`symbolEffect(.pulse)` / escala).
   - Bloque **"Pròxima cita"**: tarjeta enorme roja con cuenta atrás ("en 3 dies, 4 hores"), lugar, categoría. Si es hoy: "ÉS HUI!!! 🏃‍♀️💨" parpadeando.
   - Bloque **"Cal demanar cita"** (estat `perDemanar`): lista con botón "📞 Ja l'he demanada" que abre el editor para poner fecha → pasa a `programada`.
   - Bloque **"Programades"** ordenadas por fecha.
   - Bloque **"Fetes"** plegado (`DisclosureGroup`).
   - Filtro por categoría (chips con emoji).
2. **EditaCita** (Form): títol, categoria (Picker con emoji), estat, data+hora (si programada), durada, lloc, notes,
   **avisos** (multi-selección de chips: "1 setmana", "3 dies", "1 dia", "la vesprada abans (19:00)", "3 hores", "1 hora", "30 min"; permitir varios),
   "recorda'm demanar-la el…" (si `perDemanar`), toggle "Afegir al calendari" (por defecto sí).
   Al guardar: `store.cites.desa`, `Avisos.programa`, y si calendario → `sincronitza` y guardar `esdevenimentId`.
   Al borrar: `Avisos.cancela` + `ServeiCalendari.esborra`.
3. **Categorías**: pantalla "Gestionar categories" (añadir, renombrar, emoji, reordenar con `onMove`, borrar si no hay citas).
4. Al marcar una cita como `feta` → confeti/`Sons.toca(.festa)` + texto "Una menys! 💪".
5. Tarjeta en **Hui**: si hay una cita en los próximos 7 días o alguna `perDemanar` con recordatorio vencido, mostrar arriba del todo una `Targeta` roja de aviso que lleva a Metges.
6. Al volver la app a primer plano, reprogramar avisos de todas las citas futuras (por si se crearon desde otro dispositivo): en `Arrencada.enTornarAlPrimerPla`.

## Aceptación
- Crear cita "por pedir" con recordatorio → llega la notificación con sirena.
- Crear cita programada con 3 avisos → 3 notificaciones pendientes (`getPendingNotificationRequests`) + evento en calendario con alarmas.
- Editar fecha → avisos y evento se actualizan. Borrar → desaparecen.
- David ve las citas pero no recibe notificaciones.
