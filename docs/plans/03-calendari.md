# 03 — Calendari compartit

**Objetivo**: ver el Google Calendar compartido (ya sincronizado por iOS/macOS) y "decorar" cada evento: de quién es (Maria/David/los dos), emoji, color, nota y avisos extra.

## Ya existe
- `ServeiCalendari.shared`: `autoritzat`, `demanaAcces()`, `calendaris`, `esdeveniments` (próximos 60 días), `calendarisVisibles`, `clau(per:)` → id estable para la anotación.
- Modelo `AnotacioEsdeveniment` (`propietari`, `emoji`, `color: ColorEtiqueta`, `nota`, `avisos`) y `store.anotacions`.

## A construir (en `Mariapp/Features/Calendari/`)
1. Sin permiso: pantalla amable explicando + botón "Donar accés". Si no hay calendario de Google, explicar cómo añadir la cuenta (Ajustes › Calendario › Cuentas).
2. **Agenda**: lista agrupada por día ("Hui", "Demà", "dijous 6 de novembre"), cada evento en `Targeta` pequeña:
   franja de color a la izquierda (color de la anotación o del calendario), hora, título, emoji de la anotación, chip del propietario (🌻 Maria / 🐻 David / 💛 Els dos).
3. Filtro superior: Tots / Maria / David / Els dos.
4. Toque en evento → `EditaAnotacio` (sheet): propietari (segmentado), emoji (fila de sugeridos 🎂🍽️✈️🏥💼🎉🏋️‍♀️🛒💇‍♀️ + campo), color (círculos de `ColorEtiqueta` → `Paleta`), nota, avisos extra (chips). Guardar en `store.anotacions` con id `ServeiCalendari.clau(per:)`.
5. Avisos extra: programar notificaciones locales `anot.<id>.<min>` solo en el dispositivo de María (seguir el patrón de `Avisos.programa(cita:)`, añadir función análoga).
6. Botón "+" para crear evento: formulario propio simple (título, fecha, todo el día, calendario destino) que guarda con EventKit y crea su anotación. (`EKEventEditViewController` es solo iOS; mejor formulario propio para que funcione en Mac.)
7. Ajustes del calendario (desde un botón ⚙️): elegir calendarios visibles (`calendarisVisibles`).
8. En **Hui**: tarjeta "Hui al calendari" con los eventos de hoy (máx. 3) si hay permiso.

## Mapa de colores
`ColorEtiqueta.aigua → Paleta.aigua`, `.blau → .blau`, `.verd → .verd`, `.groc → .groc`, `.taronja → .taronja`, `.cafe → .cafe`. Añadir `var color: Color` en una extensión en la carpeta de la feature.

## Aceptación
- Los eventos del calendario compartido aparecen; anotar uno en el iPhone se ve en el Mac y en el móvil de David.
- Filtro por propietario funciona. Compila iOS + macOS (en macOS ya está el entitlement de calendario).
