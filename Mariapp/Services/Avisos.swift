import Foundation
import UserNotifications
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Notificacions locals. Només es programen les "rutines" al dispositiu de la Maria.
enum Avisos {
    enum Categoria: String {
        case cansament = "CANSAMENT"
        case aigua = "AIGUA"
        case gimnas = "GIMNAS"
        case cita = "CITA"
        case resum = "RESUM"
    }

    enum Accio: String {
        case cansamentPoc = "cansament.2"
        case cansamentMig = "cansament.5"
        case cansamentMolt = "cansament.8"
        case cansamentEscriu = "cansament.escriu"
        case aiguaMitja = "aigua.mitja"
        case aiguaBotella = "aigua.botella"
        case cafe = "cafe"
        case gimnasSi = "gimnas.si"
        case gimnasNo = "gimnas.no"
    }

    private static var centre: UNUserNotificationCenter { .current() }

    static func registraCategories() {
        let cansament = UNNotificationCategory(
            identifier: Categoria.cansament.rawValue,
            actions: [
                UNNotificationAction(identifier: Accio.cansamentPoc.rawValue, title: "⚡️ Poquet", options: []),
                UNNotificationAction(identifier: Accio.cansamentMig.rawValue, title: "🙂 Normalet", options: []),
                UNNotificationAction(identifier: Accio.cansamentMolt.rawValue, title: "😴 Feta pols", options: []),
                UNTextInputNotificationAction(identifier: Accio.cansamentEscriu.rawValue, title: "✍️ Escriu el número", options: [],
                                              textInputButtonTitle: "Apuntar", textInputPlaceholder: "Del 0 al 1000"),
            ],
            intentIdentifiers: []
        )
        let aigua = UNNotificationCategory(
            identifier: Categoria.aigua.rawValue,
            actions: [
                UNNotificationAction(identifier: Accio.aiguaMitja.rawValue, title: "💧 Mitja botella", options: []),
                UNNotificationAction(identifier: Accio.aiguaBotella.rawValue, title: "💧💧 Una botella sencera", options: []),
                UNNotificationAction(identifier: Accio.cafe.rawValue, title: "☕️ Un café", options: []),
            ],
            intentIdentifiers: []
        )
        let gimnas = UNNotificationCategory(
            identifier: Categoria.gimnas.rawValue,
            actions: [
                UNNotificationAction(identifier: Accio.gimnasSi.rawValue, title: "💪 Sí, he anat!", options: []),
                UNNotificationAction(identifier: Accio.gimnasNo.rawValue, title: "🛋️ Hui no", options: []),
            ],
            intentIdentifiers: []
        )
        let cita = UNNotificationCategory(identifier: Categoria.cita.rawValue, actions: [], intentIdentifiers: [])
        let resum = UNNotificationCategory(identifier: Categoria.resum.rawValue, actions: [], intentIdentifiers: [])
        centre.setNotificationCategories([cansament, aigua, gimnas, cita, resum])
    }

