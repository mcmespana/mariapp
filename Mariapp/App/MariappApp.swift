import SwiftUI
import UserNotifications

@main
struct MariappApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegat
    #else
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegat
    #endif

    @Environment(\.scenePhase) private var fase

    var body: some Scene {
        WindowGroup {
            Arrel()
                .environment(DataStore.shared)
                .environment(Sincronitzacio.shared)
                .environment(Preferencies.shared)
                .environment(ServeiCalendari.shared)
                .environment(Navegacio.shared)
                .environment(\.locale, Dates.locale)
                .tint(Paleta.aigua)
                .fontDesign(.rounded)
                .onOpenURL { Navegacio.shared.obri($0) }
        }
        #if os(macOS)
        .defaultSize(width: 1100, height: 760)
        #endif
        .onChange(of: fase) { _, nova in
            if nova == .active { Arrencada.enTornarAlPrimerPla() }
        }
    }
}

/// Tasques d'arrancada compartides per iOS i macOS.
enum Arrencada {
    static func enArrancar() {
        Sincronitzacio.shared.arranca()
        AccionsRapides.processador = { accions in DataStore.shared.processa(accions) }
        Avisos.registraCategories()
        Avisos.reprograma()
    }

    static func enTornarAlPrimerPla() {
        // Puja el que s'haja apuntat des del widget mentre l'app estava tancada.
        DataStore.shared.processa(CuaAccions.buida())
        ServeiCalendari.shared.recarrega()
        // Per si s'han creat o canviat cites des d'un altre dispositiu.
        ServeiCites.reprograma()
        #if os(iOS)
        if Preferencies.shared.esMaria, Preferencies.shared.activitatEnDirecte {
            let hora = Calendar.current.component(.hour, from: Date())
            if (7...22).contains(hora) {
                ActivitatHui.comenca(HuiSnapshot.carrega())
            } else {
                Task { await ActivitatHui.acaba() }
            }
        }
        #endif
    }
}

#if os(iOS)
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        Arrencada.enArrancar()
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        await MainActor.run { RespostaNotificacio.gestiona(response) }
        // Donem un moment perquè Firestore deixe l'escriptura a la cua local.
        try? await Task.sleep(nanoseconds: 600_000_000)
    }
}
#else
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self
        Arrencada.enArrancar()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        await MainActor.run { RespostaNotificacio.gestiona(response) }
    }
}
#endif

enum RespostaNotificacio {
    static func gestiona(_ response: UNNotificationResponse) {
        let text = (response as? UNTextInputNotificationResponse)?.userText
        let categoria = response.notification.request.content.categoryIdentifier
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            switch categoria {
            case Avisos.Categoria.cansament.rawValue: Navegacio.shared.obri(URL(string: "mariapp://cansament")!)
            case Avisos.Categoria.cita.rawValue: Navegacio.shared.seccio = .metges
            default: Navegacio.shared.seccio = .hui
            }
            return
        }
        _ = Avisos.gestiona(accio: response.actionIdentifier, text: text)
        Sons.toca(.gota)
    }
}
