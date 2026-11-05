# 11 — Creuar dades: aigua ↔ molèsties (i més) 🔍

**Objetivo**: ver si beber más agua coincide con menos molestias de orina (y otras relaciones curiosas), con frases prudentes y gráficas claras.

## Ya existe
- `Dia.aiguaMl`, `Dia.dolor` (0 gens … 3 molt, `nil` = no apuntado), `Dia.cafes`, `Dia.gimnas`, `Dia.cansament`.
- `Analisi.cafesVsCansament` + `fraseCafes` como modelo a seguir. `EstadistiquesView` con tarjetas de `Chart`.

## A construir
1. **Lógica pura** en `Analisi` (o `Analisi+Creuaments.swift`):
   - `enum TramAigua: CaseIterable { menysDe1L, de1a1_5, de1_5a2, mesDe2L }` con `nom` ("< 1 L", "1–1,5 L"…), calculado como % del objetivo **o** en litros fijos (usar litros fijos; más fácil de entender).
   - `aiguaVsMolesties(_ dies:) -> [PuntAiguaMolesties]` (`tram`, `dies`, `diesAmbMolesties`, `percentatge`, `dolorMitja`). Solo días con `dolor != nil` **y** `aiguaMl > 0`.
   - `aiguaAhirVsMolesties(_ dies:)`: igual pero con el agua **del día anterior** (las molestias suelen llegar después). Emparejar por `ClauDia` (día d-1 ↔ día d).
   - `fraseAiguaMolesties(_ punts:) -> String?`: necesita ≥ 5 días en el tramo bajo y ≥ 5 en el alto; si no, `nil`. Ejemplos: "Els dies que beus menys d'1 L tens molèsties el 60 % de les vegades; quan passes de 2 L, el 15 %. 💧 Pareix que l'aigua t'ajuda." / "No es veu cap relació clara (encara)." Siempre en tono prudente, nunca diagnóstico.
   - Extra (mismo patrón, frases opcionales): `gimnasVsCansamentEndema` (cansancio el día después de ir al gimnasio vs no ir) y `cafesVsMolesties`.
2. **UI** en `EstadistiquesView`: tarjeta "Aigua i molèsties" (color `Paleta.groc`) con:
   - `Picker` segmentado "El mateix dia | El dia abans".
   - `Chart` de barras: X = tramo de agua, Y = % de días con molestias, anotación con nº de días.
   - La frase y debajo, en pequeño: "Són correlacions, no diagnòstics. Si les molèsties continuen, comenta-ho amb la metgessa 🩺".
   - Tarjeta pequeña "Gimnàs i cansament de l'endemà" si hay datos.
3. **IA**: añadir estas series agregadas a `Analisi.resumPerIA` para que "✨ Analitza el meu mes" también las comente.
4. **Si ya está hecho el plan 14 (HealthKit)**: añadir aquí `sonVsCansament` (horas de sueño de la noche anterior vs cansancio). Si no, dejar un `TODO(plan 14)`.
5. **Tests** (`MariappTests/CreuamentsTests.swift`): asignación a tramos (bordes 1000/1500/2000 ml), emparejado con el día anterior (incluido cambio de mes), umbrales de la frase, días sin `dolor` ignorados.

## Aceptación
- Con datos de prueba (≥ 10 días variados) la gráfica y la frase son coherentes; con pocos datos sale "Encara no hi ha prou dies per a dir res 🤷‍♀️".
- Compila iOS + macOS y los tests pasan.
