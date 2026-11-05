# 05 — Llista de la compra

1. Nueva colección `LlistaCompra` (doc único `actual`) o `ElementCompra` (uno por ítem: `nom`, `quantitat?`, `comprat`, `platId?`, `creat`). Preferible un doc por ítem (menos conflictos).
2. Botón en la semana del menú: "🛒 Generar llista" → para cada plato de la semana, ingredientes con `tenim == false` → crear elementos (sin duplicar por nombre normalizado).
3. Vista `LlistaCompraView` (accesible desde Menú y desde Més): agrupada (pendents / comprats), tachar con animación, "+" rápido, borrar comprats, compartir como texto (`ShareLink`).
4. Al marcar comprat un ingrediente que viene de un plato → poner `tenim = true` en el plato.
5. Widget opcional (plan 07).
