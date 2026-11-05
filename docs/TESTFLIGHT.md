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

## Más adelante
El plan `docs/plans/08-testflight-automatico.md` automatiza subir builds desde GitHub Actions.
