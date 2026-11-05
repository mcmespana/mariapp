# 13 — Widget de la llista de la compra 🛒

**Objetivo**: ver lo que falta comprar desde la pantalla de inicio (y en el Mac) y tacharlo con un toque, sin abrir la app.

## Ya existe
- `ElementCompra`, `store.llistaCompra`, `LlistaCompra.marca(_:comprat:)` (también marca "el tenim" en el plato).
- Patrón de snapshot en App Group: `Shared/SnapshotsExtra.swift` (`CitaSnapshot`, `MenuSnapshot`) escrito en `DataStore.actualitzaSnapshotsExtra()`.
- Patrón de acción rápida: `AccioRapida` + `CuaAccions` + `AccionsRapides.executa` + `DataStore.processa`. Intents en `Shared/Intents.swift` (`IntentRapid` = `LiveActivityIntent` en iOS, se ejecuta en el proceso de la app).
- Widgets comunes iOS/macOS en `WidgetsComuns/` (registrar en `MariappWidgets.swift` y `MariappWidgetsMac.swift`).

## A construir
1. **Snapshot** `CompraSnapshot` en `Shared/SnapshotsExtra.swift`: `pendents: [ItemCompra]` (`id`, `nom`, `quantitat?`), ordenados por `creat`, máximo 12, y `totalPendents`. Escribirlo en `actualitzaSnapshotsExtra()` (enganchar `llistaCompra.enCanviar`).
2. **Acción**: nuevo caso `AccioRapida.comprat(id: String)` (los casos nuevos no rompen el `Codable` de los antiguos; comprobarlo con un test).
   - `AccionsRapides.executa(.comprat)`: quita el elemento del `CompraSnapshot` al momento (optimista) y lo encola.
   - `DataStore.processa`: caso `.comprat(let id)` → si existe `llistaCompra[id]`, `LlistaCompra.marca(e, comprat: true)`.
   - `actualitzaSnapshot()` (Hui) debe ignorar el caso nuevo.
3. **Intent** `MarcaCompratIntent: IntentRapid` (en `Shared/Intents.swift`) con `@Parameter id: String` + `init(id:)`.
4. **Widget** `WidgetsComuns/CompraWidget.swift` (kind `es.mariapp.compra`):
   - `systemSmall`: "🛒 N per comprar" y los 3 primeros.
   - `systemMedium`: 4–5 filas, cada una `Button(intent: MarcaCompratIntent(id:))` con círculo → al tocar se tacha (`.contentTransition`/`.invalidatableContent()`).
   - `systemLarge`: hasta 10 filas + "+ N més".
   - iOS: `accessoryRectangular` ("🛒 5: llet, pa, ous…").
   - Vacía: "Res a comprar 🎉". `widgetURL(mariapp://compra)`.
   - Colores `Paleta.verd`, fondo `Paleta.fons`, título serif.
5. **Control** (iOS 18+, opcional): `ControlWidgetButton` "Obrir la compra" que abre `mariapp://compra` (`OpenURLIntent` o intent con `openAppWhenRun`).
6. **Siri** (opcional, encaja aquí): `AfegeixCompraIntent` ("Afig llet a la compra") que crea un `ElementCompra` — ver skill `app-intents`; añadir frase en `Mariapp/App/Dreceres.swift`.
7. **Tests**: `AccioRapida` antigua (`aigua`, `cafe`, `queixa`) se sigue decodificando tras añadir el caso; `CompraSnapshot` limita a 12 y cuenta bien.

## Aceptación
- Añadir cosas en la app → aparecen en el widget; tocar una en el widget → se tacha al momento y, al abrir la app (o enseguida si está viva), queda comprada en todos los dispositivos.
- Funciona en iPhone y en el widget del Mac. Compila iOS + macOS y los tests pasan.
