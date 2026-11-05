import Foundation
import Testing
@testable import Mariapp

struct CompteTests {
    private let ara = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func diesIHores() {
        let quan = ara.addingTimeInterval(3 * 86400 + 4 * 3600 + 120)
        #expect(Compte.text(fins: quan, ara: ara) == "en 3 dies, 4 hores")
    }

    @Test func singulars() {
        #expect(Compte.text(fins: ara.addingTimeInterval(86400 + 3600 + 60), ara: ara) == "en 1 dia, 1 hora")
    }

    @Test func horesIMinuts() {
        #expect(Compte.text(fins: ara.addingTimeInterval(5400), ara: ara) == "en 1 hora, 30 min")
    }

    @Test func minuts() {
        #expect(Compte.text(fins: ara.addingTimeInterval(600), ara: ara) == "en 10 min")
    }

    @Test func jaHaPassat() {
        #expect(Compte.text(fins: ara.addingTimeInterval(-5), ara: ara) == "ja ha passat")
    }

    @Test func vespradaAbansSonLes19DelDiaAnterior() throws {
        let cita = Ajudants.data("2026-11-10").addingTimeInterval(-2 * 3600) // 10:00
        let minuts = try #require(Compte.minutsVesprada(cita))
        let avis = cita.addingTimeInterval(TimeInterval(-minuts * 60))
        let c = Calendar.current.dateComponents([.day, .hour, .minute], from: avis)
        #expect(c.day == 9)
        #expect(c.hour == 19)
        #expect(c.minute == 0)
    }
}

struct CitesTests {
    private func cita(_ estat: EstatCita, dies: Double? = nil, recordatori: Double? = nil, ara: Date) -> Cita {
        var c = Cita(titol: "x")
        c.estat = estat
        c.data = dies.map { ara.addingTimeInterval($0 * 86400) }
        c.recordarDemanarEl = recordatori.map { ara.addingTimeInterval($0 * 86400) }
        return c
    }

    @Test func properaCitaIgnoraPassadesIFetes() {
        let ara = Date(timeIntervalSince1970: 1_800_000_000)
        let a = cita(.programada, dies: -2, ara: ara)
        let b = cita(.programada, dies: 5, ara: ara)
        let c = cita(.programada, dies: 2, ara: ara)
        let d = cita(.feta, dies: 1, ara: ara)
        #expect(ServeiCites.properaCita([a, b, c, d], ara: ara)?.id == c.id)
    }

    @Test func destacaNomesSiHiHaCitaALaSetmana() {
        let ara = Date(timeIntervalSince1970: 1_800_000_000)
        #expect(ServeiCites.citaProxima7Dies([cita(.programada, dies: 6, ara: ara)], ara: ara) != nil)
        #expect(ServeiCites.citaProxima7Dies([cita(.programada, dies: 9, ara: ara)], ara: ara) == nil)
    }

    @Test func recordatorisVencuts() {
        let ara = Date(timeIntervalSince1970: 1_800_000_000)
        let vencuda = cita(.perDemanar, recordatori: -1, ara: ara)
        let futura = cita(.perDemanar, recordatori: 1, ara: ara)
        let sense = cita(.perDemanar, ara: ara)
        #expect(ServeiCites.perDemanarVencudes([vencuda, futura, sense], ara: ara).map(\.id) == [vencuda.id])
    }
}

struct ServeiIATests {
    @Test func extreuBlocJSONDeTextAmbFrases() {
        let text = "Clar que sí! 😊\n```json\n[{\"nom\": \"Hummus\"}]\n```\nQue vos aprofite"
        #expect(ServeiIA.blocJSON(text) == "[{\"nom\": \"Hummus\"}]")
    }

    @Test func triaElPrimerBlocSiHiHaObjecte() {
        #expect(ServeiIA.blocJSON("res {\"a\": 1} fi") == "{\"a\": 1}")
        #expect(ServeiIA.blocJSON("sense json") == nil)
    }

    @Test func decodificaIdees() throws {
        let text = "Ací van: [{\"nom\":\"Crema de pastanaga\",\"emoji\":\"🥕\",\"etiquetes\":[\"lleuger\",\"sopar\",\"rara\"],\"thermomix\":true,\"ingredients\":[\"Pastanaga\"]}]"
        let idees = try #require(ServeiIA.decodifica(text, tipus: [IdeaPlat].self))
        #expect(idees.count == 1)
        let plat = idees[0].comPlat()
        #expect(plat.nom == "Crema de pastanaga")
        #expect(plat.etiquetes == [.lleuger, .sopar])
        #expect(plat.thermomix)
        #expect(plat.ingredients.map(\.nom) == ["Pastanaga"])
    }

    @Test func jsonInvalidDonaNil() {
        #expect(ServeiIA.decodifica("[1, 2", tipus: [IdeaPlat].self) == nil)
    }
}