    static func demanaPermis() async -> Bool {
        (try? await centre.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    static func estatPermis() async -> UNAuthorizationStatus {
        await centre.notificationSettings().authorizationStatus
    }

    /// Obri els ajustos de notificacions del sistema (iPhone: els de l'app; Mac: Notificacions).
    @MainActor
    static func obriAjustosNotificacions() {
        #if canImport(UIKit)
        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
        #elseif canImport(AppKit)
        if let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension") { NSWorkspace.shared.open(url) }
        #endif
    }

    // MARK: Rutines diàries

    /// Esborra i torna a programar els avisos diaris segons les preferències.
    static func reprograma() {
        let prefs = Preferencies.shared
        programaResum()
        centre.getPendingNotificationRequests { pendents in
            let ids = pendents.map(\.identifier).filter { $0.hasPrefix("rutina.") }
            centre.removePendingNotificationRequests(withIdentifiers: ids)

            guard prefs.esMaria, prefs.avisosActius else { return }

            programaDiari(
                id: "rutina.cansament",
                hora: prefs.horaCansament,
                titol: "Com estàs de cansada? 🫖",
                cos: "El cansòmetre et espera: del 0 al 1000. Sense pensar-ho massa.",
                categoria: .cansament,
                so: .campaneta
            )
            let frases = [
                "Un glopet d'aigua? 💧",
                "Hora de beure! La botella t'espera 🫗",
                "Les plantes beuen. Tu també 🌿",
                "Aigua, aigüeta… 💦",
            ]
            for (i, hora) in prefs.horesAigua.sorted().enumerated() {
                programaDiari(
                    id: "rutina.aigua.\(hora.text)",
                    hora: hora,
                    titol: frases[i % frases.count],
                    cos: "Apunta el que has begut des d'ací mateix.",
                    categoria: .aigua,
                    so: .gota
                )
            }
            if prefs.avisGimnas {
                programaDiari(
                    id: "rutina.gimnas",
                    hora: prefs.horaGimnas,
                    titol: "Has anat al gimnàs hui? 🏋️‍♀️",
                    cos: "Per a les estadístiques del mes (sense pressió).",
                    categoria: .gimnas,
                    so: .campaneta
                )
            }
        }
    }

    // MARK: Resum setmanal

    /// Notificació ÚNICA (no repetitiva) per al pròxim diumenge a l'hora triada, amb les dades d'ara.
    /// Es recalcula quan canvien les dades, en tornar a primer pla i en canviar les preferències.
    static func programaResum() {
        let nova = peticioResum()
        // Esborrar i afegir dins del mateix callback (veure `programa(cita:)`).
        centre.getPendingNotificationRequests { pendents in
            if pendents.contains(where: { $0.identifier == ResumSetmanal.idNotificacio }) {
                centre.removePendingNotificationRequests(withIdentifiers: [ResumSetmanal.idNotificacio])
            }
            if let nova { centre.add(nova) }
        }
    }

    private static func peticioResum() -> UNNotificationRequest? {
        let prefs = Preferencies.shared
        let store = DataStore.shared
        guard prefs.esMaria, prefs.avisosActius, prefs.resumSetmanal,
              let quan = ResumSetmanal.dataNotificacio(hora: prefs.horaResum) else { return nil }
        // El diumenge que ve és el final de la setmana que conté aquesta data.
        let resum = ResumSetmanal.calcula(dies: store.dies.items, setmana: Setmana.inici(de: quan), objectiuMl: store.config.objectiuMl)
        let c = UNMutableNotificationContent()
        c.title = ResumSetmanal.titolNotificacio(resum)
        c.body = ResumSetmanal.cosNotificacio(resum)
        c.categoryIdentifier = Categoria.resum.rawValue
        c.sound = UNNotificationSound(named: UNNotificationSoundName(So.campaneta.fitxer))
        return peticio(id: ResumSetmanal.idNotificacio, contingut: c, quan: quan)
    }

    private static func programaDiari(id: String, hora: Hora, titol: String, cos: String, categoria: Categoria, so: So) {
        let contingut = UNMutableNotificationContent()
        contingut.title = titol
        contingut.body = cos
        contingut.categoryIdentifier = categoria.rawValue
        contingut.sound = UNNotificationSound(named: UNNotificationSoundName(so.fitxer))
        var c = DateComponents()
        c.hour = hora.hora
        c.minute = hora.minut
        let trigger = UNCalendarNotificationTrigger(dateMatching: c, repeats: true)
        centre.add(UNNotificationRequest(identifier: id, content: contingut, trigger: trigger))
    }

    // MARK: Metges

    /// Programa tots els avisos d'una cita (o el recordatori per a demanar-la). Esborra els anteriors.
    static func programa(cita: Cita, categoria: CategoriaMetge?) {
        let nova = esMaria() ? peticions(cita: cita, categoria: categoria) : []
        // Esborrar i afegir dins del mateix callback: si no, l'esborrat podria menjar-se els avisos nous.
        centre.getPendingNotificationRequests { pendents in
            let ids = pendents.map(\.identifier).filter { $0.hasPrefix("cita.\(cita.id).") }
            centre.removePendingNotificationRequests(withIdentifiers: ids)
            nova.forEach { centre.add($0) }
        }
    }

    private static func esMaria() -> Bool { Preferencies.shared.esMaria }

    private static func peticions(cita: Cita, categoria: CategoriaMetge?) -> [UNNotificationRequest] {
        let nomCategoria = categoria.map { "\($0.emoji) \($0.nom)" } ?? "🏥 Metge"
        var resultat: [UNNotificationRequest] = []

        switch cita.estat {
        case .programada:
            guard let data = cita.data else { return [] }
            for minuts in cita.avisos {
                let quan = data.addingTimeInterval(TimeInterval(-minuts * 60))
                guard quan > Date() else { continue }
                let c = UNMutableNotificationContent()
                c.title = "🚨 \(cita.titol) \(textAntelacio(minuts)) 🚨"
                c.body = "\(nomCategoria)\(cita.lloc.isEmpty ? "" : " · \(cita.lloc)"). NO SE T'OBLIDE!!"
                c.categoryIdentifier = Categoria.cita.rawValue
                c.sound = UNNotificationSound(named: UNNotificationSoundName(So.sirena.fitxer))
                c.interruptionLevel = .timeSensitive
                resultat.append(peticio(id: "cita.\(cita.id).\(minuts)", contingut: c, quan: quan))
            }
        case .perDemanar:
            guard let quan = cita.recordarDemanarEl, quan > Date() else { return [] }
            let c = UNMutableNotificationContent()
            c.title = "📞 Toca demanar cita!"
            c.body = "\(nomCategoria): \(cita.titol). Agafa el telèfon ARA, que després no ho fas 😅"
            c.categoryIdentifier = Categoria.cita.rawValue
            c.sound = UNNotificationSound(named: UNNotificationSoundName(So.sirena.fitxer))
            c.interruptionLevel = .timeSensitive
            resultat.append(peticio(id: "cita.\(cita.id).demanar", contingut: c, quan: quan))
        case .feta:
            break
        }
        return resultat
    }

    static func cancela(citaId: String) {
        centre.getPendingNotificationRequests { pendents in
            let ids = pendents.map(\.identifier).filter { $0.hasPrefix("cita.\(citaId).") }
            centre.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    private static func peticio(id: String, contingut: UNNotificationContent, quan: Date) -> UNNotificationRequest {
        let c = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: quan)
        let trigger = UNCalendarNotificationTrigger(dateMatching: c, repeats: false)
        return UNNotificationRequest(identifier: id, content: contingut, trigger: trigger)
    }

    // MARK: Anotacions del calendari

    /// Avisos extra d'un esdeveniment del calendari (`anot.<id>.<minuts>`). Només al dispositiu de la Maria.
    static func programa(anotacio: AnotacioEsdeveniment, titol: String, inici: Date) {
        var nova: [UNNotificationRequest] = []
        if esMaria() {
            let emoji = anotacio.emoji.map { "\($0) " } ?? ""
            for minuts in anotacio.avisos {
                let quan = inici.addingTimeInterval(TimeInterval(-minuts * 60))
                guard quan > Date() else { continue }
                let c = UNMutableNotificationContent()
                c.title = "\(emoji)\(titol) \(textAntelacio(minuts))"
                if let nota = anotacio.nota, !nota.isEmpty { c.body = nota }
                c.sound = UNNotificationSound(named: UNNotificationSoundName(So.campaneta.fitxer))
                nova.append(peticio(id: "anot.\(anotacio.id).\(minuts)", contingut: c, quan: quan))
            }
        }
        centre.getPendingNotificationRequests { pendents in
            let ids = pendents.map(\.identifier).filter { $0.hasPrefix("anot.\(anotacio.id).") }
            centre.removePendingNotificationRequests(withIdentifiers: ids)
            nova.forEach { centre.add($0) }
        }
    }

    static func cancela(anotacioId: String) {
        centre.getPendingNotificationRequests { pendents in
            let ids = pendents.map(\.identifier).filter { $0.hasPrefix("anot.\(anotacioId).") }
            centre.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    static func textAntelacio(_ minuts: Int) -> String {
        switch minuts {
        case 0: return "ARA MATEIX"
        case ..<60: return "en \(minuts) minuts"
        case 60: return "en 1 hora"
        case ..<1440: return "en \(minuts / 60) hores"
        case 1440: return "DEMÀ"
        case ..<10080: return "en \(minuts / 1440) dies"
        case 10080: return "en 1 setmana"
        default: return "en \(minuts / 10080) setmanes"
        }
    }

    // MARK: Respostes

    /// Gestiona el botó que s'ha tocat en una notificació. Retorna un enllaç a obrir, si cal.
    static func gestiona(accio: String, text: String?) -> URL? {
        let store = DataStore.shared
        let ampolla = store.config.ampollaMl
        switch Accio(rawValue: accio) {
        case .cansamentPoc: store.posa(.cansament, store.config.escalaCansament * 2 / 10)
        case .cansamentMig: store.posa(.cansament, store.config.escalaCansament * 5 / 10)
        case .cansamentMolt: store.posa(.cansament, store.config.escalaCansament * 8 / 10)
        case .cansamentEscriu:
            if let text, let n = Int(text.trimmingCharacters(in: .whitespaces)) {
                store.posa(.cansament, max(0, min(store.config.escalaCansament, n)))
            }
        case .aiguaMitja: store.suma(.aiguaMl, ampolla / 2)
        case .aiguaBotella: store.suma(.aiguaMl, ampolla)
        case .cafe: store.suma(.cafes, 1)
        case .gimnasSi: store.posa(.gimnas, true)
        case .gimnasNo: store.posa(.gimnas, false)
        case nil:
            break
        }
        return nil
    }
}
