# Arquitectura

## Decisiones principales (y por qué)

| Decisión | Elegido | Por qué |
|---|---|---|
| Tecnología | **SwiftUI nativo**, un target para iPhone + Mac | Widgets, Live Activities, Dynamic Island, Siri, notificaciones con botones, EventKit… solo se aprovechan bien en nativo. |
| Proyecto Xcode | **XcodeGen** (`project.yml`) | El `.xcodeproj` es ilegible para agentes y da conflictos; el YAML es claro y se regenera en un segundo. |
| Backend | **Firebase Firestore** + login **anónimo** | Gratis para este uso, offline de serie, tiempo real entre dispositivos, cuenta de Google personal (fuera de MCM). Sin contraseñas. |
| Compartir con David | **Código de "llar"** (hogar) | Quien tiene el código entra. Cero cuentas. Sirve igual para el Mac de María. |
| Sin Firebase | **Modo local** (JSON en el dispositivo) | La app funciona desde el minuto 0; al crear la llar se suben los datos locales. |
| Calendario | **EventKit** (calendario del sistema) | El Google Calendar compartido ya está en iOS/macOS. Sin OAuth. Las decoraciones (emoji, color, de quién es) se guardan en Firestore. |
| IA | **API de Anthropic** directa (Haiku por defecto, Sonnet opcional) | Clave en el Llavero de cada dispositivo. |
| Idioma | Valenciano en la UI, `ca_ES` para fechas | |

### ¿Por qué no CloudKit/SwiftData?
SwiftData + CloudKit no permite compartir datos con otra cuenta de iCloud (David). Se podría con Core Data + `CKShare`, pero es mucho más complejo y frágil. Firestore resuelve sincronización + compartir + offline de golpe.

## Modelo de datos (Firestore)

```
llars/{CODI}                     { membres: [uid…], creada }
llars/{CODI}/dies/{2026-11-04}   { aiguaMl, cafes, queixes, gimnas, cansament?, dolor?, nota?, entrenament?, sonMinuts? }
llars/{CODI}/config/general      { ampollaMl, objectiuMl, escalaCansament }
llars/{CODI}/plats/{uuid}        { nom, emoji, etiquetes[], thermomix, ingredients[], recepta, imatgeURL?, … }
llars/{CODI}/menus/{2026-W45}    { apats: { "1-dinar": {platId|text}, … } }
llars/{CODI}/categoriesMetge/{id}
llars/{CODI}/cites/{uuid}        { titol, categoriaId, estat, data?, avisos[], esdevenimentId? … }
llars/{CODI}/pensaments/{uuid}
llars/{CODI}/anotacions/{hash}   { propietari, emoji, color, nota, avisos[] }
llars/{CODI}/llistaCompra/{uuid} { nom, quantitat?, comprat, platId?, ingredientId? }
```

- **Un documento por día** con contadores atómicos (`FieldValue.increment`): no importa desde dónde se apunte (widget, notificación, Mac), nunca se pisa nada.
- Fechas como segundos desde 1970 (`Double`).
- Reglas de seguridad: `firebase/firestore.rules` (solo los miembros leen/escriben).

## Flujo de una "acción rápida" (widget, Live Activity, Siri, notificación)

```
Botón del widget ──► SumaAiguaIntent (LiveActivityIntent → se ejecuta en el proceso de la app)
                         │
                         ├─► HuiSnapshot (App Group) se actualiza al momento → widget y Live Activity se repintan
                         └─► CuaAccions (cola) ──► si la app está viva: DataStore.processa → Firestore
                                                 si no: se sube al volver a abrir la app
```

## Notificaciones

- Solo en el dispositivo con rol **Maria**.
- `rutina.cansament` (18:30 por defecto) con botones Poquet / Normalet / Feta pols (20 %, 50 %, 80 % de la escala) y campo para escribir el número del 0 al 1000.
- `rutina.aigua.HH:MM` con botones ½ botella / 1 botella / café.
- `rutina.gimnas` (21:30) Sí/No.
- `cita.<id>.<minutos>`: alertas de médicos, *time-sensitive*, con sirena; además, alarma de despertador con AlarmKit (`Cita.alarmaMinuts`/`alarmaId`).
- `anot.<id>.<minutos>`: avisos extra de eventos del calendario.
- `resum.setmana`: **una sola** notificación (no repetitiva) para el próximo domingo a la hora elegida (21:00 por defecto). Su texto se calcula con los datos de ese momento y se reprograma al cambiar los días (con *debounce* de 5 s), al volver a primer plano y al cambiar las preferencias. Tocarla abre `mariapp://resum`.

## Live Activity

Se inicia al abrir la app entre las 7 y las 22 h (si está activado en Ajustos) y se cierra fuera de ese horario.
Además existe el atajo **"Comença el dia"**: se puede poner en una automatización de la app Atajos (p. ej. todos los días a las 9:00).

## Resumen semanal y cruces de datos (planes 10 y 11)

- `ResumSetmanal` (`Features/Resum/`) y `Analisi+Creuaments` (`Features/Estadistiques/`) son **lógica pura**: sin UI, sin red, probadas en `MariappTests`.
- Las frases de los cruces (agua ↔ molestias, gimnasio → cansancio de mañana, café ↔ molestias, sueño ↔ cansancio) exigen **≥ 5 días** en cada extremo y nunca son diagnósticos. Los datos que se mandan a la IA son agregados, sin notas.

## Recetas del mundo (plan 12)

```
TheMealDB (sin clave) ──► ParserReceptes (JSONSerialization: strIngredient1…20 dinámicos)
        ▲                          │
 consulta traducida por IA         ▼
                           ReceptaExterna (inglés) ──► ServeiIA.json ──► ReceptaTraduida ──► Plat (con imatgeURL)
```
Sin IA se puede guardar la receta tal cual (en inglés). «Què faig amb el que tinc?» es solo IA.

## Widget de la compra (plan 13)

`CompraSnapshot` (App Group, máx. 12 pendientes + total) → `CompraWidget` (iOS y macOS). Cada fila es un `Button(intent: MarcaCompratIntent)`: quita el elemento del snapshot al instante y encola `AccioRapida.comprat(id:)`; el `DataStore` lo marca de verdad (si todavía no han llegado los datos, lo recuerda y lo aplica al cargarlos).

## Apple Salud (plan 14, solo iPhone de María)

- `ServeiSalut` lee entrenamientos (≥ 15 min → marca el gimnasio y guarda `entrenament`, **nunca** pone `false`) y sueño (`sonMinuts` de la noche que acaba ese día, unión de intervalos para no contar dos veces iPhone + Watch), y escribe **una** muestra de agua por día (borra las suyas y reescribe: idempotente).
- Entrega en segundo plano (`HKObserverQuery`) **no** implementada: necesita el entitlement `com.apple.developer.healthkit.background-delivery`. Hoy todo se sincroniza al volver a primer plano.

## Apple Watch (plan 15)

```
iPhone ──updateApplicationContext(EstatRellotge)──► Watch (MagatzemRellotge, App Group del reloj)
Watch  ──transferUserInfo(AccioPendent) (+ sendMessage si está a mano)──► ServeiRellotge ──► DataStore.processa
```
- Sin Firebase en el reloj. Las acciones se aplican al momento en local (`EstatRellotge.aplica`) y el iPhone deduplica por el `id` de la `AccioPendent`.
- Targets: `MariappWatch` (app) y `MariappWatchWidgets` (complicaciones: agua, cansancio, próxima cita). Comparten con el iPhone `Shared/Compartit.swift`, `SnapshotsExtra.swift` y `Paleta.swift`.
