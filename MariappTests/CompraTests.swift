import Foundation
import Testing
@testable import Mariapp

struct GeneradorCompraTests {
    private func plats() -> [String: Plat] {
        let lasanya = Ajudants.plat("l", "Lasanya", ingredients: [
            Ingredient(id: "l1", nom: "Pasta", tenim: true),
            Ingredient(id: "l2", nom: "Beixamel", tenim: false),
            Ingredient(id: "l3", nom: "Formatge", tenim: false),
        ])
        let pizza = Ajudants.plat("p", "Pizza", ingredients: [
            Ingredient(id: "p1", nom: "FORMATGE", tenim: false),
            Ingredient(id: "p2", nom: "Tomaca", tenim: false),
        ])
        return ["l": lasanya, "p": pizza]
    }

    @Test func nomesElQueNoTenim() {
        var menu = MenuSetmana(id: "2026-W45")
        menu.posa(EntradaMenu(platId: "l"), dia: 1, apat: .dinar)
        let nous = GeneradorCompra.nous(menu: menu, plats: plats(), existents: [])
        #expect(nous.map(\.nom) == ["Beixamel", "Formatge"])
        #expect(nous.allSatisfy { $0.platId == "l" })
    }

    @Test func noDuplicaPerNomNormalitzat() {
        var menu = MenuSetmana(id: "2026-W45")
        menu.posa(EntradaMenu(platId: "l"), dia: 1, apat: .dinar)
        menu.posa(EntradaMenu(platId: "p"), dia: 2, apat: .sopar)
        let nous = GeneradorCompra.nous(menu: menu, plats: plats(), existents: [])
        // Formatge apareix en tots dos plats (un en majúscules): només una vegada.
        #expect(nous.filter { Plat.normalitza($0.nom) == "formatge" }.count == 1)
        #expect(nous.count == 3)
    }

    @Test func noRepeteixElQueJaEstaPendent() {
        var menu = MenuSetmana(id: "2026-W45")
        menu.posa(EntradaMenu(platId: "l"), dia: 1, apat: .dinar)
        let pendent = ElementCompra(nom: "beixamel")
        var comprat = ElementCompra(nom: "Formatge")
        comprat.comprat = true
        let nous = GeneradorCompra.nous(menu: menu, plats: plats(), existents: [pendent, comprat])
        // Beixamel ja és pendent; Formatge estava comprat, així que torna a faltar.
        #expect(nous.map(\.nom) == ["Formatge"])
    }

    @Test func afegirAMaNoDuplicaPendents() {
        let existents = [ElementCompra(nom: "Llet")]
        #expect(!GeneradorCompra.podeuAfegir("  LLET ", a: existents))
        #expect(!GeneradorCompra.podeuAfegir("   ", a: existents))
        #expect(GeneradorCompra.podeuAfegir("Pa", a: existents))
    }

    @Test func comprarMarcaElTenimAlPlat() throws {
        let plat = try #require(plats()["l"])
        var element = ElementCompra(nom: "Beixamel")
        element.ingredientId = "l2"

        let actualitzat = try #require(GeneradorCompra.platActualitzat(plat, element: element, tenim: true))
        #expect(actualitzat.ingredients.first { $0.id == "l2" }?.tenim == true)
        // Ja estava així: no cal desar res.
        #expect(GeneradorCompra.platActualitzat(actualitzat, element: element, tenim: true) == nil)
    }
}
