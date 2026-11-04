# Instrucciones para agentes (Claude)

App nativa SwiftUI para iOS 18+ y macOS 15+ (un único target multiplataforma) + extensión de widgets iOS.
El proyecto Xcode se genera con **XcodeGen** desde `project.yml` (no hay `.xcodeproj` en git).

## Reglas

1. **Interfaz en valenciano** (normativo AVL pero cercano y "de poble": *hui, este/esta, eixir, xicotet, vore, faena, prompte*).
   Tutea a María. Humor suave, emojis con moderación. **Documentación y commits en castellano.**
2. **Estilo**: usa siempre los componentes de `Mariapp/Design/Tema.swift` (`Targeta`, `CapcaleraTargeta`, `BotoSuau`, `BotoRodo`, `Xip`, `.fonsMariapp()`)
   y los colores de `Shared/Paleta.swift`. Fondo crema, mucha calma. **Prohibido rosa y rojo**, salvo `Paleta.alerta` en la sección Metges.
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
