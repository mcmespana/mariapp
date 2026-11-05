# 10 — Resum setmanal 📊

**Objetivo**: el domingo por la noche, una notificación cariñosa con cómo ha ido la semana, y una pantalla bonita con el detalle.

## Ya existe
- `Analisi` (cálculos puros), `Dia`, `DataStore.dies`, `Avisos` (patrón: borrar y añadir en el mismo callback de `getPendingNotificationRequests`).
- `Navegacio.obri(_:)` para enlaces `mariapp://…`. `Preferencies` (ajustes por dispositivo).
- `ServeiCites.properaCita`, `MenuSnapshot` (menú de los próximos 7 días).

## A construir
1. **Lógica pura** `Mariapp/Features/Resum/ResumSetmanal.swift`:
   - `struct ResumSetmana { inici: Date; aiguaTotalMl; millorDiaAigua: (dia, ml)?; diesObjectiuAigua; diesGimnas; cansamentMitja: Double?; diaMesCansat / diaMenysCansat: (dia, valor)?; cafes; queixes; diesMolesties; diesApuntats }`.
   - `static func calcula(dies: [Dia], setmana inici: Date, objectiuMl: Int) -> ResumSetmana` (semana ISO lunes–domingo, usa `Setmana`).
   - `static func comparativa(actual:, anterior:) -> [String]`: frases cortas tipo "💧 +1,2 L més que la setmana passada", "🏋️‍♀️ 1 dia més de gimnàs". Solo si hay datos suficientes.
   - `static func titolNotificacio(_:) / cosNotificacio(_:)`: texto ≤ 2 líneas con el mejor dato de la semana y las quejas con humor ("😤 3 queixes sobre David. Ell diu que són poques.").
2. **Notificación** (solo dispositivo de María, si `prefs.resumSetmanal` está activo; por defecto sí):
   - Nuevas preferencias `resumSetmanal: Bool` y `horaResum: Hora` (domingo 21:00 por defecto) en `Preferencies` + `Ajustos › Avisos`.
   - `Avisos.programaResum()`: notificación **única** (no repetitiva) para el próximo domingo a la hora elegida, id `resum.setmana`, categoría nueva `RESUM`, sonido `campaneta`. El contenido se calcula con los datos actuales.
   - Recalcular y reprogramar: en `Arrencada.enTornarAlPrimerPla`, al cambiar `dies` (con *debounce* de ~5 s en `DataStore`, no en cada toque) y al cambiar la preferencia.
   - Si a la hora de programar todavía no hay datos de esa semana: texto genérico "Ja tens el resum de la setmana 📊 Obri'l i mira com t'ha anat".
   - (Opcional, si da tiempo) `BGAppRefreshTask` el domingo por la tarde para refrescar el contenido aunque no se abra la app: id `es.mariapp.resum` en `BGTaskSchedulerPermittedIdentifiers` y `UIBackgroundModes: [fetch]` en `project.yml`. Solo iOS (`#if os(iOS)`).
3. **Pantalla** `ResumSetmanaView` (en `Features/Resum/`):
   - Selector de semana (← →, como en el menú), por defecto la última semana completa (o la actual si es domingo).
   - Tarjetas `Targeta`: 💧 agua (total, mejor día, días con objetivo, mini `Chart` de barras por día con `RuleMark` del objetivo), 🏋️‍♀️ gimnasio (puntitos L M X J V S D), 😮‍💨 cansancio (media + día más duro), ☕️ cafés, 😤 quejas, molestias, y "La setmana que ve": próxima cita y menú del lunes.
   - Bloque "Comparat amb la setmana passada" con las frases de `comparativa`.
   - `BotoIA` "✨ Un comentari per a la setmana" (reutiliza `ServeiIA.pregunta` con datos **agregados**, nada de notas; mismo tono que `AnalisiIAView`).
   - Accesos: toque en la notificación (`mariapp://resum` → abre la hoja), botón en `EstadistiquesView` (toolbar) y una tarjeta en **Hui** los domingos desde las 18:00 y los lunes ("Mira el resum de la setmana ✨").
   - `Navegacio`: nuevo `mostraResum: Bool`, caso `"resum"` en `obri(_:)`. `RespostaNotificacio`: categoría `RESUM` → `mostraResum = true`.
4. **Tests** (`MariappTests/ResumSetmanalTests.swift`): semana con días sin apuntar, mejor día, días de objetivo, comparativa con semana anterior vacía (no debe dar frases), texto de la notificación sin datos.

## Diseño
Color `Paleta.aigua` para la pantalla, títulos `.titolGran()`, animación `Clay.molla` al cambiar de semana, `Sons.toca(.festa)` si la semana tiene ≥ 5 días de objetivo de agua (con `sensoryFeedback(.success)`).

## Aceptación
- El domingo a la hora elegida llega la notificación con datos reales de la semana (comprobar en `getPendingNotificationRequests` que existe `resum.setmana` con fecha del próximo domingo).
- Tocarla abre el resumen. David ve el resumen desde Estadísticas pero no recibe notificación.
- Compila iOS + macOS y los tests pasan.
