# 15 — Apple Watch ⌚️

**Objetivo**: María tiene Apple Watch. Desde la muñeca: apuntar agua, café y quejas, el cansòmetre con la **Digital Crown** (0–1000 🎯), ver la próxima cita y el menú de hoy, y complicaciones en la esfera.

Hazlo después del 13 (usa `AccioRapida`) y del 14 (Salud, opcional). Sin skill específica: SwiftUI + WidgetKit (`widgetkit`) + WatchConnectivity.

## Arquitectura (decidida)
- **Sin Firebase en el reloj.** El reloj habla con el iPhone por **WatchConnectivity**:
  - iPhone → reloj: `updateApplicationContext` con un `EstatRellotge` (Codable): `HuiSnapshot`, `CitaSnapshot?`, `ParellaMenu?` de hoy y `escalaCansament`. Se envía cada vez que cambian (desde `DataStore.actualitzaSnapshot()` y `actualitzaSnapshotsExtra()`), con *debounce* corto.
  - Reloj → iPhone: `transferUserInfo(["accio": <AccioPendent JSON>])` (llega aunque el iPhone esté bloqueado o la app cerrada; la app lo procesa al despertar). Si `isReachable`, además `sendMessage` para que sea inmediato.
  - En el iPhone: `ServeiRellotge` (`WCSessionDelegate`, `#if os(iOS)`, activado en `Arrencada.enArrancar`) decodifica la acción y llama a `DataStore.processa([accio])`.
- El reloj aplica la acción **en local al momento** (optimista) sobre su copia del estado y recarga sus complicaciones.
- `AccioRapida`: añadir `.cansament(Int)` (además de `.comprat` del plan 13). `processa` → `posa(.cansament, valor)`.

## Proyecto (`project.yml`)
- Target `MariappWatch`: `type: application`, `platform: watchOS`, deployment `watchOS: "26.0"` (añadir en `options.deploymentTarget`), bundle `$(MARIAPP_BUNDLE_ID).watchkitapp`, Info: `WKApplication: true`, `WKCompanionAppBundleIdentifier: $(MARIAPP_BUNDLE_ID)`, `CFBundleDisplayName: Mariapp`. Fuentes: `MariappWatch/` + archivos sueltos de `Shared/` (**no** toda la carpeta): `Compartit.swift`, `SnapshotsExtra.swift`, `Paleta.swift`. Recursos: los sonidos no hacen falta.
- Target `MariappWatchWidgets`: `type: app-extension`, `platform: watchOS`, bundle `$(MARIAPP_BUNDLE_ID).watchkitapp.widgets`, `NSExtensionPointIdentifier: com.apple.widgetkit-extension`, embebido en `MariappWatch`. App Group compartido con la app del reloj (entitlements nuevos `Config/MariappWatch.entitlements` y `Config/MariappWatchWidgets.entitlements` con `$(MARIAPP_APP_GROUP)`).
- Embeber el reloj en la app iOS: dependencia `- target: MariappWatch` con `destinationFilters: [iOS]` en el target `Mariapp` (XcodeGen crea la fase "Embed Watch Content"). Si da problemas con el target multiplataforma, alternativa: compilar el reloj en su propio esquema y dejar el embebido documentado como paso manual en `docs/`.
- `Paleta.swift`: `UIColor(dynamicProvider:)` no existe en watchOS → añadir rama `#if os(watchOS)` que devuelva siempre el color **oscuro** (el reloj siempre es oscuro).
- **CI** (`build.yml`): añadir `watchos` al `grep` de "Versions disponibles", rutas `MariappWatch/**` y `MariappWatchWidgets/**`, y un paso "Compila watchOS" (`-scheme Mariapp -destination 'generic/platform=watchOS'` o el esquema del reloj). Si el runner no tiene el SDK de watchOS, añadir antes `xcodebuild -downloadPlatform watchOS`. **El primer commit del plan debe ser solo el esqueleto del reloj** (una vista "Hola") para validar proyecto + CI antes de escribir funciones.

## A construir (app del reloj, `MariappWatch/`)
1. `EstatRellotge` compartido (en `Shared/SnapshotsExtra.swift` para que lo vean iPhone, reloj y widgets del reloj) y `MagatzemRellotge` (`@Observable`, en el reloj): guarda el último estado en el App Group del reloj, aplica acciones optimistas, envía por `WCSession` y `WidgetCenter.shared.reloadAllTimelines()`.
2. **Pantallas** (`TabView` vertical, estilo `.verticalPage`):
   - **Aigua**: anillo grande (como `AnellAigua`) con ml / objetivo y botones "+½" y "+1" (botella), `WKInterfaceDevice.current().play(.success)` al llegar al objetivo.
   - **Cansòmetre**: número gigante 0–1000 controlado con `.digitalCrownRotation($valor, from: 0, through: escala, by: 10, sensitivity: .medium, isHapticFeedbackEnabled: true)`, emoji que cambia (mismos 11 emojis que `EscalaCansament`, copiar la tabla al reloj) y botón "Apuntar".
   - **Ràpids**: "☕️ Café" y "😤 Queixa" con contador del día.
   - **Hui**: próxima cita (en `Paleta.alerta`, "ÉS HUI!" si toca) y menú de hoy (☀️ / 🌙).
   - Estilo: fondo negro, acentos de `Paleta` (oscuros), tipografía `.rounded`, títulos serif; botones con `.buttonStyle(.borderedProminent)` y `tint` del color de cada cosa (en el reloj no hace falta la plastilina).
3. **Complicaciones** (`MariappWatchWidgets/`, WidgetKit): leen el `EstatRellotge` del App Group.
   - `accessoryCircular`: `Gauge` de agua (y otra variante: emoji del cansancio).
   - `accessoryRectangular`: agua + cafés, o próxima cita con cuenta atrás (`Text(data, style: .relative)`).
   - `accessoryInline`: "💧 1,5 L · ☕️ 2".
   - `accessoryCorner`: gauge de agua.
   - Tocar la complicación abre la app en la pantalla correspondiente (`widgetURL`).
   - (Opcional) Smart Stack: `relevance` alta cuando hay cita hoy.
4. **Notificaciones**: las del iPhone (agua, cansancio, gimnasio, citas) ya se reflejan en el reloj con sus botones; comprobar que al responder desde el reloj se ejecuta `RespostaNotificacio` en el iPhone. Las alarmas de AlarmKit ya suenan en el reloj.
5. **Tests** (en `MariappTests`): codificación de `EstatRellotge`; `AccioRapida.cansament` se procesa bien; aplicación optimista en una función pura `EstatRellotge.aplica(_ accio:)`.

## Aceptación
- Apuntar agua o café en el reloj → aparece en el iPhone (y en el Mac / David vía Firestore) en segundos; con el iPhone lejos, llega al reconectar.
- Cansòmetre con la corona apunta el valor exacto.
- Complicaciones en la esfera se actualizan tras cada acción y cuando cambia algo en el iPhone.
- Compila iOS + macOS + watchOS en CI y los tests pasan.
