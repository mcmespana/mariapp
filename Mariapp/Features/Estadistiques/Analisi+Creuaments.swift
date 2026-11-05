import Foundation

// Creuaments de dades: l'aigua amb les molèsties, el gimnàs amb el cansament de l'endemà, els cafés amb les molèsties.
// Sempre amb frases prudents: són correlacions, mai diagnòstics.

/// Trams d'aigua en litres fixos (més fàcils d'entendre que un percentatge de l'objectiu).
enum TramAigua: Int, CaseIterable, Identifiable {
    case menysDe1L, de1a1_5, de1_5a2, mesDe2L

    var id: Int { rawValue }

    var nom: String {
        switch self {
        case .menysDe1L: "< 1 L"
        case .de1a1_5: "1–1,5 L"
        case .de1_5a2: "1,5–2 L"
        case .mesDe2L: "> 2 L"
        }
    }

    /// Per a les frases: "Els dies que **beus menys d'1 L** …".
    var fragment: String {
        switch self {
        case .menysDe1L: "beus menys d'1 L"
        case .de1a1_5: "beus entre 1 i 1,5 L"
        case .de1_5a2: "beus entre 1,5 i 2 L"
        case .mesDe2L: "passes de 2 L"
        }
    }

    /// Els límits són inclusius pel baix: 1000 ml ja és "1–1,5 L", 2000 ml ja és "> 2 L".
    static func per(ml: Int) -> TramAigua {
        switch ml {
        case ..<1000: .menysDe1L
        case 1000..<1500: .de1a1_5
        case 1500..<2000: .de1_5a2
        default: .mesDe2L
        }
    }
}

struct PuntAiguaMolesties: Identifiable, Equatable {
    let tram: TramAigua
    let dies: Int
    let diesAmbMolesties: Int
    /// Mitjana de la intensitat (1...3) dels dies que han tingut molèsties. nil si cap.
    let dolorMitja: Double?

    var id: Int { tram.rawValue }
    /// 0...100
    var percentatge: Double { dies > 0 ? Double(diesAmbMolesties) / Double(dies) * 100 : 0 }
}

/// Molèsties en un grup de dies (per als cafés).
struct GrupMolesties: Equatable {
    var dies = 0
    var diesAmbMolesties = 0
    var percentatge: Double { dies > 0 ? Double(diesAmbMolesties) / Double(dies) * 100 : 0 }
}

struct CafesMolesties: Equatable {
    var pocs = GrupMolesties()    // 0–1 cafés
    var molts = GrupMolesties()   // 3 o més
}

/// Cansament de l'endemà segons si el dia abans es va anar al gimnàs.
struct GimnasCansamentEndema: Equatable {
    var diesAmbGimnas = 0
    var cansamentAmbGimnas: Double?
    var diesSenseGimnas = 0
    var cansamentSenseGimnas: Double?

    var hiHaDades: Bool { diesAmbGimnas > 0 && diesSenseGimnas > 0 }
}

extension Analisi {
    /// Dies mínims en un tram perquè en parlem.
    static let minimDiesCreuament = 5

    // MARK: Aigua ↔ molèsties

    /// Un parell (aigua, dolor) per cada dia amb `dolor` apuntat i aigua > 0, amb l'aigua del MATEIX dia.
    static func aiguaVsMolesties(_ dies: [Dia]) -> [PuntAiguaMolesties] {
        agrupaAiguaMolesties(dies.compactMap { d -> (aiguaMl: Int, dolor: Int)? in
            guard let dolor = d.dolor, d.aiguaMl > 0 else { return nil }
            return (aiguaMl: d.aiguaMl, dolor: dolor)
        })
    }

