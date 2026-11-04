import Foundation
import UserNotifications

/// Notificacions locals. Només es programen les "rutines" al dispositiu de la Maria.
enum Avisos {
    enum Categoria: String {
        case cansament = "CANSAMENT"
        case aigua = "AIGUA"
        case gimnas = "GIMNAS"
        case cita = "CITA"
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
                UNNotificationAction(identifier: Accio.cansamentPoc.rawValue, title: "⚡️ Poc (2)"),
                UNNotificationAction(identifier: Accio.cansamentMig.rawValue, title: "🙂 Normalet (5)"),
                UNNotificationAction(identifier: Accio.cansamentMolt.rawValue, title: "😴 Molt (8)"),
                UNTextInputNotificationAction(identifier: Accio.cansamentEscriu.rawValue, title: "✍️ Escriu el número",
                                              textInputButtonTitle: "Apuntar", textInputPlaceholder: "0 – 10"),
            ],
            intentIdentifiers: []
        )
        let aigua = UNNotificationCategory(
            identifier: Categoria.aigua.rawValue,
            actions: [
                UNNotificationAction(identifier: Accio.aiguaMitja.rawValue, title: "💧 Mitja botella"),
                UNNotificationAction(identifier: Accio.aiguaBotella.rawValue, title: "💧💧 Una botella sencera"),
                UNNotificationAction(identifier: Accio.cafe.rawValue, title: "☕️ Un café"),
            ],
            intentIdentifiers: []
        )
        let gimnas = UNNotificationCategory(
            identifier: Categoria.gimnas.rawValue,
            actions: [
                UNNotificationAction(identifier: Accio.gimnasSi.rawValue, title: "💪 Sí, he anat!"),
                UNNotificationAction(identifier: Accio.gimnasNo.rawValue, title: "🛋️ Hui no"),
            ],
            intentIdentifiers: []
        )
        let cita = UNNotificationCategory(identifier: Categoria.cita.rawValue, actions: [], intentIdentifiers: [])
        centre.setNotificationCategories([cansament, aigua, gimnas, cita])
    }

    static func demanaPermis() async -> Bool {
        (try? await centre.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    // MARK: Rutines diàries

    /// Esborra i torna a programar els avisos diaris segons les preferències.
    static func reprograma() {
        let prefs = Preferencies.shared
        centre.getPendingNotificationRequests { pendents in
            let ids = pendents.map(\.identifier).filter { $0.hasPrefix("rutina.") }
            centre.removePendingNotificationRequests(withIdentifiers: ids)

            guard prefs.esMaria, prefs.avisosActius else { return }

            programaDiari(
                id: "rutina.cansament",
                hora: prefs.horaCansament,
                titol: "Com estàs de cansada? 🫖",
                cos: "Puntua'l del 0 al 10. Sense pensar-ho massa.",
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
        cancela(citaId: cita.id)
        guard Preferencies.shared.esMaria else { return }
        let nomCategoria = categoria.map { "\($0.emoji) \($0.nom)" } ?? "🏥 Metge"

        switch cita.estat {
        case .programada:
            guard let data = cita.data else { return }
            for minuts in cita.avisos {
                let quan = data.addingTimeInterval(TimeInterval(-minuts * 60))
                guard quan > Date() else { continue }
                let c = UNMutableNotificationContent()
                c.title = "🚨 \(cita.titol) \(textAntelacio(minuts)) 🚨"
                c.body = "\(nomCategoria)\(cita.lloc.isEmpty ? "" : " · \(cita.lloc)"). NO SE T'OBLIDE!!"
                c.categoryIdentifier = Categoria.cita.rawValue
                c.sound = UNNotificationSound(named: UNNotificationSoundName(So.sirena.fitxer))
                c.interruptionLevel = .timeSensitive
                afegeix(id: "cita.\(cita.id).\(minuts)", contingut: c, quan: quan)
            }
        case .perDemanar:
            guard let quan = cita.recordarDemanarEl, quan > Date() else { return }
            let c = UNMutableNotificationContent()
            c.title = "📞 Toca demanar cita!"
            c.body = "\(nomCategoria): \(cita.titol). Agafa el telèfon ARA, que després no ho fas 😅"
            c.categoryIdentifier = Categoria.cita.rawValue
            c.sound = UNNotificationSound(named: UNNotificationSoundName(So.sirena.fitxer))
            c.interruptionLevel = .timeSensitive
            afegeix(id: "cita.\(cita.id).demanar", contingut: c, quan: quan)
        case .feta:
            break
        }
    }

    static func cancela(citaId: String) {
        centre.getPendingNotificationRequests { pendents in
            let ids = pendents.map(\.identifier).filter { $0.hasPrefix("cita.\(citaId).") }
            centre.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    private static func afegeix(id: String, contingut: UNNotificationContent, quan: Date) {
        let c = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: quan)
        let trigger = UNCalendarNotificationTrigger(dateMatching: c, repeats: false)
        centre.add(UNNotificationRequest(identifier: id, content: contingut, trigger: trigger))
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
        case .cansamentPoc: store.posa(.cansament, 2)
        case .cansamentMig: store.posa(.cansament, 5)
        case .cansamentMolt: store.posa(.cansament, 8)
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
