# Configurar Firebase (sincronización + invitar a David)

Tiempo: ~5 minutos. Necesitas Node.js instalado (https://nodejs.org).

## Opción automática (recomendada)

```bash
./scripts/configura-firebase.sh
```

El script:
1. Te hace iniciar sesión con tu **cuenta de Google personal**.
2. Crea el proyecto `mariapp-xxxxxx`.
3. Registra la app (`es.mariapp.app`) y descarga `Mariapp/Resources/GoogleService-Info.plist`.
4. Crea la base de datos Firestore en Europa y sube las reglas de seguridad.
5. Te abre la consola para el **único clic manual**: *Authentication → Sign-in method → Anonymous → Enable*.

Luego: `./scripts/obre-xcode.sh` y compila. Haz commit del `GoogleService-Info.plist` (el repo es privado; no es un secreto crítico, las reglas protegen los datos).

## Opción manual

1. https://console.firebase.google.com → *Add project* → "Mariapp" (sin Analytics).
2. *Add app* → iOS → bundle id `es.mariapp.app` → descarga `GoogleService-Info.plist` → ponlo en `Mariapp/Resources/`.
3. *Build → Firestore Database* → Create (modo producción, `eur3`). Pestaña *Rules* → pega `firebase/firestore.rules` → Publish.
4. *Build → Authentication* → Get started → *Anonymous* → Enable.

## Usarlo en la app

1. En el iPhone de María: **Més → Ajustos → Crear la llar al núvol**. Se suben los datos que ya hubiera.
2. Pulsa **Convidar** y envía el enlace/código a David (y a ti misma para el Mac).
3. En el otro dispositivo: abrir el enlace `mariapp://unir?codi=…` o pegar el código en Ajustos → *Unir-me amb el codi*.

## Coste
Plan gratuito (Spark): 50.000 lecturas y 20.000 escrituras al día. Mariapp usará unas pocas decenas.
