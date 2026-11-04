# 01 — Menú setmanal

**Objetivo**: guardar platos favoritos, clasificarlos y montar el menú de la semana en pocos toques, con sugerencias.

## Ya existe
- Modelos `Plat`, `EtiquetaPlat`, `Ingredient`, `MenuSetmana`, `EntradaMenu`, `Apat` en `Mariapp/Data/Models.swift`.
- Colecciones `store.plats`, `store.menus`. `MenuSetmana.id(per:)` da el id ISO de semana; claves `"<1-7>-dinar|sopar"` (1 = dilluns).
- Placeholder `Mariapp/Features/Menu/MenuView.swift`.

## A construir (en `Mariapp/Features/Menu/`)
1. **MenuView** con un selector segmentado arriba: **Setmana** | **Plats**.
2. **Setmana** (`SetmanaView`):
   - Cabecera con la semana ("4 – 10 de novembre") y flechas ← → para cambiar de semana; botón "Hui".
   - 7 filas (dilluns…diumenge), cada una con 2 huecos: ☀️ Dinar y 🌙 Sopar. Hoy resaltado.
   - Hueco vacío → toque abre `TriaPlat` (sheet): buscador, filtros por etiqueta (chips `Xip`), arriba "Suggeriments" (ver 4), opción "Text lliure" (p. ej. "Sopar fora 🎉"), opción "Buidar".
   - Hueco lleno: emoji + nombre + mini iconos (🥡 táper, Thermomix). Menú contextual: canviar, buidar, veure recepta.
   - Botón "✨ Omplir la setmana" que rellena huecos vacíos con sugerencias (respetando: sopar → preferir `lleuger`+`sopar`; dinar → `dinar`; evitar repetir plato en la misma semana).
   - Botón "Copiar setmana anterior".
3. **Plats** (`PlatsView`):
   - Rejilla de tarjetas (`LazyVGrid adaptive 160`) con emoji grande, nombre, chips de etiquetas, badge "Thermomix" y ⭐ favorito.
   - Filtros: chips por etiqueta + toggle "Només Thermomix" + buscador (`.searchable`).
   - "+" → `EditaPlat` (Form): nom, emoji (TextField de 1 carácter), etiquetes (multi-selección con chips), Thermomix, ingredients (lista editable con toggle "el tenim"), recepta (texto largo), enllaç (URL), notes, favorit.
   - Detalle `DetallPlat`: todo bonito; enlace abre Safari; botón "Afegir al menú" (elige día/apat).
   - Al primer arranque con 0 platos: sembrar 8–10 platos ejemplo (crema de carabassa (Thermomix, lleuger, sopar), truita de carabasseta, amanida de cigrons (tupper), salmó al forn, hummus (Thermomix), arròs al forn (contundent, dinar), lasanya de verdures (tupper), crema de porros (Thermomix, lleuger, sopar), poke bowl, gaspatxo (Thermomix, estiu)).
4. **Sugerencias sin IA** (`SuggeridorMenu.swift`, lógica pura y testeable):
   - Puntuación: +3 si coincide la etiqueta del apat (`sopar`/`dinar`), +2 `lleuger` para sopars, +2 favorito, −5 si ya está esta semana, −2 si se comió la semana anterior, + aleatoriedad pequeña.
   - Devuelve top 5.
5. **IA (opcional si `ServeiIA.configurada`)**: en `TriaPlat` un botón "✨ Idees noves amb IA" que pide a Claude 3 platos nuevos en JSON (`[{nom, emoji, etiquetes, thermomix, ingredients}]`) teniendo en cuenta el resto de la semana; poder guardarlos como `Plat` con un toque. Ver plan 04 para el helper JSON.

## Diseño
Color de sección `Paleta.verd`. Huecos vacíos con borde discontinuo suave y "+". Usar `Targeta`. Animación `spring` al asignar plato + `Sons.toca(.cafe)`.
En Mac (ancho > 700) mostrar la semana como 7 columnas y los platos a la derecha (arrastrar y soltar plato → hueco con `.draggable`/`.dropDestination` usando el id del plato como `String`).

## Aceptación
- Crear/editar/borrar platos; filtros funcionan; Thermomix visible.
- Asignar plato o texto libre a cualquier hueco; navegar semanas; "Omplir" y "Copiar anterior" funcionan.
- David (rol convidat) puede ver y editar el menú (es compartido).
- Compila iOS + macOS.
