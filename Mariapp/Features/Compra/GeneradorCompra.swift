import Foundation

/// Lògica de la llista de la compra (pura, fàcil de provar).
enum GeneradorCompra {
    static func clau(_ nom: String) -> String { Plat.normalitza(nom) }

    /// Elements nous per a tots els plats d'un menú: els ingredients que NO tenim,
    /// sense repetir el que ja és pendent a la llista ni entre plats (per nom normalitzat).
    static func nous(menu: MenuSetmana, plats: [String: Plat], existents: [ElementCompra]) -> [ElementCompra] {
        var vists = Set(existents.filter { !$0.comprat }.map { clau($0.nom) })
        var resultat: [ElementCompra] = []
        for platId in menu.platIds.sorted() {
            guard let plat = plats[platId] else { continue }
            for ing in plat.ingredients where !ing.tenim {
                let k = clau(ing.nom)
                guard !k.isEmpty, !vists.contains(k) else { continue }
                vists.insert(k)
                var e = ElementCompra(nom: ing.nom.trimmingCharacters(in: .whitespaces))
                e.platId = plat.id
                e.platNom = plat.nom
                e.ingredientId = ing.id
                resultat.append(e)
            }
        }
        return resultat
    }

    /// Afig un element a mà si no n'hi ha ja un de pendent amb el mateix nom.
    static func podeuAfegir(_ nom: String, a existents: [ElementCompra]) -> Bool {
        let k = clau(nom)
        guard !k.isEmpty else { return false }
        return !existents.contains { !$0.comprat && clau($0.nom) == k }
    }

    /// Plat actualitzat quan es marca (o desmarca) com a comprat un ingredient que venia d'ell.
    static func platActualitzat(_ plat: Plat, element: ElementCompra, tenim: Bool) -> Plat? {
        var p = plat
        let k = clau(element.nom)
        guard let i = p.ingredients.firstIndex(where: { $0.id == element.ingredientId || clau($0.nom) == k }) else { return nil }
        guard p.ingredients[i].tenim != tenim else { return nil }
        p.ingredients[i].tenim = tenim
        return p
    }
}
