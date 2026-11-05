import Foundation
import Testing
@testable import Mariapp

struct CodificadorTests {
    private func anada<T: Registre>(_ valor: T) -> T? {
        Codificador.registre(T.self, id: valor.id, dades: Codificador.diccionari(valor))
    }

    @Test func diaIdaIVolta() {
        let d = Ajudants.dia("2026-11-04", aigua: 750, cafes: 2, queixes: 1, gimnas: true, cansament: 640, dolor: 1)
        #expect(anada(d) == d)
    }

    @Test func platIdaIVolta() {
        var p = Ajudants.plat("p1", "Hummus", [.lleuger, .sopar], favorit: true, ingredients: [Ingredient(id: "i1", nom: "Cigrons", tenim: false)])
        p.thermomix = true
        p.enllac = "https://exemple.cat"
        #expect(anada(p) == p)
    }

    @Test func citaIdaIVoltaAmbAlarma() {
        var c = Cita(titol: "Revisió")
        c.id = "c1"
        c.estat = .programada
        c.data = Date(timeIntervalSince1970: 1_800_000_000)
        c.avisos = [10080, 1440]
        c.alarmaMinuts = 120
        c.alarmaId = "ABC"
        c.creat = Date(timeIntervalSince1970: 1_700_000_000)
        #expect(anada(c) == c)
    }

    @Test func menuISetmanaIdaIVolta() {
        var m = MenuSetmana(id: "2026-W45")
        m.posa(EntradaMenu(platId: "p1"), dia: 1, apat: .dinar)
        m.posa(EntradaMenu(text: "Sopar fora 🎉"), dia: 5, apat: .sopar)
        #expect(anada(m) == m)
    }

    @Test func altresRegistresIdaIVolta() {
        var e = ElementCompra(nom: "Llet")
        e.id = "e1"
        e.creat = Date(timeIntervalSince1970: 1_800_000_000)
        e.quantitat = "2"
        #expect(anada(e) == e)

        var a = AnotacioEsdeveniment(id: "a1")
        a.emoji = "🎂"
        a.color = .groc
        a.avisos = [30, 1440]
        #expect(anada(a) == a)

        let cat = CategoriaMetge(id: "x", nom: "Fisio", emoji: "💪", ordre: 3)
        #expect(anada(cat) == cat)

        var pens = Pensament(tipus: .agraiment, text: "Gràcies")
        pens.id = "pe1"
        pens.data = Date(timeIntervalSince1970: 1_800_000_000)
        #expect(anada(pens) == pens)

        #expect(anada(Configuracio()) == Configuracio())
    }

    // MARK: Documents antics (sense els camps nous)

    @Test func citaAntigaSenseCampsNous() throws {
        let c = try #require(Codificador.registre(Cita.self, id: "vella", dades: ["titol": "Dentista", "estat": "programada"]))
        #expect(c.titol == "Dentista")
        #expect(c.estat == .programada)
        #expect(c.alarmaMinuts == nil)
        #expect(c.alarmaId == nil)
        #expect(c.avisos == [1440, 120])
    }

    @Test func platAntic() throws {
        let p = try #require(Codificador.registre(Plat.self, id: "p", dades: ["nom": "Truita", "etiquetes": ["lleuger", "inventada"]]))
        #expect(p.etiquetes == [.lleuger])
        #expect(p.ingredients.isEmpty)
        #expect(p.thermomix == false)
    }

    @Test func documentsBuitsNoFallen() {
        #expect(Codificador.registre(Dia.self, id: "2026-01-01", dades: [:]) != nil)
        #expect(Codificador.registre(MenuSetmana.self, id: "2026-W01", dades: [:]) != nil)
        #expect(Codificador.registre(ElementCompra.self, id: "e", dades: [:]) != nil)
        #expect(Codificador.registre(AnotacioEsdeveniment.self, id: "a", dades: [:]) != nil)
    }

    @Test func configuracioPerDefecte() throws {
        let c = try #require(Codificador.registre(Configuracio.self, id: "general", dades: [:]))
        #expect(c.ampollaMl == 750)
        #expect(c.objectiuMl == 2250)
        #expect(c.escalaCansament == 1000)
    }
}
