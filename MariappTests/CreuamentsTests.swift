import Foundation
import Testing
@testable import Mariapp

struct CreuamentsTests {
    // MARK: Trams d'aigua

    @Test func tramsEnElsBorns() {
        #expect(TramAigua.per(ml: 0) == .menysDe1L)
        #expect(TramAigua.per(ml: 999) == .menysDe1L)
        #expect(TramAigua.per(ml: 1000) == .de1a1_5)
        #expect(TramAigua.per(ml: 1499) == .de1a1_5)
        #expect(TramAigua.per(ml: 1500) == .de1_5a2)
        #expect(TramAigua.per(ml: 1999) == .de1_5a2)
        #expect(TramAigua.per(ml: 2000) == .mesDe2L)
        #expect(TramAigua.per(ml: 5000) == .mesDe2L)
    }

    // MARK: Aigua ↔ molèsties

    @Test func ignoraDiesSenseDolorOSenseAigua() {
        let dies = [
            Ajudants.dia("2026-11-02", aigua: 500, dolor: 2),
            Ajudants.dia("2026-11-03", aigua: 500),               // sense dolor apuntat
            Ajudants.dia("2026-11-04", aigua: 0, dolor: 3),       // sense aigua
            Ajudants.dia("2026-11-05", aigua: 2500, dolor: 0),
        ]
        let punts = Analisi.aiguaVsMolesties(dies)
        #expect(punts.map(\.tram) == [.menysDe1L, .mesDe2L])
        #expect(punts[0].dies == 1)
        #expect(punts[0].diesAmbMolesties == 1)
        #expect(punts[0].percentatge == 100)
        #expect(punts[0].dolorMitja == 2)
        #expect(punts[1].diesAmbMolesties == 0)
        #expect(punts[1].dolorMitja == nil)
    }

    @Test func aiguaDeLAhirAmbCanviDeMes() {
        let dies = [
            Ajudants.dia("2026-10-31", aigua: 800),                 // → molèsties l'1 de novembre
            Ajudants.dia("2026-11-01", aigua: 2200, dolor: 1),
            Ajudants.dia("2026-11-02", aigua: 100, dolor: 0),       // ahir: 2200 → tram alt
            Ajudants.dia("2026-11-05", dolor: 2),                   // ahir sense document: ignorat
        ]
        let punts = Analisi.aiguaAhirVsMolesties(dies)
        let baix = punts.first { $0.tram == .menysDe1L }
        let alt = punts.first { $0.tram == .mesDe2L }
        #expect(baix?.dies == 1)
        #expect(baix?.diesAmbMolesties == 1)
        #expect(alt?.dies == 1)
        #expect(alt?.diesAmbMolesties == 0)
        #expect(punts.map(\.dies).reduce(0, +) == 2)
    }

    /// 6 dies amb poca aigua i molèsties en `moltesBaixes` d'ells; 6 dies amb molta aigua i molèsties en `moltesAltes`.
    private func dadesPerFrase(baixes: Int, altes: Int) -> [PuntAiguaMolesties] {
        let baix = (0..<6).map { Ajudants.dia(String(format: "2026-10-%02d", $0 + 1), aigua: 700, dolor: $0 < baixes ? 2 : 0) }
        let alt = (0..<6).map { Ajudants.dia(String(format: "2026-10-%02d", $0 + 11), aigua: 2400, dolor: $0 < altes ? 1 : 0) }
        return Analisi.aiguaVsMolesties(baix + alt)
    }

    @Test func fraseNecessitaCincDiesPerTram() {
        // Només 4 dies al tram baix.
        let dies = (0..<4).map { Ajudants.dia(String(format: "2026-10-%02d", $0 + 1), aigua: 700, dolor: 2) }
            + (0..<6).map { Ajudants.dia(String(format: "2026-10-%02d", $0 + 11), aigua: 2400, dolor: 0) }
        #expect(Analisi.fraseAiguaMolesties(Analisi.aiguaVsMolesties(dies)) == nil)
        #expect(Analisi.fraseAiguaMolesties([]) == nil)
    }

    @Test func fraseDiuQueLAiguaAjuda() throws {
        // 4 de 6 (67 %) amb poca aigua; 1 de 6 (17 %) amb molta.
        let frase = try #require(Analisi.fraseAiguaMolesties(dadesPerFrase(baixes: 4, altes: 1)))
        #expect(frase.contains("menys d'1 L"))
        #expect(frase.contains("67 %"))
        #expect(frase.contains("17 %"))
        #expect(frase.contains("t'ajuda"))
    }

    @Test func fraseSenseRelacioClara() throws {
        let frase = try #require(Analisi.fraseAiguaMolesties(dadesPerFrase(baixes: 2, altes: 2)))
        #expect(frase.hasPrefix("No es veu cap relació clara"))
    }

