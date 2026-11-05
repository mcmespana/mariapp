# 🌻 Mariapp

La app de María. Nativa (SwiftUI) para **iPhone y Mac**, con sincronización entre dispositivos y la posibilidad de invitar a David.
Interfaz en **valenciano**; documentación en castellano.

## Qué hace (hoy)

| Sección | Estado | Qué hay |
|---|---|---|
| **Hui** (hoy) | ✅ | Agua con botella animada (¼, ½, 1 botella de 750 ml), cafés, gimnasio, cansòmetre 0–1000 (dial de plastilina), molestias de orina, contador de quejas sobre David, nota del día |
| **Estadístiques** | ✅ | Gimnasio por mes (🏆 mejor mes), cansancio medio, día de la semana más cansado, cafés vs cansancio, agua, días con molestias, quejas |
| **David** | ✅ | Pensamientos sobre David: quejas, agradecimientos, cosas bonitas, ideas |
| **Fills / Filles / Fillis…** | ✅ | El nombre cambia cada día. Burbujas y magia. |
| **Ajustos** | ✅ | Quién eres, sincronización + invitar, avisos y horas, botella/objetivo, calendario, IA |
| Notificaciones | ✅ | 18:30 cansancio (respondes desde la notificación), recordatorios de agua configurables, gimnasio por la noche. Con sonidos propios |
| Widgets + Live Activity | ✅ | Widget de pantalla de inicio/bloqueo con botones, Live Activity con Dynamic Island, controles del Centro de Control, Siri |
| **Menú setmanal** | 🛠️ plan 01 | Platos, etiquetas, Thermomix, menú de la semana, sugerencias |
| **Metges** | 🛠️ plan 02 | Citas, "pedir cita", alertas EXAGERADAS, calendario |
| **Calendari** | 🛠️ plan 03 | Google Calendar compartido con emojis, colores y de quién es |

Los planes para terminar el resto están en [`docs/plans/`](docs/plans/00-INDICE.md), listos para que Claude (Sonnet) los ejecute uno detrás de otro.

## Arrancar en el Mac (la primera vez)

1. Instala **Xcode** desde la App Store y ábrelo una vez (acepta la licencia).
2. Clona el repo y en Terminal, desde la carpeta:
   ```bash
   ./scripts/obre-xcode.sh
   ```
   (instala XcodeGen si hace falta, genera el proyecto y lo abre).
3. En Xcode: proyecto *Mariapp* → target *Mariapp* → **Signing & Capabilities** → elige tu *Team*. Haz lo mismo en *MariappWidgets*.
   Para no tener que repetirlo, crea `Config/Local.xcconfig` con `DEVELOPMENT_TEAM = TU_TEAM_ID`.
4. Conecta el iPhone por cable, elígelo arriba y pulsa ▶︎.

> Sin Firebase la app funciona perfectamente, pero guardando solo en ese dispositivo.

## Sincronizar e invitar (Firebase)

Ver [`docs/FIREBASE.md`](docs/FIREBASE.md). Resumen: `./scripts/configura-firebase.sh` + un clic en la consola.

## Instalarla en los móviles (TestFlight)

Ver [`docs/TESTFLIGHT.md`](docs/TESTFLIGHT.md).

## Más documentación

- [`docs/ARQUITECTURA.md`](docs/ARQUITECTURA.md) — cómo está montado todo y por qué.
- [`CLAUDE.md`](CLAUDE.md) — normas para los agentes que sigan desarrollando.
- [`docs/IDEAS.md`](docs/IDEAS.md) — sugerencias para el futuro.