    /// El mateix, però amb l'aigua del DIA ANTERIOR (les molèsties solen arribar després).
    static func aiguaAhirVsMolesties(_ dies: [Dia]) -> [PuntAiguaMolesties] {
        let perId = Dictionary(dies.map { ($0.id, $0) }, uniquingKeysWith: { primer, _ in primer })
        let cal = Calendar.current
        return agrupaAiguaMolesties(dies.compactMap { d -> (aiguaMl: Int, dolor: Int)? in
            guard let dolor = d.dolor,
                  let ahir = cal.date(byAdding: .day, value: -1, to: d.data),
                  let aigua = perId[ClauDia.de(ahir)]?.aiguaMl, aigua > 0 else { return nil }
            return (aiguaMl: aigua, dolor: dolor)
        })
    }

    static func agrupaAiguaMolesties(_ parelles: [(aiguaMl: Int, dolor: Int)]) -> [PuntAiguaMolesties] {
        var grups: [TramAigua: [Int]] = [:]
        for p in parelles { grups[TramAigua.per(ml: p.aiguaMl), default: []].append(p.dolor) }
        return TramAigua.allCases.compactMap { tram in
            guard let dolors = grups[tram], !dolors.isEmpty else { return nil }
            let amb = dolors.filter { $0 > 0 }
            return PuntAiguaMolesties(
                tram: tram,
                dies: dolors.count,
                diesAmbMolesties: amb.count,
                dolorMitja: amb.isEmpty ? nil : Double(amb.reduce(0, +)) / Double(amb.count)
            )
        }
    }

    /// Compara el tram més baix amb prou dies amb el més alt amb prou dies (han d'estar separats per un tram, almenys).
    static func fraseAiguaMolesties(_ punts: [PuntAiguaMolesties]) -> String? {
        let amb = punts.filter { $0.dies >= minimDiesCreuament }.sorted { $0.tram.rawValue < $1.tram.rawValue }
        guard let baix = amb.first, let alt = amb.last, alt.tram.rawValue - baix.tram.rawValue >= 2 else { return nil }

        let pb = Int(baix.percentatge.rounded())
        let pa = Int(alt.percentatge.rounded())
        let dades = "Els dies que \(baix.tram.fragment) tens molèsties el \(pb) % de les vegades; quan \(alt.tram.fragment), el \(pa) %."
        let diferencia = baix.percentatge - alt.percentatge
        if diferencia >= 15 {
            return "\(dades) 💧 Pareix que l'aigua t'ajuda."
        } else if diferencia <= -15 {
            return "\(dades) Curiós: potser beus més quan ja no et trobes bé 🤔"
        }
        return "No es veu cap relació clara (encara). \(dades)"
    }

    // MARK: Cafés ↔ molèsties

    static func cafesVsMolesties(_ dies: [Dia]) -> CafesMolesties {
        var r = CafesMolesties()
        for d in dies {
            guard let dolor = d.dolor else { continue }
            if d.cafes <= 1 {
                r.pocs.dies += 1
                if dolor > 0 { r.pocs.diesAmbMolesties += 1 }
            } else if d.cafes >= 3 {
                r.molts.dies += 1
                if dolor > 0 { r.molts.diesAmbMolesties += 1 }
            }
        }
        return r
    }

    static func fraseCafesMolesties(_ c: CafesMolesties) -> String? {
        guard c.pocs.dies >= minimDiesCreuament, c.molts.dies >= minimDiesCreuament else { return nil }
        let a = Int(c.pocs.percentatge.rounded())
        let b = Int(c.molts.percentatge.rounded())
        if c.molts.percentatge - c.pocs.percentatge >= 15 {
            return "Els dies de 3 o més cafés tens molèsties el \(b) % de les vegades, i els de 0–1, el \(a) %. ☕️"
        } else if c.pocs.percentatge - c.molts.percentatge >= 15 {
            return "Els dies de 0–1 cafés tens més molèsties (\(a) %) que els de 3 o més (\(b) %)."
        }
        return "El café no sembla canviar les molèsties (\(a) % vs \(b) %)."
    }

    // MARK: Gimnàs → cansament de l'endemà

