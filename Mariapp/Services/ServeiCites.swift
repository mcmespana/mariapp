import Foundation

/// Tot el que passa en desar, marcar com a feta o esborrar una cita:
/// dades, avisos (notificacions), alarma de despertador i esdeveniment del calendari.
enum ServeiCites {
    private static var store: DataStore { DataStore.shared }

    static func categoria(_ cita: Cita) -> CategoriaMetge? {
        store.categoriesMetge[cita.categoriaId]
    }

    /// Desa la cita i ho deixa tot sincronitzat.
    static func desa(_ original: Cita, alCalendari: Bool) async {
        var cita = original
        let cat = categoria(cita)

        // Calendari
        let calendari = ServeiCalendari.shared
        if cita.estat == .programada, alCalendari {
            if !calendari.autoritzat { await calendari.demanaAcces() }
            if let id = try? calendari.sincronitza(cita: cita, categoria: cat) {
                cita.esdevenimentId = id
            }
        } else if cita.estat != .programada || !alCalendari {
            calendari.esborra(esdevenimentId: cita.esdevenimentId)
            cita.esdevenimentId = nil
        }

        // Alarma de despertador
        ServeiAlarmes.cancela(alarmaId: cita.alarmaId)
        cita.alarmaId = nil
        if cita.estat == .programada, cita.alarmaMinuts != nil {
            cita.alarmaId = await ServeiAlarmes.programa(cita: cita)
        }

        store.cites.desa(cita)
        Avisos.programa(cita: cita, categoria: cat)
    }

    static func marcaFeta(_ cita: Cita) {
        var c = cita
        c.estat = .feta
        c.alarmaId = nil
        ServeiAlarmes.cancela(alarmaId: cita.alarmaId)
        Avisos.cancela(citaId: cita.id)
        store.cites.desa(c)
    }

    static func esborra(_ cita: Cita) {
        Avisos.cancela(citaId: cita.id)
        ServeiAlarmes.cancela(alarmaId: cita.alarmaId)
        ServeiCalendari.shared.esborra(esdevenimentId: cita.esdevenimentId)
        store.cites.esborra(cita)
    }

    /// Torna a programar avisos i alarmes de totes les cites futures
    /// (per si s'han creat o canviat des d'un altre dispositiu).
    static func reprograma() {
        guard Preferencies.shared.esMaria else { return }
        let ara = Date()
        for cita in store.cites.items {
            let cat = categoria(cita)
            switch cita.estat {
            case .programada:
                guard let data = cita.data, data > ara else { continue }
                Avisos.programa(cita: cita, categoria: cat)
                if cita.alarmaMinuts != nil, !ServeiAlarmes.esVigent(cita: cita) {
                    Task {
                        ServeiAlarmes.cancela(alarmaId: cita.alarmaId)
                        var c = cita
                        c.alarmaId = await ServeiAlarmes.programa(cita: cita)
                        if c.alarmaId != cita.alarmaId { store.cites.desa(c) }
                    }
                }
            case .perDemanar:
                Avisos.programa(cita: cita, categoria: cat)
            case .feta:
                break
            }
        }
    }

    // MARK: Consultes (per a Metges i Hui)

    static func properaCita(_ cites: [Cita], ara: Date = Date()) -> Cita? {
        cites.filter { $0.estat == .programada && ($0.data ?? .distantPast) > ara }
            .min { ($0.data ?? .distantFuture) < ($1.data ?? .distantFuture) }
    }

    /// Cites per demanar amb el recordatori ja vençut.
    static func perDemanarVencudes(_ cites: [Cita], ara: Date = Date()) -> [Cita] {
        cites.filter { $0.estat == .perDemanar && ($0.recordarDemanarEl.map { $0 <= ara } ?? false) }
    }

    /// La cita que cal destacar a Hui: una dins dels pròxims 7 dies.
    static func citaProxima7Dies(_ cites: [Cita], ara: Date = Date()) -> Cita? {
        guard let c = properaCita(cites, ara: ara), let d = c.data,
              d.timeIntervalSince(ara) <= 7 * 86400 else { return nil }
        return c
    }
}

/// Textos de compte enrere: "en 3 dies, 4 hores".
enum Compte {
    static func text(fins data: Date, ara: Date = Date()) -> String {
        let s = Int(data.timeIntervalSince(ara))
        guard s > 0 else { return "ja ha passat" }
        let d = s / 86400
        let h = (s % 86400) / 3600
        let m = (s % 3600) / 60
        func u(_ n: Int, _ singular: String, _ plural: String) -> String { "\(n) \(n == 1 ? singular : plural)" }
        if d > 0 { return "en \(u(d, "dia", "dies")), \(u(h, "hora", "hores"))" }
        if h > 0 { return "en \(u(h, "hora", "hores")), \(m) min" }
        return "en \(max(m, 1)) min"
    }

    /// Minuts d'antelació per a "la vesprada abans" (19:00 del dia anterior).
    static func minutsVesprada(_ data: Date) -> Int? {
        let cal = Calendar.current
        guard let diaAbans = cal.date(byAdding: .day, value: -1, to: data),
              let vesprada = cal.date(bySettingHour: 19, minute: 0, second: 0, of: diaAbans) else { return nil }
        let m = Int(data.timeIntervalSince(vesprada) / 60)
        return m > 0 ? m : nil
    }
}