    @Test func fraseAlRevesEsPrudent() throws {
        let frase = try #require(Analisi.fraseAiguaMolesties(dadesPerFrase(baixes: 0, altes: 5)))
        #expect(frase.contains("Curiós"))
        #expect(!frase.contains("t'ajuda"))
    }

    @Test func fraseUsaElsTramsExtremsAmbDades() throws {
        // Sense dies < 1 L però amb "1–1,5 L" i "> 2 L".
        let mig = (0..<5).map { Ajudants.dia(String(format: "2026-10-%02d", $0 + 1), aigua: 1200, dolor: 2) }
        let alt = (0..<5).map { Ajudants.dia(String(format: "2026-10-%02d", $0 + 11), aigua: 2300, dolor: 0) }
        let frase = try #require(Analisi.fraseAiguaMolesties(Analisi.aiguaVsMolesties(mig + alt)))
        #expect(frase.contains("entre 1 i 1,5 L"))
        #expect(frase.contains("100 %"))
    }

    @Test func tramsContiguosNoFanFrase() {
        let a = (0..<5).map { Ajudants.dia(String(format: "2026-10-%02d", $0 + 1), aigua: 1200, dolor: 2) }
        let b = (0..<5).map { Ajudants.dia(String(format: "2026-10-%02d", $0 + 11), aigua: 1700, dolor: 0) }
        #expect(Analisi.fraseAiguaMolesties(Analisi.aiguaVsMolesties(a + b)) == nil)
    }

    // MARK: Gimnàs → cansament de l'endemà

    @Test func gimnasVsCansamentEndema() {
        let dies = [
            Ajudants.dia("2026-11-02", gimnas: true),
            Ajudants.dia("2026-11-03", cansament: 300),            // després de gimnàs
            Ajudants.dia("2026-11-04", gimnas: false),
            Ajudants.dia("2026-11-05", cansament: 700),            // després de no anar-hi
            Ajudants.dia("2026-11-06", gimnas: true),              // l'endemà no té cansament: ignorat
        ]
        let r = Analisi.gimnasVsCansamentEndema(dies)
        #expect(r.diesAmbGimnas == 1)
        #expect(r.cansamentAmbGimnas == 300)
        // 11-03 (sense gimnàs, endemà 11-04 sense cansament) no compta; 11-04 → 11-05 sí.
        #expect(r.diesSenseGimnas == 1)
        #expect(r.cansamentSenseGimnas == 700)
        #expect(r.hiHaDades)
        // Poques dades: cap frase.
        #expect(Analisi.fraseGimnasCansament(r, escala: 1000) == nil)
    }

    @Test func fraseGimnasAmbDadesSuficients() throws {
        var dies: [Dia] = []
        for i in 0..<3 {
            dies.append(Ajudants.dia(String(format: "2026-10-%02d", 2 * i + 1), gimnas: true))
            dies.append(Ajudants.dia(String(format: "2026-10-%02d", 2 * i + 2), cansament: 300))
            dies.append(Ajudants.dia(String(format: "2026-10-%02d", 2 * i + 11), gimnas: false))
            dies.append(Ajudants.dia(String(format: "2026-10-%02d", 2 * i + 12), cansament: 600))
        }
        let r = Analisi.gimnasVsCansamentEndema(dies)
        let frase = try #require(Analisi.fraseGimnasCansament(r, escala: 1000))
        #expect(frase.contains("menys cansada"))
    }

    // MARK: Cafés ↔ molèsties

    @Test func cafesVsMolesties() {
        var dies: [Dia] = []
        for i in 0..<5 { dies.append(Ajudants.dia(String(format: "2026-10-%02d", i + 1), cafes: 0, dolor: 0)) }
        for i in 0..<5 { dies.append(Ajudants.dia(String(format: "2026-10-%02d", i + 11), cafes: 4, dolor: i < 4 ? 1 : 0)) }
        dies.append(Ajudants.dia("2026-10-25", cafes: 2, dolor: 3)) // 2 cafés: ni uns ni altres
        let c = Analisi.cafesVsMolesties(dies)
        #expect(c.pocs.dies == 5)
        #expect(c.pocs.diesAmbMolesties == 0)
        #expect(c.molts.dies == 5)
        #expect(c.molts.percentatge == 80)
        let frase = Analisi.fraseCafesMolesties(c)
        #expect(frase?.contains("80 %") == true)
    }

    // MARK: IA

    @Test func creuamentsPerIAEsAgregatIBuitSenseDades() {
        #expect(Analisi.creuamentsPerIA([], escala: 1000).isEmpty)
        var d = Ajudants.dia("2026-11-02", aigua: 500, dolor: 1)
        d.nota = "SECRET personal"
        let text = Analisi.creuamentsPerIA([d], escala: 1000).joined(separator: "\n")
        #expect(text.contains("< 1 L"))
        #expect(!text.contains("SECRET"))
    }
}
