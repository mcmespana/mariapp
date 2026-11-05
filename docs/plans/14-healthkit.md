# 14 — Apple Salut (HealthKit) ❤️

**Objetivo**: que el gimnasio se marque solo con los entrenamientos del Apple Watch, que el agua llegue a Salud, y leer el sueño para cruzarlo con el cansancio.

Carga la skill `healthkit` antes de empezar. Todo en `#if os(iOS)` (HealthKit no está disponible en el Mac).

## Ya existe
- `Dia.gimnas`, `Dia.aiguaMl`, `DataStore.posa/suma`, `Preferencies` (rol: solo el dispositivo de María toca Salud).
- `Arrencada.enTornarAlPrimerPla`.

## Configuración
- `project.yml` (target `Mariapp`): `NSHealthShareUsageDescription` ("Mariapp llig els teus entrenaments i el son per a apuntar el gimnàs sola i veure com descanses."), `NSHealthUpdateUsageDescription` ("Mariapp apunta a Salut l'aigua que beus.").
- Entitlement `com.apple.developer.healthkit` (+ `com.apple.developer.healthkit.access: []`) en `Config/Mariapp-iOS.entitlements` (NO en el de macOS). CI compila sin firmar, así que no rompe.

## A construir
1. **Servicio** `Mariapp/Services/ServeiSalut.swift` (`@Observable`, `shared`):
   - `disponible` (`HKHealthStore.isHealthDataAvailable()`), `demanaPermis()` (lectura: `workoutType`, `sleepAnalysis`; escritura: `dietaryWater`).
   - **Gimnasio**: `entrenamentsDe(dia:) async -> [HKWorkout]` (duración ≥ 15 min). `sincronitzaGimnas()` para hoy y los 7 días anteriores: si hay entrenamiento y `Dia.gimnas == false` → `store.posa(.gimnas, true, dia:)`. Nunca pone `false` (si María dice que no, manda ella).
   - Guardar en `Dia` un campo nuevo opcional `entrenament: String?` ("🏋️ Força tradicional · 45 min") para mostrarlo en la `TargetaGimnas` ("Apuntat sol des de l'Apple Watch ⌚️").
   - **Agua → Salud**: `sincronitzaAigua(dia:)`: borrar las muestras `dietaryWater` **de esta app** de ese día (`HKQuery.predicateForObjects(from: .default())`) y escribir **una** con el total del día. Idempotente: soporta deshacer y cambios desde otros dispositivos. Llamarla con *debounce* (~3 s) cuando cambia `aiguaMl` de hoy en `DataStore` y al volver a primer plano (hoy y ayer).
   - **Sueño**: `sonDe(nit:) async -> Int?` (minutos dormidos de la noche que acaba en ese día: muestras `asleepCore/Deep/REM/Unspecified` entre las 18:00 del día anterior y las 12:00). Guardar en `Dia` campo nuevo opcional `sonMinuts: Int?` (solo si no está ya, para no reescribir cada vez).
   - Observación en segundo plano (opcional): `HKObserverQuery` + `enableBackgroundDelivery(for: workoutType, frequency: .hourly)` para marcar el gimnasio aunque no se abra la app.
2. **Ajustos** (solo María, solo iOS): sección "Apple Salut ❤️" con toggles `salutGimnas`, `salutAigua`, `salutSon` en `Preferencies` (por defecto apagados hasta dar permiso), botón "Connectar amb Salut" que pide permisos y explica qué se lee/escribe.
3. **Hui**: en `TargetaGimnas`, si `dia.entrenament != nil`, mostrar la línea del entrenamiento con `IconaClay("applewatch")`. En `TargetaCansament`, si hay `sonMinuts`, chip "😴 7 h 20 min".
4. **Estadísticas**: tarjeta "Son" (horas medias por mes) y añadir `sonVsCansament` al plan 11 (si ya está hecho, añadirlo ahora en `Analisi` + tarjeta + `resumPerIA`).
5. **Tests**: `Dia` antiguo sin `entrenament`/`sonMinuts`; función pura que suma minutos de sueño a partir de intervalos (sin HealthKit: pasar `[(inici, fi, tipus)]`), con solapamientos.

## Aceptación
- Con un entrenamiento hoy en Salud (se puede crear a mano en la app Salud) → al abrir Mariapp, gimnasio marcado con el texto del entrenamiento.
- Apuntar 1,5 L → en Salud aparece 1,5 L de agua de Mariapp; deshacer ½ → Salud muestra el nuevo total (sin duplicados).
- El sueño de anoche aparece en Hui. En el dispositivo de David y en el Mac no se toca Salud. Compila iOS + macOS.
