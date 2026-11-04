# Instrucciones para agentes (Claude)

App nativa SwiftUI para **iOS 26+ y macOS 26+** (los móviles ya están en iOS 27) (un único target multiplataforma) + extensión de widgets iOS.
El proyecto Xcode se genera con **XcodeGen** desde `project.yml` (no hay `.xcodeproj` en git).

## Reglas

1. **Interfaz en valenciano** (normativo AVL pero cercano y "de poble": *hui, este/esta, eixir, xicotet, vore, faena, prompte*).
   Tutea a María. Humor suave, emojis con moderación. **Documentación y commits en castellano.**
2. **Estilo "soft clay"** (plastilina suave sobre crema): usa siempre los componentes de `Mariapp/Design/Tema.swift` y `Clay.swift`
   (`Targeta`, `CapcaleraTargeta`, `BotoSuau`, `BotoRodo`, `Xip`, `IconaClay`, `BolaClay`, `.clay(color, ple:)`, `.fonsMariapp()`)
   y los colores de `Shared/Paleta.swift`. Nada de fondos planos con `RoundedRectangle().fill(...)`: si algo es tocable o es una superficie, es plastilina (`.clay`).
   Animaciones: `Clay.molla` (sin rebote) por defecto y `Clay.mollaJuganera` solo al soltar/confirmar. Respeta `accessibilityReduceMotion`.
   Botones de solo icono con título (`Button("Títol", systemImage:)` + `.labelStyle(.iconOnly)`), mínimo 44×44 pt. (Accesibilidad avanzada no es prioridad: no hace falta trabajar VoiceOver ni Reduce Motion más allá de lo existente.) Fondo crema, mucha calma. **Prohibido rosa y rojo**, salvo `Paleta.alerta` en la sección Metges.
   Títulos con `.titolGran()` (serif); texto con diseño `.rounded`. Añade `sensoryFeedback`, animaciones `spring` y `Sons.toca(...)` donde aporte.
3. **Datos**: todo lo que se sincroniza es un `Registre` (ver `Mariapp/Data/Models.swift`) y vive en una `Coleccio<T>` de `DataStore`.
   - Campos nuevos: **opcionales o con valor por defecto en `init(from:)`** (los documentos antiguos no los tienen).
   - Contadores: usar `fusiona`/`suma` (operaciones atómicas), nunca leer-modificar-escribir.
   - Nueva colección: añadir la `Coleccio` en `DataStore` y conectarla en `connecta(_:)`.
4. **Roles**: `Preferencies.shared.rol` (`.maria` / `.david`). David (invitado) lo ve todo; las notificaciones personales solo en el dispositivo de María.
5. **Multiplataforma**: el código del target `Mariapp` compila en iOS **y** macOS. Envuelve UIKit/ActivityKit/modificadores solo-iOS con `#if os(iOS)`.
6. **Concurrencia**: Swift 5 mode. No añadas `@MainActor` a clases enteras sin necesidad.
7. **Verificación**: no se puede compilar en Linux. Haz push a la rama y revisa el workflow **"Compila Mariapp"** (GitHub Actions, macOS).
   Hasta que esté en verde, la tarea no está terminada. Para ver errores: logs del job, paso "Errors".
8. Commits pequeños, en castellano, uno por plan o sub-parte.

## Skills instaladas (`.claude/skills/`) — úsalas
- Diseño y SwiftUI: `apple-design`, `swiftui-pro` (**ojo**: los runners de GitHub solo tienen Xcode 26.6 / SDK iOS 26.5; NO uses APIs exclusivas de iOS 27 —ni con `#available`— hasta que el workflow use Xcode 27, porque no compilaría), `swiftui-animation`, `swiftui-liquid-glass`, `swift-charts`.
- Swift: `write-swift` (seguimos en modo Swift 5 por ahora), `swift-testing-pro` (plan 09).
- Sistema: `widgetkit`, `activitykit`, `app-intents`, `push-notifications`, `eventkit` (plan 03), `alarmkit` (plan 02), `tipkit`, `healthkit` (ideas).
- Firebase: `firebase-security-rules-auditor` (revisar `firebase/firestore.rules`).
Antes de tocar una de esas áreas, carga la skill correspondiente.

## Mapa

```
Shared/            → compartido app + widgets (Paleta, snapshot de "hoy", intents, Live Activity)
Mariapp/App/       → arranque, navegación, atajos de Siri
Mariapp/Design/    → componentes visuales
Mariapp/Data/      → modelos, DataStore, backends (local / Firestore), sincronización
Mariapp/Services/  → avisos, sonidos, calendario (EventKit), IA (Anthropic), preferencias
Mariapp/Features/  → una carpeta por sección
MariappWidgets/    → widget, Live Activity, controles
docs/plans/        → planes pendientes, en orden
```

## Planes

Ejecuta `docs/plans/` en orden. Al terminar uno, marca su casilla en `docs/plans/00-INDICE.md`.
