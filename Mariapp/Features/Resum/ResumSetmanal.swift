import Foundation

/// Un dia amb un valor (el millor dia d'aigua, el dia més cansat…).
struct DiaAmbValor: Equatable {
    var dia: Date
    var valor: Int

    /// "dijous"
    var nomDia: String { Analisi.nomsDiesLlargs[Setmana.numeroDia(dia) - 1] }
}

/// Les dades d'un dia dins d'una setmana (sempre n'hi ha 7, encara que no s'haja apuntat res).
struct DiaSetmana: Identifiable, Equatable {
    var numero: Int          // 1 = dilluns … 7 = diumenge
    var data: Date
    var aiguaMl = 0
    var cafes = 0
    var queixes = 0
    var gimnas = false
    var cansament: Int?
    var dolor: Int?

    var id: Int { numero }
    var nom: String { Analisi.nomsDies[numero - 1] }
    /// Inicial per a les boletes del gimnàs: L M X J V S D.
    var inicial: String { ["L", "M", "X", "J", "V", "S", "D"][numero - 1] }
    var apuntat: Bool { aiguaMl > 0 || cafes > 0 || queixes > 0 || gimnas || cansament != nil || dolor != nil }
}

/// Com ha anat una setmana (dilluns–diumenge). Càlcul pur, fàcil de provar.
struct ResumSetmana: Equatable {
    var inici: Date
    var dies: [DiaSetmana] = []
    var aiguaTotalMl = 0
    var diesAmbAigua = 0
    var millorDiaAigua: DiaAmbValor?
    var diesObjectiuAigua = 0
    var diesGimnas = 0
    var cansamentMitja: Double?
    var diaMesCansat: DiaAmbValor?
    var diaMenysCansat: DiaAmbValor?
    var cafes = 0
    var queixes = 0
    var diesMolesties = 0
    var diesApuntats = 0

    var teDades: Bool { diesApuntats > 0 }

    /// Mitjana d'aigua dels dies en què s'ha apuntat aigua.
    var aiguaMitjanaDia: Double? {
        diesAmbAigua > 0 ? Double(aiguaTotalMl) / Double(diesAmbAigua) : nil
    }
}

enum ResumSetmanal {
    static let idNotificacio = "resum.setmana"

    // MARK: Càlcul

    static func calcula(dies: [Dia], setmana inici: Date, objectiuMl: Int) -> ResumSetmana {
        let perId = Dictionary(dies.map { ($0.id, $0) }, uniquingKeysWith: { primer, _ in primer })
        var r = ResumSetmana(inici: inici)
        var sumaCansament = 0
        var diesCansament = 0

        for n in 1...7 {
            let data = Setmana.dia(inici, n)
            var dia = DiaSetmana(numero: n, data: data)
            if let d = perId[ClauDia.de(data)] {
                dia.aiguaMl = d.aiguaMl
                dia.cafes = d.cafes
                dia.queixes = d.queixes
                dia.gimnas = d.gimnas
                dia.cansament = d.cansament
                dia.dolor = d.dolor
            }
            r.dies.append(dia)

            if dia.apuntat { r.diesApuntats += 1 }
            if dia.aiguaMl > 0 {
                r.aiguaTotalMl += dia.aiguaMl
                r.diesAmbAigua += 1
                if objectiuMl > 0, dia.aiguaMl >= objectiuMl { r.diesObjectiuAigua += 1 }
            }
            if dia.gimnas { r.diesGimnas += 1 }
            if let c = dia.cansament {
                sumaCansament += c
                diesCansament += 1
            }
            r.cafes += dia.cafes
            r.queixes += dia.queixes
            if (dia.dolor ?? 0) > 0 { r.diesMolesties += 1 }
        }

        if let millor = r.dies.filter({ $0.aiguaMl > 0 }).max(by: { $0.aiguaMl < $1.aiguaMl }) {
            r.millorDiaAigua = DiaAmbValor(dia: millor.data, valor: millor.aiguaMl)
        }
        if diesCansament > 0 {
            r.cansamentMitja = Double(sumaCansament) / Double(diesCansament)
        }
        // Amb un sol dia apuntat no té sentit parlar del més i el menys cansat.
        if diesCansament >= 2 {
            let amb = r.dies.compactMap { d in d.cansament.map { (d.data, $0) } }
            if let pitjor = amb.max(by: { $0.1 < $1.1 }) { r.diaMesCansat = DiaAmbValor(dia: pitjor.0, valor: pitjor.1) }
            if let millor = amb.min(by: { $0.1 < $1.1 }) { r.diaMenysCansat = DiaAmbValor(dia: millor.0, valor: millor.1) }
        }
        return r
    }

    /// La setmana que s'ensenya per defecte: l'última completa (o l'actual si és diumenge).
    static func setmanaPerDefecte(ara: Date = Date()) -> Date {
        let actual = Setmana.inici(de: ara)
        return Setmana.numeroDia(ara) == 7 ? actual : Setmana.mou(actual, setmanes: -1)
    }

    // MARK: Comparativa

