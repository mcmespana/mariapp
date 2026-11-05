import Foundation
import Testing
@testable import Mariapp

struct RellotgeTests {
    private func estat(aigua: Int = 0, cansament: Int? = nil) -> EstatRellotge {
        EstatRellotge(
            hui: HuiSnapshot(dia: "2026-11-05", aiguaMl: aigua, objectiuMl: 2250, ampollaMl: 750, cansament: cansament, escalaCansament: 1000),
            cita: CitaSnapshot(titol: "Revisió", emoji: "🩺", data: Date(timeIntervalSince1970: 1_800_100_000), lloc: "CAP"),
            menuAvui: ParellaMenu(dinar: "🥗 Amanida", sopar: nil),
            escalaCansament: 1000,
            actualitzat: Date(timeIntervalSince1970: 1_800_000_000)
        )
    }

    @Test func codificaIDescodifica() throws {
        let original = estat(aigua: 1500, cansament: 400)
        let dades = try JSONEncoder().encode(original)
        let torna = try JSONDecoder().decode(EstatRellotge.self, from: dades)
        #expect(torna == original)
        #expect(torna.cita?.titol == "Revisió")
        #expect(torna.menuAvui?.dinar == "🥗 Amanida")
    }

    @Test func aplicaAccionsDeFormaOptimista() {
        var e = estat(aigua: 500)
        e.aplica(.aigua(ml: 375))
        e.aplica(.cafe(quantitat: 2))
        e.aplica(.queixa)
        e.aplica(.queixa)
        #expect(e.hui.aiguaMl == 875)
        #expect(e.hui.cafes == 2)
        #expect(e.hui.queixes == 2)
        // Desfer no baixa de zero.
        e.aplica(.aigua(ml: -5000))
        #expect(e.hui.aiguaMl == 0)
        e.aplica(.cafe(quantitat: -9))
        #expect(e.hui.cafes == 0)
    }

    @Test func elCansamentDelRellotgeQuedaDinsDeLEscala() {
        var e = estat()
        e.aplica(.cansament(valor: 730))
        #expect(e.hui.cansament == 730)
        e.aplica(.cansament(valor: 5000))
        #expect(e.hui.cansament == 1000)
        e.aplica(.cansament(valor: -3))
        #expect(e.hui.cansament == 0)
    }

    @Test func comprarNoTocaElRellotge() {
        var e = estat(aigua: 100)
        let abans = e.hui
        e.aplica(.comprat(id: "x"))
        #expect(e.hui == abans)
    }

    @Test func canviDeDiaPosaElsComptadorsAZero() {
        var e = estat(aigua: 1800, cansament: 600)
        e.hui.cafes = 3
        let nou = e.normalitzat(avui: "2026-11-06")
        #expect(nou.hui.dia == "2026-11-06")
        #expect(nou.hui.aiguaMl == 0)
        #expect(nou.hui.cafes == 0)
        #expect(nou.hui.cansament == nil)
        // Es conserven l'objectiu i la botella.
        #expect(nou.hui.objectiuMl == 2250)
        #expect(nou.hui.ampollaMl == 750)
        // El mateix dia no canvia res.
        #expect(e.normalitzat(avui: "2026-11-05") == e)
    }

    @Test func accioPendentDelRellotgeFaViatgeIPortaElCansament() throws {
        let pendent = AccioPendent(dia: "2026-11-05", accio: .cansament(valor: 420), data: Date(timeIntervalSince1970: 1_800_000_000))
        let dades = try JSONEncoder().encode(pendent)
        let torna = try JSONDecoder().decode(AccioPendent.self, from: dades)
        #expect(torna.id == pendent.id)
        #expect(torna.accio == .cansament(valor: 420))
    }

    @Test func elsCansamentsAntiguesNoEsTrenquen() throws {
        let json = #"{"cansament":{"valor":250}}"#
        #expect(try JSONDecoder().decode(AccioRapida.self, from: Data(json.utf8)) == .cansament(valor: 250))
    }
}
