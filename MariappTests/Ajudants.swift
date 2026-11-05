import Foundation
@testable import Mariapp

/// Utilitats comunes dels tests.
enum Ajudants {
    /// Data local a migdia (així cap canvi d'hora ens canvia el dia).
    static func data(_ clau: String) -> Date {
        ClauDia.data(clau)!.addingTimeInterval(12 * 3600)
    }

    static func dia(_ id: String, aigua: Int = 0, cafes: Int = 0, queixes: Int = 0, gimnas: Bool = false, cansament: Int? = nil, dolor: Int? = nil) -> Dia {
        var d = Dia(id: id)
        d.aiguaMl = aigua
        d.cafes = cafes
        d.queixes = queixes
        d.gimnas = gimnas
        d.cansament = cansament
        d.dolor = dolor
        return d
    }

    static func plat(_ id: String, _ nom: String, _ etiquetes: [EtiquetaPlat] = [], favorit: Bool = false, ingredients: [Ingredient] = []) -> Plat {
        var p = Plat(nom: nom)
        p.id = id
        p.etiquetes = etiquetes
        p.favorit = favorit
        p.ingredients = ingredients
        p.creat = Date(timeIntervalSince1970: 1_800_000_000)
        return p
    }
}