    static func gimnasVsCansamentEndema(_ dies: [Dia]) -> GimnasCansamentEndema {
        let perId = Dictionary(dies.map { ($0.id, $0) }, uniquingKeysWith: { primer, _ in primer })
        let cal = Calendar.current
        var amb: [Int] = []
        var sense: [Int] = []
        for d in dies {
            guard let endema = cal.date(byAdding: .day, value: 1, to: d.data),
                  let cansament = perId[ClauDia.de(endema)]?.cansament else { continue }
            if d.gimnas { amb.append(cansament) } else { sense.append(cansament) }
        }
        func mitja(_ v: [Int]) -> Double? { v.isEmpty ? nil : Double(v.reduce(0, +)) / Double(v.count) }
        return GimnasCansamentEndema(
            diesAmbGimnas: amb.count, cansamentAmbGimnas: mitja(amb),
            diesSenseGimnas: sense.count, cansamentSenseGimnas: mitja(sense)
        )
    }

    static func fraseGimnasCansament(_ r: GimnasCansamentEndema, escala: Int) -> String? {
        guard r.diesAmbGimnas >= 3, r.diesSenseGimnas >= 3,
              let a = r.cansamentAmbGimnas, let b = r.cansamentSenseGimnas else { return nil }
        let llindar = Double(escala) * 0.05
        let f = { (x: Double) in escala > 10 ? "\(Int(x.rounded()))" : String(format: "%.1f", x).replacingOccurrences(of: ".", with: ",") }
        if a < b - llindar {
            return "L'endemà d'anar al gimnàs estàs menys cansada (\(f(a)) vs \(f(b))). El cos t'ho agraeix 💪"
        } else if a > b + llindar {
            return "L'endemà d'anar al gimnàs estàs una mica més cansada (\(f(a)) vs \(f(b))). Normal: el cos treballa 🫶"
        }
        return "El gimnàs no sembla canviar el cansament de l'endemà (\(f(a)) vs \(f(b)))."
    }

    // MARK: Per a la IA

    /// Línies agregades (sense notes) amb tots els creuaments, per a "✨ Analitza el meu mes".
    static func creuamentsPerIA(_ dies: [Dia], escala: Int) -> [String] {
        var linies: [String] = []
        func descriu(_ punts: [PuntAiguaMolesties]) -> String {
            punts.map { "\($0.tram.nom): \(Int($0.percentatge.rounded())) % de dies amb molèsties (\($0.dies) dies)" }.joined(separator: "; ")
        }
        let mateix = aiguaVsMolesties(dies)
        if !mateix.isEmpty { linies.append("Molèsties segons l'aigua del mateix dia: " + descriu(mateix)) }
        let ahir = aiguaAhirVsMolesties(dies)
        if !ahir.isEmpty { linies.append("Molèsties segons l'aigua del dia abans: " + descriu(ahir)) }

        let cafes = cafesVsMolesties(dies)
        if cafes.pocs.dies > 0 || cafes.molts.dies > 0 {
            linies.append("Molèsties segons els cafés: 0–1 cafés → \(Int(cafes.pocs.percentatge.rounded())) % (\(cafes.pocs.dies) dies); 3 o més → \(Int(cafes.molts.percentatge.rounded())) % (\(cafes.molts.dies) dies)")
        }
        let gimnas = gimnasVsCansamentEndema(dies)
        if gimnas.hiHaDades, let a = gimnas.cansamentAmbGimnas, let b = gimnas.cansamentSenseGimnas {
            linies.append("Cansament de l'endemà: després d'anar al gimnàs \(Int(a.rounded())) (\(gimnas.diesAmbGimnas) dies), sense gimnàs \(Int(b.rounded())) (\(gimnas.diesSenseGimnas) dies), sobre \(escala)")
        }
        // TODO(plan 14): afegir aquí `sonVsCansament` quan hi haja dades del son.
        return linies
    }
}