    /// Frases curtes comparant amb la setmana anterior. Buit si no hi ha dades suficients per a comparar.
    static func comparativa(actual: ResumSetmana, anterior: ResumSetmana, escala: Int = 1000, ara: Date = Date()) -> [String] {
        guard actual.diesApuntats >= 3, anterior.diesApuntats >= 3 else { return [] }
        var frases: [String] = []

        // La setmana "està completa" des del diumenge a la vesprada; abans, no comparem recomptes de dies.
        let completa = Setmana.dia(actual.inici, 7).addingTimeInterval(18 * 3600) <= ara

        if let a = actual.aiguaMitjanaDia, let b = anterior.aiguaMitjanaDia,
           actual.diesAmbAigua >= 3, anterior.diesAmbAigua >= 3 {
            let diff = Int((a - b).rounded())
            if diff >= 150 {
                frases.append("💧 +\(FormatAigua.text(diff)) més al dia que la setmana passada")
            } else if diff <= -150 {
                frases.append("💧 −\(FormatAigua.text(-diff)) menys al dia que la setmana passada")
            }
        }

        if completa {
            let gimnas = actual.diesGimnas - anterior.diesGimnas
            if gimnas > 0 {
                frases.append("🏋️‍♀️ \(dies(gimnas)) més de gimnàs")
            } else if gimnas < 0 {
                frases.append("🏋️‍♀️ \(dies(-gimnas)) menys de gimnàs")
            }
        }

        if let a = actual.cansamentMitja, let b = anterior.cansamentMitja {
            let llindar = Double(escala) * 0.1
            if a < b - llindar {
                frases.append("😌 Menys cansada que la setmana passada")
            } else if a > b + llindar {
                frases.append("😮‍💨 Una mica més cansada que la setmana passada")
            }
        }

        if completa {
            let cafes = actual.cafes - anterior.cafes
            if cafes >= 2 {
                frases.append("☕️ \(cafes) cafés més que la setmana passada")
            } else if cafes <= -2 {
                frases.append("☕️ \(-cafes) cafés menys que la setmana passada")
            }

            let molesties = actual.diesMolesties - anterior.diesMolesties
            if molesties < 0 {
                frases.append("🌿 \(dies(-molesties)) menys amb molèsties")
            } else if molesties > 0 {
                frases.append("🫶 \(dies(molesties)) més amb molèsties que la setmana passada")
            }
        }
        return frases
    }

    static func dies(_ n: Int) -> String { n == 1 ? "1 dia" : "\(n) dies" }

    // MARK: Notificació

    /// Pròxim diumenge a l'hora triada (sempre en el futur).
    static func dataNotificacio(ara: Date = Date(), hora: Hora) -> Date? {
        var c = DateComponents()
        c.weekday = 1   // diumenge (el calendari gregorià/ISO sempre compta 1 = diumenge)
        c.hour = hora.hora
        c.minute = hora.minut
        return Setmana.calendari.nextDate(after: ara, matching: c, matchingPolicy: .nextTime)
    }

    static func titolNotificacio(_ r: ResumSetmana) -> String {
        r.teDades ? "El resum de la teua setmana 📊" : "Ja tens el resum de la setmana 📊"
    }

    /// Com a màxim dues línies: la millor dada de la setmana i, si n'hi ha, les queixes amb humor.
    static func cosNotificacio(_ r: ResumSetmana) -> String {
        guard r.teDades else { return "Obri'l i mira com t'ha anat" }

        var linies: [String] = []
        if r.diesObjectiuAigua >= 5 {
            linies.append("💧 \(r.diesObjectiuAigua) dies amb l'objectiu d'aigua complit. Campiona!")
        } else if r.diesGimnas >= 3 {
            linies.append("🏋️‍♀️ \(dies(r.diesGimnas)) de gimnàs. Quina setmana!")
        } else if let millor = r.millorDiaAigua {
            linies.append("💧 El teu millor dia d'aigua: \(millor.nomDia) amb \(FormatAigua.text(millor.valor))")
        } else if r.diesGimnas > 0 {
            linies.append("🏋️‍♀️ \(dies(r.diesGimnas)) de gimnàs")
        } else {
            linies.append("📝 Has apuntat \(dies(r.diesApuntats)). Toca vore com ha anat")
        }

        if r.queixes == 1 {
            linies.append("😤 1 queixa sobre David. Ell diu que és poca.")
        } else if r.queixes > 1 {
            linies.append("😤 \(r.queixes) queixes sobre David. Ell diu que són poques.")
        }
        return linies.joined(separator: "\n")
    }

    // MARK: IA

    /// Resum AGREGAT (sense notes) per a què la IA comente la setmana.
    static func resumPerIA(_ r: ResumSetmana, comparativa: [String], escala: Int, objectiuMl: Int) -> String {
        var linies = ["Setmana del \(Setmana.titol(r.inici)). Escala del cansament: 0 (fresca) a \(escala). Objectiu d'aigua: \(objectiuMl) ml/dia."]
        for d in r.dies {
            var parts: [String] = []
            if d.aiguaMl > 0 { parts.append("aigua \(d.aiguaMl) ml") }
            if d.gimnas { parts.append("gimnàs") }
            if let c = d.cansament { parts.append("cansament \(c)") }
            if d.cafes > 0 { parts.append("\(d.cafes) cafés") }
            if (d.dolor ?? 0) > 0 { parts.append("molèsties") }
            if d.queixes > 0 { parts.append("\(d.queixes) queixes sobre David") }
            linies.append("- \(Analisi.nomsDiesLlargs[d.numero - 1]): " + (parts.isEmpty ? "res apuntat" : parts.joined(separator: ", ")))
        }
        linies.append("Dies amb l'objectiu d'aigua complit: \(r.diesObjectiuAigua) de 7. Dies de gimnàs: \(r.diesGimnas).")
        if !comparativa.isEmpty {
            linies.append("Comparat amb la setmana passada: " + comparativa.joined(separator: "; "))
        }
        return linies.joined(separator: "\n")
    }
}
