# Instalar Mariapp en los iPhones y Macs

## Opción 1 — Directo desde Xcode (para empezar ya)
Conecta el iPhone por cable, elígelo en Xcode y ▶︎. Con cuenta de desarrollador de pago la app dura 1 año.
La primera vez: en el iPhone, *Ajustes → General → VPN y gestión de dispositivos* → confiar en el desarrollador, y activar el *Modo desarrollador* si lo pide.

## Opción 2 — TestFlight (recomendada para David y para actualizar sin cables)
1. https://appstoreconnect.apple.com → *Apps* → **+** → Nueva app
   - Plataformas: iOS y macOS · Nombre: Mariapp (si está cogido: "Mariapp Casa") · Idioma principal: Catalán · Bundle ID: `es.mariapp.app` · SKU: `mariapp`.
2. En Xcode: menú *Product → Archive* (con destino "Any iOS Device").
3. En el Organizer: **Distribute App → TestFlight & App Store → Distribute**.
4. En App Store Connect → *TestFlight*: espera a que se procese (10–30 min), responde lo del cifrado (ya está como "no usa cifrado propio").
5. *Internal Testing* → crea grupo "Casa" → añade a María y David (tienen que estar como usuarios de App Store Connect con rol *Developer* o *Marketing*; se invita en *Users and Access*).
6. Ellos instalan la app **TestFlight** y aceptan la invitación. Las builds internas no necesitan revisión de Apple.

Para Mac: repite *Archive* con destino "Any Mac" y distribúyelo igual; se instala desde TestFlight para Mac.

## Opción 3 — Automático desde GitHub Actions (`.github/workflows/testflight.yml`)
Cada build se sube sola a TestFlight, sin abrir Xcode. Solo hay que hacer **una vez** esta preparación (la hace una persona, no el agente):

1. En App Store Connect crea la app (paso 1 de la opción 2) y, en *Users and Access → Integrations → App Store Connect API*, crea una **Team Key** con rol **App Manager**. Descarga el `.p8` (solo se puede una vez) y apunta el *Key ID* y el *Issuer ID*.
2. En GitHub: *Settings → Secrets and variables → Actions → New repository secret*:

   | Secret | Valor |
   |---|---|
   | `ASC_KEY_ID` | Key ID de la clave |
   | `ASC_ISSUER_ID` | Issuer ID (arriba de la tabla de claves) |
   | `ASC_KEY_P8` | Contenido completo del `.p8` (con las líneas `-----BEGIN…`) |
   | `TEAM_ID` | Team ID de Apple (developer.apple.com → Membership) |

3. Lanza el flujo:
   - **A mano**: *Actions → TestFlight → Run workflow* (elige iOS, macOS o ambas).
   - **Con etiqueta**: `git tag v0.2.0 && git push origin v0.2.0` (la versión de marketing sale de la etiqueta).

Qué hace: `xcodegen` → `xcodebuild archive` con firma automática (`-allowProvisioningUpdates` + clave de API) → `xcodebuild -exportArchive` con `method = app-store-connect` y `destination = upload`. El número de build es el `run_number` de GitHub (`CURRENT_PROJECT_VERSION`), así que siempre sube.
Si falta algún secret, el flujo falla enseguida con un mensaje claro.

Notas:
- Los runners de macOS gastan minutos ×10 en repos privados; cada subida ronda 10–15 min por plataforma.
- La primera vez Apple puede tardar en crear los perfiles de aprovisionamiento (App Group `group.es.mariapp.app` incluido); si falla, abre el proyecto una vez en Xcode con tu cuenta para que se registren los identificadores.
- Alternativa sin secretos en GitHub: **Xcode Cloud** (Xcode → Product → Xcode Cloud; 25 h/mes gratis).
