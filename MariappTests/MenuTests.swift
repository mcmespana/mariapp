import Foundation
import Testing
@testable import Mariapp

struct SuggeridorMenuTests {
    private let sense: () -> Double = { 0 }

    @Test func puntuacioSegonsEtiquetes() {
        let sopar = Ajudants.plat("a", "Crema", [.sopar, .lleuger], favorit: true)
        let dinar = Ajudants.plat("b", "Arròs", [.dinar])

        // sopar + lleuger + favorit = 3 + 2 + 2
        #expect(SuggeridorMenu.punts(sopar, apat: .sopar, aquestaSetmana: [], anterior: []) == 7)
        // per a dinar el lleuger no compta
        #expect(SuggeridorMenu.punts(sopar, apat: .dinar, aquestaSetmana: [], anterior: []) == 2)
        #expect(SuggeridorMenu.punts(dinar, apat: .dinar, aquestaSetmana: [], anterior: []) == 3)
    }

    @Test func penalitzaRepetits() {
        let p = Ajudants.plat("a", "Crema", [.sopar])
        #expect(SuggeridorMenu.punts(p, apat: .sopar, aquestaSetmana: ["a"], anterior: []) == -2)
        #expect(SuggeridorMenu.punts(p, apat: .sopar, aquestaSetmana: [], anterior: ["a"]) == 1)
    }

    @Test func suggerimentsOrdenatsILimitats() {
        let plats = (1...8).map { Ajudants.plat("p\($0)", "Plat \($0)", $0 == 3 ? [.sopar, .lleuger] : []) }
        let top = SuggeridorMenu.suggeriments(plats: plats, apat: .sopar, setmana: nil, anterior: nil, atzar: sense)
        #expect(top.count == 5)
        #expect(top.first?.id == "p3")
    }

    @Test func suggerimentsEviteLoDeEstaSetmana() {
        let a = Ajudants.plat("a", "A", [.dinar])
        let b = Ajudants.plat("b", "B", [.dinar])
        var setmana = MenuSetmana(id: "2026-W45")
        setmana.posa(EntradaMenu(platId: "a"), dia: 1, apat: .dinar)
        let top = SuggeridorMenu.suggeriments(plats: [a, b], apat: .dinar, setmana: setmana, anterior: nil, limit: 1, atzar: sense)
        #expect(top.first?.id == "b")
    }

    @Test func ompleNomesElsForatsBuits() {
        let plats = [Ajudants.plat("a", "A", [.dinar]), Ajudants.plat("b", "B", [.sopar])]
        var inicial = MenuSetmana(id: "2026-W45")
        inicial.posa(EntradaMenu(text: "Sopar fora 🎉"), dia: 2, apat: .sopar)

        let omplit = SuggeridorMenu.omple(setmana: inicial, plats: plats, anterior: nil, atzar: sense)

        for dia in 1...7 {
            for apat in Apat.allCases {
                #expect(omplit.entrada(dia: dia, apat: apat) != nil)
            }
        }
        #expect(omplit.entrada(dia: 2, apat: .sopar)?.text == "Sopar fora 🎉")
    }

    @Test func ompleSensePlatsNoFaRes() {
        let m = MenuSetmana(id: "2026-W45")
        #expect(SuggeridorMenu.omple(setmana: m, plats: [], anterior: nil).apats.isEmpty)
    }

    @Test func copiaNomesAlsBuits() {
        var anterior = MenuSetmana(id: "2026-W44")
        anterior.posa(EntradaMenu(platId: "a"), dia: 1, apat: .dinar)
        anterior.posa(EntradaMenu(platId: "b"), dia: 1, apat: .sopar)
        var actual = MenuSetmana(id: "2026-W45")
        actual.posa(EntradaMenu(platId: "z"), dia: 1, apat: .sopar)

        let copiat = SuggeridorMenu.copia(de: anterior, a: actual)
        #expect(copiat.entrada(dia: 1, apat: .dinar)?.platId == "a")
        #expect(copiat.entrada(dia: 1, apat: .sopar)?.platId == "z")
    }
}

struct SetmanaTests {
    // 2026-11-05 és dijous.
    private let dijous = Ajudants.data("2026-11-05")

    @Test func iniciDeSetmanaEsDilluns() {
        #expect(ClauDia.de(Setmana.inici(de: dijous)) == "2026-11-02")
        #expect(Setmana.numeroDia(dijous) == 4)
        #expect(Setmana.numeroDia(Ajudants.data("2026-11-08")) == 7)
        #expect(Setmana.numeroDia(Ajudants.data("2026-11-02")) == 1)
    }

    @Test func idISOdeLaSetmana() {
        #expect(MenuSetmana.id(per: dijous) == "2026-W45")
    }

    @Test func titolDeSetmanaDinsDelMateixMes() {
        #expect(Setmana.titol(Setmana.inici(de: dijous)) == "2 – 8 de novembre")
    }

    @Test func navegarSetmanes() {
        let inici = Setmana.inici(de: dijous)
        #expect(ClauDia.de(Setmana.mou(inici, setmanes: 1)) == "2026-11-09")
        #expect(ClauDia.de(Setmana.mou(inici, setmanes: -1)) == "2026-10-26")
        #expect(ClauDia.de(Setmana.dia(inici, 7)) == "2026-11-08")
    }
}

struct PlatTests {
    @Test func cercaSenseAccentsNiMajuscules() {
        let p = Ajudants.plat("a", "Salmó al forn", [.dinar])
        #expect(p.passa(cerca: "SALMO"))
        #expect(p.passa(cerca: "  forn "))
        #expect(!p.passa(cerca: "lasanya"))
    }

    @Test func cercaTambeEnIngredients() {
        let p = Ajudants.plat("a", "Amanida", ingredients: [Ingredient(nom: "Cigrons")])
        #expect(p.passa(cerca: "cigrons"))
    }

    @Test func filtreDEtiquetesRequereixTotes() {
        let p = Ajudants.plat("a", "Crema", [.lleuger, .sopar])
        #expect(p.passa(cerca: "", etiquetes: [.lleuger]))
        #expect(p.passa(cerca: "", etiquetes: [.lleuger, .sopar]))
        #expect(!p.passa(cerca: "", etiquetes: [.lleuger, .tupper]))
    }

    @Test func filtresThermomixIPreferits() {
        var p = Ajudants.plat("a", "Hummus")
        #expect(!p.passa(cerca: "", nomesThermomix: true))
        #expect(!p.passa(cerca: "", nomesPreferits: true))
        p.thermomix = true
        p.favorit = true
        #expect(p.passa(cerca: "", nomesThermomix: true, nomesPreferits: true))
    }

    @Test func platsDExempleTenenIdsUnics() {
        let ids = Plat.exemples.map(\.id)
        #expect(Set(ids).count == ids.count)
        #expect(Plat.exemples.count >= 8)
    }
}
