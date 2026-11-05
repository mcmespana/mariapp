# 12 — Receptes del món, traduïdes per la IA 🌍🍲

**Objetivo**: buscar recetas en una API gratuita (TheMealDB), verlas con foto, y que la IA las traduzca al valenciano (y las adapte a Thermomix si se quiere) para guardarlas como `Plat` con un toque. Además, "Què faig amb el que tinc?": recetas a partir de ingredientes.

## Ya existe
- `Plat` (con `recepta`, `enllac`, `ingredients`, `thermomix`), `EditaPlat`, `DetallPlat`, `PlatsView`.
- `ServeiIA.pregunta`, `ServeiIA.json` (con reintento), `BotoIA`, `ResultatIA`, `.shimmer()`.
- Entitlement de red en macOS (`network.client`) ya está.

## API (sin clave, gratuita: clave pública "1")
Base `https://www.themealdb.com/api/json/v1/1/`:
- `search.php?s=<nom>` · `filter.php?i=<ingredient>` · `filter.php?c=<categoria>` · `filter.php?a=Spanish` · `lookup.php?i=<id>` · `random.php` · `categories.php`.
- Respuesta: `{"meals": [ {...} ] | null}`. Campos: `idMeal, strMeal, strCategory, strArea, strInstructions, strMealThumb, strYoutube, strSource, strIngredient1…20, strMeasure1…20`. Los `filter.php` solo devuelven `idMeal, strMeal, strMealThumb` → pedir el detalle con `lookup.php`.
- Todo está **en inglés**.

## A construir
1. **Modelo** `Plat`: campo nuevo opcional `imatgeURL: String?` (+ en `init(from:)`, regla de oro). Mostrarla en `TargetaPlat` y `DetallPlat` con `AsyncImage` recortada con esquinas `Clay.radiMitja` dentro de la plastilina (placeholder: el emoji). `EditaPlat`: campo "Foto (URL)".
2. **Servicio** `Mariapp/Services/ServeiReceptes.swift`:
   - `struct ReceptaExterna: Identifiable, Hashable { id, nom, categoria?, area?, instruccions, imatge: URL?, youtube: URL?, font: URL?, ingredients: [(nom, mesura)] }` (usar un `struct IngredientExtern: Hashable`).
   - Parseo con `JSONSerialization` (las claves `strIngredientN` son dinámicas); descartar ingredientes vacíos.
   - `cerca(_:)`, `perIngredient(_:)`, `perCategoria(_:)`, `espanyoles()`, `detall(id:)`, `aleatoria()`. `URLSession` async, errores amables ("No hi ha connexió 📡").
   - La búsqueda del usuario está en valenciano: si hay IA configurada, traducir primero la consulta al inglés con una petición corta (`maxTokens` 50, "Respon només amb la traducció"); si no hay IA, buscar tal cual.
3. **Traducción** `ServeiIA.json` → `ReceptaTraduida { nom, emoji, etiquetes: [String], thermomix: Bool, ingredients: [String], passos: [String] }`:
   - Prompt: traducir al valenciano (AVL cercano), cantidades en sistema métrico (tazas → g/ml), pasos numerados y breves, elegir etiquetas solo de `lleuger, contundent, dinar, sopar, tupper, rapid`.
   - Opción "🫕 Adapta-la a la Thermomix (TM6)": mismo prompt con pasos TM6 (tiempo / temperatura / velocidad) y `thermomix: true`.
   - Convertir a `Plat`: `recepta` = pasos unidos con saltos de línea, `enllac` = `strSource` o YouTube, `imatgeURL` = foto, `notes` = "Recepta de TheMealDB (\(area))".
4. **UI** `Features/Menu/ReceptesMonView.swift` (accesible desde `PlatsView` con botón "🌍 Receptes del món" y desde `TriaPlat`):
   - Buscador + chips: "Espanyoles 🇪🇸", "Sorprén-me 🎲" (`random`), categorías traducidas (Pasta, Peix, Vegetarià, Pollastre, Postres, Entrants…).
   - Rejilla de resultados con foto, nombre original; tocar → `DetallReceptaExterna`: foto grande, ingredientes y pasos **en inglés** mientras no se traduce; botones `BotoIA` "✨ Tradueix-la" y "🫕 Tradueix i adapta a Thermomix" (con shimmer); tras traducir, vista en valenciano y botón "Guardar als meus plats" (y "Guardar i posar al menú" si se vino desde `TriaPlat`).
   - Sin clave de IA: se puede guardar igualmente en inglés (aviso amable con enlace a Ajustos).
5. **"Què faig amb el que tinc?"** (solo IA, en `ReceptesMonView`): campo de ingredientes (chips) → `ServeiIA.json` devuelve 3 propuestas `ReceptaTraduida` completas, con opción Thermomix; guardar con un toque. Puede sugerir primero recetas de TheMealDB que contengan el ingrediente principal (`filter.php?i=`) y que la IA elija/adapte.
6. **Tests** (`MariappTests/ReceptesTests.swift`): parseo de un JSON de ejemplo de TheMealDB (incluido en el test, sin red) con ingredientes vacíos y `meals: null`; conversión `ReceptaTraduida → Plat`; `Plat` antiguo sin `imatgeURL`.

## Diseño
Color `Paleta.verd` + toques `Paleta.groc` para lo de IA. Fotos dentro de `Targeta` (no fondos planos). `Sons.toca(.festa)` al guardar.

## Aceptación
- Buscar "pasta" (o "pollastre" con IA) devuelve resultados con foto; una receta se traduce al valenciano y se guarda como plato con foto, ingredientes y pasos; la adaptación Thermomix da pasos TM6.
- Sin red o sin clave, mensajes amables. Compila iOS + macOS y los tests pasan.
